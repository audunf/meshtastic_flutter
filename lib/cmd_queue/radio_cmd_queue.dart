import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:meshtastic_flutter/mesh_utilities.dart' as Utils;
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pbserver.dart';
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
class RadioCommand {
  RadioCommandDirection direction;
  int bluetoothId;
  int timestamp;
  GeneratedMessage payload; // Both ToRadio and FromRadio inherit from GeneratedMessage
  int? checksum;
  bool acknowledged = true; // For ToRadio -> has the radio acknowledged reception?
  bool stored = false; // has object been stored in the database before?
  bool dirty = false; // has object changed since it was stored?

  RadioCommand(this.direction, this.bluetoothId, this.timestamp, this.acknowledged, this.payload, this.stored, this.dirty, [this.checksum]) {
    if (this.checksum == null) {
      this.checksum = Utils.makePackageChecksum(payload);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'direction': direction,
      'bluetooth_id': bluetoothId,
      'timestamp': timestamp,
      'checksum': checksum,
      'acknowledged': acknowledged,
      'stored': stored,
      'dirty': dirty,
      'payload': payload.writeToBuffer()
    };
  }

  static RadioCommand makeFromRadio(int bluetoothId, FromRadio p) {
    return RadioCommand(RadioCommandDirection.fromRadio, bluetoothId, DateTime.now().toUtc().millisecond, false, p, false, true);
  }

  static RadioCommand makeToRadio(int bluetoothId, ToRadio p) {
    return RadioCommand(RadioCommandDirection.fromRadio, bluetoothId, DateTime.now().toUtc().millisecond, false, p, false, true);
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
    return RadioCommand(RadioCommandDirectionInteger.fromInt(m['direction']), m['bluetooth_id'], m['timestamp'], m['acknowledged'], payload, m['stored'],
        m['dirty'], m['checksum']);
  }
}

///
class RadioCommandQueue extends MeshtasticDb {
  RadioCommandQueue._internal();
  static final RadioCommandQueue _singleton = new RadioCommandQueue._internal();
  static RadioCommandQueue get instance => _singleton;

  Queue<RadioCommand> _cmdQueue = new Queue<RadioCommand>();

  ///
  addToRadio(int bluetoothId, ToRadio pkt) {
    _cmdQueue.add(RadioCommand.makeToRadio(bluetoothId, pkt));
  }


  ///
  addFromRadio(int bluetoothId, FromRadio pkt) {
    _cmdQueue.add(RadioCommand.makeFromRadio(bluetoothId, pkt));
  }


  ///
  getFromRadioQueue() {
    return Queue.from(_cmdQueue.where((r) => r.direction == RadioCommandDirection.fromRadio));
  }


  ///
  getToRadioQueue({bool acknowledged = false}) {
    return Queue.from(_cmdQueue.where((r) => r.direction == RadioCommandDirection.toRadio && r.acknowledged == acknowledged));
  }


  ///
  save() async {
    if (_cmdQueue.isEmpty) return;

    return database.then((db) {
      return db?.transaction((txn) async {
        var batch = txn.batch();
        for (var i in _cmdQueue) {
          if (i.stored == true && i.dirty == false) continue;

          if (i.stored == true && i.dirty == true) {
            i.stored = true;
            i.dirty = false;
            var m = i.toMap();
            batch.update('radio_command', m, where: 'direction=?, bluetooth_id=?, epoch_ms=?', whereArgs: [m['direction'], m['bluetooth_id'], m['epoch_ms']]);
          } else if (i.stored == false) {
            i.stored = true;
            i.dirty = false;
            var m = i.toMap();
            batch.insert('radio_command', m);
          }
        }
        return batch.commit(noResult: true);
      });
    }).catchError((e, s) {
      print('RadioCommandQueue::save - exception $e $s');
    });
  }


  ///
  load(int bluetoothId) async {
    var timeAgo = DateTime.now().subtract(Duration(days: 2));

    return database.then((db) => db?.rawQuery('SELECT * FROM radio_command WHERE bluetooth_id=? AND epoch_ms > ? ORDER BY epoch_ms ASC;', [bluetoothId, timeAgo.millisecond]).then((rLst) {
      if (rLst.length <= 0) return;
      for (var m in rLst) {
        _cmdQueue.add(RadioCommand.fromMap(m));
      }
    })).catchError((e, s) {
      print('RadioCommandQueue::load - exception $e $s');
    });
  }
}
