import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:meshtastic_flutter/mesh_utilities.dart' as Utils;
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pbserver.dart';
import 'package:meshtastic_flutter/proto-autogen/portnums.pb.dart';
import 'package:protobuf/protobuf.dart';
import 'package:sqflite/sqflite.dart';

import 'meshtastic_db.dart';

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
  MeshDataPacketDirection direction = MeshDataPacketDirection.toRadio;
  int bluetoothId = 0;
  int timestamp = 0;
  GeneratedMessage payload; // Both ToRadio and FromRadio inherit from GeneratedMessage
  int checksum = 0;
  int payloadVariant =
      FromRadio_PayloadVariant.notSet.index; // TODO: could be dangerous if protobuf definition changes? Add own function to return int based on type?
  bool acknowledged = true; // For ToRadio -> has the radio acknowledged reception?
  bool stored = false; // has object been stored in the database before?
  bool dirty = false; // has object changed since it was stored?

  MeshDataPacket(this.direction, this.bluetoothId, this.timestamp, this.acknowledged, this.payload, this.stored, this.dirty) {
    this.checksum = Utils.makePackageChecksum(payload);
    if (direction == MeshDataPacketDirection.fromRadio) {
      payloadVariant = Utils.fromRadioPayloadVariantToInteger(payload as FromRadio);
    } else if (direction == MeshDataPacketDirection.toRadio) {
      payloadVariant = Utils.toRadioPayloadVariantToInteger(payload as ToRadio);
    }
  }

  int getFromNodeNum() {
    if (direction == MeshDataPacketDirection.fromRadio) {
      FromRadio p = payload as FromRadio;
      if (p.whichPayloadVariant() == FromRadio_PayloadVariant.packet) {
        return p.packet.from;
      }
    }
    return 0;
  }

  DateTime getDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(this.timestamp);
  }

  String getBluetoothIdAsString() {
    String id = Utils.convertBluetoothAddressToString(this.bluetoothId);
    print("getBluetoothIdAsString $id");
    return id;
  }

  Map<String, dynamic> toMap() {
    return {
      'direction': direction.toInt(),
      'bluetooth_id': bluetoothId,
      'epoch_ms': timestamp,
      'checksum': checksum,
      'acknowledged': (acknowledged ? 1 : 0),
      'payload_variant': payloadVariant,
      'stored': (stored ? 1 : 0),
      'dirty': (dirty ? 1 : 0),
      'payload': payload.writeToBuffer()
    };
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

  static MeshDataPacket makeFromRadio(int bluetoothId, FromRadio p) {
    int timestampMS = DateTime.now().toUtc().millisecond;
    if (p.whichPayloadVariant() == FromRadio_PayloadVariant.packet) {
      if (p.packet.rxTime > 0) {
        timestampMS = p.packet.rxTime * 1000; // to MS
      }
    }
    return MeshDataPacket(MeshDataPacketDirection.fromRadio, bluetoothId, timestampMS, false, p, false, true);
  }

  static MeshDataPacket makeToRadio(int bluetoothId, ToRadio p) {
    int timestampMS = DateTime.now().toUtc().millisecond;
    if (p.whichPayloadVariant() == ToRadio_PayloadVariant.packet) {
      if (p.packet.rxTime > 0) {
        timestampMS = p.packet.rxTime * 1000; // to MS
      }
    }
    return MeshDataPacket(MeshDataPacketDirection.toRadio, bluetoothId, timestampMS, false, p, false, true);
  }

  static MeshDataPacket fromMap(Map<String, dynamic> m) {
    GeneratedMessage payload;
    MeshDataPacketDirection rd = RadioCommandDirectionInteger.fromInt(m['direction']);
    if (rd == MeshDataPacketDirection.toRadio) {
      payload = ToRadio.fromBuffer(m['payload']);
    } else if (rd == MeshDataPacketDirection.fromRadio) {
      payload = FromRadio.fromBuffer(m['payload']);
    } else {
      throw new ErrorDescription("payload from DB doesn't match ToRadio or FromRadio");
    }
    return MeshDataPacket(RadioCommandDirectionInteger.fromInt(m['direction']), m['bluetooth_id'], m['epoch_ms'], (m['acknowledged'] == 0 ? false : true),
        payload, (m['stored'] == 0 ? false : true), (m['dirty'] == 0 ? false : true));
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
  void addToRadioBack(ToRadio pkt) {
    if (pkt.whichPayloadVariant() != ToRadio_PayloadVariant.packet) return; // only add data packets
    MeshDataPacket rc = MeshDataPacket.makeToRadio(_bluetoothId, pkt);
    _addRadioCommandBack(rc);
  }

  ///
  void addFromRadioBack(FromRadio pkt) {
    if (pkt.whichPayloadVariant() != FromRadio_PayloadVariant.packet) return; // only add data packets
    MeshDataPacket rc = MeshDataPacket.makeFromRadio(_bluetoothId, pkt);
    _addRadioCommandBack(rc);
  }

  ///
  void _addRadioCommandBack(MeshDataPacket rc) {
    if (_hasPacketWithChecksum(rc.checksum)) {
      print("addRadioCommandBack - reAddPacket");
      _reAddPacket(rc);
      return;
    }
    _cmdQueue.addLast(rc);
    notifyListeners();
    save();
  }

  ///
  Queue<MeshDataPacket> getFromRadioQueue() {
    return Queue.from(_cmdQueue.where((r) => r.direction == MeshDataPacketDirection.fromRadio));
  }

  ///
  Queue<MeshDataPacket> getToRadioQueue({bool acknowledged = false}) {
    return Queue.from(_cmdQueue.where((r) => r.direction == MeshDataPacketDirection.toRadio && r.acknowledged == acknowledged));
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

  /// True if packet with checksum is present in queue
  bool _hasPacketWithChecksum(int checksum) {
    return _cmdQueue.any((MeshDataPacket e) => e.checksum == checksum);
  }

  /// Has un-acknowledged (unsent) packets
  bool hasUnAcknowledgedToRadioPackets() {
    return _cmdQueue.any((MeshDataPacket e) => e.direction == MeshDataPacketDirection.toRadio && e.acknowledged == false);
  }

  /// When same packet is seen 'again' (same checksum), remove old, add new to get the timestamps right
  void _reAddPacket(MeshDataPacket rc) {
    _cmdQueue.removeWhere((MeshDataPacket e) => e.checksum == rc.checksum && e.bluetoothId == rc.bluetoothId && e.direction == rc.direction);
    rc.dirty = true;
    rc.stored = false;
    // clean up the database - easier to delete the old packet than try to update it
    MeshtasticDb.database.then((db) {
      return db.delete('radio_command', where: 'direction=? AND bluetooth_id=? AND checksum=?', whereArgs: [rc.direction.index, rc.bluetoothId, rc.checksum]);
    });
    _cmdQueue.addLast(rc);
    notifyListeners();
    save();
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

    return MeshtasticDb.database.then((db) {
      return db.transaction((txn) async {
        var batch = txn.batch();
        for (var i in _cmdQueue) {
          if (i.stored == true && i.dirty == false) continue;

          if (i.stored == true && i.dirty == true) {
            i.stored = true;
            i.dirty = false;
            var m = i.toMap();
            // TODO FAILS HERE!!!
            batch.update('radio_command', m,
                where: 'direction=? AND bluetooth_id=? AND epoch_ms=? AND payload_variant=?',
                whereArgs: [m['direction'], m['bluetooth_id'], m['epoch_ms'], m['payload_variant']]);
            ++countUpdate;
          } else if (i.stored == false) {
            i.stored = true;
            i.dirty = false;
            var m = i.toMap();
            batch.insert('radio_command', m);
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
    print("MeshDataPacketQueue::_load");
    var timeAgo = DateTime.now().subtract(Duration(days: 2));
    List<MeshDataPacket> cmdLst = <MeshDataPacket>[];

    Database db = await MeshtasticDb.database;
    // Load from DB. Oldest first (Ascending order of epoch_ms)
    List<Map<String, Object?>> rLst = await db.rawQuery(
        'SELECT * FROM radio_command WHERE bluetooth_id=? AND rx_time_epoch_sec > ? ORDER BY rx_time_epoch_sec ASC;', [_bluetoothId, timeAgo.second]);
    print(" -> query returned: ${rLst.length} rows");
    for (var m in rLst) {
      // packets in ascending order (timestamp), newest to oldest, so add to back of queue
      print("MeshDataPacketQueue::_load $m");
      MeshDataPacket rc = MeshDataPacket.fromMap(m);
      rc.stored = true;
      rc.dirty = false;
      cmdLst.add(rc);
    }
    return cmdLst;
  }
}
