import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:meshtastic_flutter/mesh_utilities.dart' as Utils;
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pbserver.dart';
import 'package:meshtastic_flutter/proto-autogen/portnums.pb.dart';
import 'package:protobuf/protobuf.dart';

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
enum RadioCommandDirection { toRadio, fromRadio }

extension RadioCommandDirectionInteger on RadioCommandDirection {
  String get name => describeEnum(this);

  static RadioCommandDirection fromInt(int v) {
    if (v == 0)
      return RadioCommandDirection.toRadio;
    else
      return RadioCommandDirection.fromRadio;
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
/// TODO: look at https://github.com/meshtastic/Meshtastic-Android/blob/4d9ae0df730d8c37246c002de1c95609a512e296/app/src/main/java/com/geeksville/mesh/DataPacket.kt
class RadioCommand {
  RadioCommandDirection direction = RadioCommandDirection.toRadio;
  int bluetoothId = 0;
  int timestamp = 0;
  GeneratedMessage payload; // Both ToRadio and FromRadio inherit from GeneratedMessage
  int checksum = 0;
  int payloadVariant =
      FromRadio_PayloadVariant.notSet.index; // TODO: could be dangerous if protobuf definition changes? Add own function to return int based on type?
  bool acknowledged = true; // For ToRadio -> has the radio acknowledged reception?
  bool stored = false; // has object been stored in the database before?
  bool dirty = false; // has object changed since it was stored?

  RadioCommand(this.direction, this.bluetoothId, this.timestamp, this.acknowledged, this.payload, this.stored, this.dirty) {
    this.checksum = Utils.makePackageChecksum(payload);
    if (direction == RadioCommandDirection.fromRadio) {
      payloadVariant = Utils.fromRadioPayloadVariantToInteger(payload as FromRadio);
    } else if (direction == RadioCommandDirection.toRadio) {
      payloadVariant = Utils.toRadioPayloadVariantToInteger(payload as ToRadio);
    }
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
    if (direction == RadioCommandDirection.fromRadio)
      return payload as FromRadio;
    else
      return null;
  }

  ToRadio? getPayloadAsToRadio() {
    if (direction == RadioCommandDirection.toRadio)
      return payload as ToRadio;
    else
      return null;
  }

  static RadioCommand makeFromRadio(int bluetoothId, FromRadio p) {
    return RadioCommand(RadioCommandDirection.fromRadio, bluetoothId, DateTime.now().toUtc().millisecond, false, p, false, true);
  }

  static RadioCommand makeToRadio(int bluetoothId, ToRadio p) {
    return RadioCommand(RadioCommandDirection.toRadio, bluetoothId, DateTime.now().toUtc().millisecond, false, p, false, true);
  }

  static RadioCommand fromMap(Map<String, dynamic> m) {
    GeneratedMessage payload;
    RadioCommandDirection rd = RadioCommandDirectionInteger.fromInt(m['direction']);
    if (rd == RadioCommandDirection.toRadio) {
      payload = ToRadio.fromBuffer(m['payload']);
    } else if (rd == RadioCommandDirection.fromRadio) {
      payload = FromRadio.fromBuffer(m['payload']);
    } else {
      throw new ErrorDescription("payload from DB doesn't match ToRadio or FromRadio");
    }
    return RadioCommand(RadioCommandDirectionInteger.fromInt(m['direction']), m['bluetooth_id'], m['epoch_ms'], (m['acknowledged'] == 0 ? false : true),
        payload, (m['stored'] == 0 ? false : true), (m['dirty'] == 0 ? false : true));
  }
}

///
///
///
class RadioCommandQueue extends ChangeNotifier {
  int _bluetoothId = 0;
  /// back of the queue are the most recent packets.
  DoubleLinkedQueue<RadioCommand> _cmdQueue = new DoubleLinkedQueue<RadioCommand>();

  RadioCommandQueue();

  /// set new BT ID, load all Radio packets for this device, return 'true' if ID actually changed
  Future<bool> setBluetoothIdFromString(String hexId) async {
    return await setBluetoothId(Utils.convertBluetoothAddressToInt(hexId));
  }

  /// set new BT ID, load all Radio packets for this device, return 'true' if ID actually changed
  Future<bool> setBluetoothId(int id) async {
    if (id == _bluetoothId) return false;
    await save();
    _cmdQueue.clear();
    _bluetoothId = id;
    notifyListeners();
    return true;
  }

  /// Add to the front of the queue.
  /*
  void _addToRadioFront(ToRadio pkt) {
    RadioCommand rc = RadioCommand.makeToRadio(_bluetoothId, pkt);
    if (_hasPacketWithChecksum(rc.checksum)) {
      print("addToRadioFront - reAddPacket");
      _reAddPacket(rc);
      return;
    }
    _cmdQueue.addFirst(rc);
    notifyListeners();
    save();
  }
   */

  ///
  void addToRadioBack(ToRadio pkt) {
    RadioCommand rc = RadioCommand.makeToRadio(_bluetoothId, pkt);
    addRadioCommandBack(rc);
  }

  ///
  void addFromRadioBack(FromRadio pkt) {
    RadioCommand rc = RadioCommand.makeFromRadio(_bluetoothId, pkt);
    addRadioCommandBack(rc);
  }

  ///
  void addRadioCommandBack(RadioCommand rc) {
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
  Queue<RadioCommand> getFromRadioQueue() {
    return Queue.from(_cmdQueue.where((r) => r.direction == RadioCommandDirection.fromRadio));
  }

  ///
  Queue<RadioCommand> getToRadioQueue({bool acknowledged = false}) {
    return Queue.from(_cmdQueue.where((r) => r.direction == RadioCommandDirection.toRadio && r.acknowledged == acknowledged));
  }

  /// get all the text messages in the message queue. Silly filtering to get there.
  Queue<RadioCommand> getTextMessageQueue() {
    var isTextMessage = (RadioCommand r) {
      if (r.direction == RadioCommandDirection.toRadio) {
        ToRadio? tr = r.getPayloadAsToRadio();
        if (tr == null) return false;
        if (tr.whichPayloadVariant() == ToRadio_PayloadVariant.packet &&
            tr.packet.whichPayloadVariant() == MeshPacket_PayloadVariant.decoded &&
            tr.packet.decoded.portnum == PortNum.TEXT_MESSAGE_APP) {
          return true;
        }
      } else if (r.direction == RadioCommandDirection.fromRadio) {
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
  Queue<RadioCommand> getRadioQueue() {
    return _cmdQueue;
  }

  /// clear contents of the queue
  void clearRadioQueue() {
    _cmdQueue.clear();
    notifyListeners();
  }

  /// True if packet with checksum is present in queue
  bool _hasPacketWithChecksum(int checksum) {
    return _cmdQueue.any((RadioCommand e) => e.checksum == checksum);
  }

  /// Has un-acknowledged (unsent) packets
  bool hasUnAcknowledgedToRadioPackets() {
    return _cmdQueue.any((RadioCommand e) => e.direction == RadioCommandDirection.toRadio && e.acknowledged == false);
  }

  /// When same packet is seen 'again' (same checksum), remove old, add new to get the timestamps right
  void _reAddPacket(RadioCommand rc) {
    _cmdQueue.removeWhere((RadioCommand e) => e.checksum == rc.checksum && e.bluetoothId == rc.bluetoothId && e.direction == rc.direction);
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
    _cmdQueue.forEach((RadioCommand e) {
      e.dirty = false;
      e.stored = true;
    });
  }

  ///
  save() async {
    int countInsert = 0;
    int countUpdate = 0;
    print("RadioCommandQueue::save");
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
        print("RadioCommandQueue::save - insert=$countInsert update=$countUpdate");
        return batch.commit(noResult: true);
      });
    }).catchError((e, s) {
      print('RadioCommandQueue::save - exception $e $s');
    });
  }
}
