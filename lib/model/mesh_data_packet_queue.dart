import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:meshtastic_flutter/mesh_utilities.dart' as Utils;
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pbserver.dart';
import 'package:meshtastic_flutter/proto-autogen/portnums.pb.dart';
import 'package:protobuf/protobuf.dart';
import 'package:sqflite/sqflite.dart';

import 'mesh_database.dart';

/*
There needs to be:
1. A ToRadio command queue. Any actions get added to this queue. It's sent whenever the phone connects.
2. A FromRadio queue. This is the history of all that happened with a particular device.
- Both of these need an SQLite DB, with NodeId as key. On connecting to a certain node, use that as key for the tables, and load.
- When no node is connected, assume the previous nodeId.
- On changing node, load the items from that node.
- Once done with the queue, disconnect BT
 */

///
///
///
enum MeshDataPacketDirection { toRadio, fromRadio }
extension RadioCommandDirectionInteger on MeshDataPacketDirection {
  String get name => describeEnum(this);

  static MeshDataPacketDirection fromInt(int v) {
    if (v == 0)
      return MeshDataPacketDirection.toRadio;
    else
      return MeshDataPacketDirection.fromRadio;
  }

  int toInt() {
    if (this.index == 0)
      return 0;
    else
      return 1;
  }
}

///
///
class MeshDataPacket {
  // meta-info about the package
  MeshDataPacketDirection direction = MeshDataPacketDirection.toRadio;
  int bluetoothId = 0;
  bool acknowledged = false; // marks whether an outgoing package has been acknowledged
  GeneratedMessage payload; // Both ToRadio and FromRadio inherit from GeneratedMessage
  int checksum = 0; // checksum on the 'payload' field

  // not stored in DB. Used to keep track of when to save.
  bool stored = false; // has object been stored in the database before?
  bool dirty = false; // has object changed since it was stored?

  // lifted "up" from the payload (MeshPacket)
  int payloadVariant = FromRadio_PayloadVariant.notSet.index; // TODO: dangerous if protobuf definition changes? Add own function to return int based on type?
  int packetId = 0;
  int fromNodeNum = 0;
  int toNodeNum = 0;
  int channel = 0;
  int rxTimeEpochSec = 0;
  double rxSnr = 0;
  int hopLimit = 0;
  bool wantAck = false;
  int priority = 0;
  int rxRssi = 0;

  MeshDataPacket(this.bluetoothId, this.payload, this.acknowledged, this.stored, this.dirty) {
    dynamic radioPacket;

    if (payload is FromRadio) {
      direction = MeshDataPacketDirection.fromRadio;
      payloadVariant = Utils.fromRadioPayloadVariantToInteger(payload as FromRadio);
      radioPacket = getPayloadAsFromRadio();
    } else if (payload is ToRadio) {
      direction = MeshDataPacketDirection.toRadio;
      payloadVariant = Utils.toRadioPayloadVariantToInteger(payload as ToRadio);
      radioPacket = getPayloadAsToRadio();
    }

    packetId = radioPacket?.packet?.id ?? 0;
    fromNodeNum = radioPacket?.packet?.from ?? 0;
    toNodeNum = radioPacket?.packet?.to ?? 0;
    rxTimeEpochSec = radioPacket?.packet?.rxTime ?? 0;
    rxSnr = radioPacket?.packet?.rxSnr ?? 0.0;
    hopLimit = radioPacket?.packet?.hopLimit ?? 0;
    wantAck = radioPacket?.packet?.wantAck ?? false;
    priority = radioPacket?.packet?.priority?.value ?? MeshPacket_Priority.DEFAULT.value;
    rxRssi = radioPacket?.packet?.rxRssi ?? 0;

    checksum = Utils.makePackageChecksum(radioPacket);
  }

  Map<String, dynamic> toMap() {
    return {
      'bluetooth_id': bluetoothId,
      'direction': direction.toInt(),
      'payload_variant': payloadVariant,
      'checksum': checksum,
      'packet_id': packetId,
      'from_node_num': fromNodeNum,
      'to_node_num': toNodeNum,
      'channel': channel,
      'rx_time_epoch_sec': rxTimeEpochSec,
      'rx_snr': rxSnr,
      'hop_limit': hopLimit,
      'want_ack': (wantAck ? 1 : 0),
      'priority': priority,
      'rx_rssi': rxRssi,
      'acknowledged': (acknowledged ? 1 : 0),
      'payload': payload.writeToBuffer(),
      //'stored': (stored ? 1 : 0),
      //'dirty': (dirty ? 1 : 0),
    };
  }

  static MeshDataPacket fromMap(Map<String, dynamic> m) {
    GeneratedMessage pl;
    MeshDataPacketDirection rd = RadioCommandDirectionInteger.fromInt(m['direction']);

    if (rd == MeshDataPacketDirection.toRadio) {
      pl = ToRadio.fromBuffer(m['payload']);
    } else if (rd == MeshDataPacketDirection.fromRadio) {
      pl = FromRadio.fromBuffer(m['payload']);
    } else {
      throw new ErrorDescription("payload from DB is neither ToRadio or FromRadio");
    }
    return MeshDataPacket(m['bluetooth_id'], pl, (m['acknowledged'] == 0 ? false : true), (m['stored'] == 0 ? false : true), (m['dirty'] == 0 ? false : true));
  }

  DateTime getDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(this.rxTimeEpochSec * 1000);
  }

  String getBluetoothIdAsString() {
    String id = Utils.convertBluetoothAddressToString(this.bluetoothId);
    return id;
  }

  FromRadio? getPayloadAsFromRadio() {
    if (direction == MeshDataPacketDirection.fromRadio)
      return payload as FromRadio;
    else
      return null;
  }

  ToRadio? getPayloadAsToRadio() {
    if (direction == MeshDataPacketDirection.toRadio)
      return payload as ToRadio;
    else
      return null;
  }
}

///
///
///
class MeshDataPacketQueue extends ChangeNotifier {
  int _bluetoothId = 0;
  /// back of the queue are the most recent packets.
  DoubleLinkedQueue<MeshDataPacket> _cmdQueue = new DoubleLinkedQueue<MeshDataPacket>();

  MeshDataPacketQueue();

  /// set new BT ID, load all Radio packets for this device, return 'true' if ID actually changed
  Future<bool> setBluetoothIdFromString(String hexId) async {
    return await setBluetoothId(Utils.convertBluetoothAddressToInt(hexId));
  }

  /// set new BT ID, load all Radio packets for this device, return 'true' if ID actually changed
  Future<bool> setBluetoothId(int id) async {
    if (id == _bluetoothId) return false; // do nothing - it's the same ID

    await save();
    _cmdQueue.clear();
    _bluetoothId = id;
    List<MeshDataPacket> pLst = await _load();
    _cmdQueue.addAll(pLst);
    notifyListeners();
    return true;
  }

  ///
  bool addToRadioBack(ToRadio pkt) {
    if (pkt.whichPayloadVariant() != ToRadio_PayloadVariant.packet) return false; // only add data packets
    MeshDataPacket rc = MeshDataPacket(_bluetoothId, pkt, false, false, true);
    return _addRadioCommandBack(rc);
  }

  ///
  bool addFromRadioBack(FromRadio pkt) {
    if (pkt.whichPayloadVariant() != FromRadio_PayloadVariant.packet) return false; // only add data packets
    MeshDataPacket rc = MeshDataPacket(_bluetoothId, pkt, false, false, true);
    return _addRadioCommandBack(rc);
  }

  ///
  bool _addRadioCommandBack(MeshDataPacket rc) {
    if (hasChecksum(rc.checksum)) {
      print("_addRadioCommandBack - has this package already. Discarding duplicate ${rc.toMap()}");
      return false;
    }
    _cmdQueue.addLast(rc);
    notifyListeners();
    return true;
  }

  ///
  Queue<MeshDataPacket> getFromRadioQueue() {
    return Queue.from(_cmdQueue.where((r) => r.direction == MeshDataPacketDirection.fromRadio));
  }

  ///
  Queue<MeshDataPacket> getToRadioQueue({bool acknowledged = false}) {
    return Queue.from(_cmdQueue.where((r) => r.direction == MeshDataPacketDirection.toRadio && r.acknowledged == acknowledged));
  }

  /// return true if checksum in argument already exists in the command queue (we have this package already - it's a duplicate)
  bool hasChecksum(int checksum) {
    return _cmdQueue.where((r) => r.checksum == checksum).isNotEmpty;
  }

  /// get all the text messages in the message queue. Silly filtering to get there.
  Queue<MeshDataPacket> getTextMessageQueue() {
    var isTextMessage = (MeshDataPacket r) {
      if (r.direction == MeshDataPacketDirection.toRadio) {
        ToRadio? tr = r.getPayloadAsToRadio();
        if (tr == null) return false;
        if (tr.whichPayloadVariant() == ToRadio_PayloadVariant.packet &&
            tr.packet.whichPayloadVariant() == MeshPacket_PayloadVariant.decoded &&
            tr.packet.decoded.portnum == PortNum.TEXT_MESSAGE_APP) {
          return true;
        }
      } else if (r.direction == MeshDataPacketDirection.fromRadio) {
        FromRadio? fr = r.getPayloadAsFromRadio();
        if (fr == null) return false;
        if (fr.whichPayloadVariant() == FromRadio_PayloadVariant.packet &&
            fr.packet.whichPayloadVariant() == MeshPacket_PayloadVariant.decoded &&
            fr.packet.decoded.portnum == PortNum.TEXT_MESSAGE_APP) {
          return true;
        }
      }
      return false;
    };
    return Queue.from(_cmdQueue.where((r) => isTextMessage(r)));
  }

  /// With great power comes great responsibility...
  Queue<MeshDataPacket> getRadioQueue() {
    return _cmdQueue;
  }

  /// clear contents of the queue
  void clearRadioQueue() {
    _cmdQueue.clear();
    notifyListeners();
  }

  /// Has un-acknowledged (unsent) packets
  bool hasUnAcknowledgedToRadioPackets() {
    return _cmdQueue.any((MeshDataPacket e) => e.direction == MeshDataPacketDirection.toRadio && e.acknowledged == false);
  }

  /// mark all packets in the queue as Clean and *not* Dirty
  void markAllStoredAndClean() {
    _cmdQueue.forEach((MeshDataPacket e) {
      e.dirty = false;
      e.stored = true;
    });
  }

  ///
  save() async {
    int countInsert = 0;
    int countUpdate = 0;
    print("MeshDataPacketQueue::save");
    if (_cmdQueue.isEmpty) return;

    return MeshDatabase.database.then((db) {
      return db.transaction((txn) async {
        var batch = txn.batch();
        for (var i in _cmdQueue) {
          if (i.stored == true && i.dirty == false) continue;

          if (i.stored == true && i.dirty == true) {
            i.stored = true;
            i.dirty = false;
            var m = i.toMap();
            batch.update('mesh_data_packet', m,
                where: 'bluetooth_id=? AND rx_time_epoch_sec=? AND packet_id=? AND from_node_num=? AND to_node_num=? AND channel=? AND checksum=?',
                whereArgs: [m['bluetooth_id'], m['rx_time_epoch_sec'], m['packet_id'], m['from_node_num'], m['to_node_num'], m['channel'], m['checksum']]);
            ++countUpdate;
          } else if (i.stored == false) {
            i.stored = true;
            i.dirty = false;
            var m = i.toMap();
            batch.insert('mesh_data_packet', m);
            ++countInsert;
          }
        }
        print("MeshDataPacketQueue::save - insert=$countInsert update=$countUpdate");
        return batch.commit(noResult: true);
      });
    }).catchError((e, s) {
      print('MeshDataPacketQueue::save - exception $e $s');
    });
  }

  ///
  Future<List<MeshDataPacket>> _load() async {
    var timeAgo = DateTime.now().subtract(Duration(days: 2));
    List<MeshDataPacket> cmdLst = <MeshDataPacket>[];

    Database db = await MeshDatabase.database;
    // Load from DB. Oldest first (Ascending order of epoch_ms)
    List<Map<String, Object?>> rLst = await db.rawQuery(
        'SELECT * FROM mesh_data_packet WHERE bluetooth_id=? AND rx_time_epoch_sec > ? ORDER BY rx_time_epoch_sec ASC;', [_bluetoothId, timeAgo.second]);

    print("MeshDataPacketQueue::_load -> query returned: ${rLst.length} rows");

    for (var m in rLst) {
      // packets in ascending order (timestamp), newest to oldest, so add to back of queue
      // print("MeshDataPacketQueue::_load $m");
      MeshDataPacket rc = MeshDataPacket.fromMap(m);
      rc.stored = true;
      rc.dirty = false;
      cmdLst.add(rc);
    }
    return cmdLst;
  }
}
