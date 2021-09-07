

import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';

class MeshNode {
  int bluetoothId; 
  int nodeNum; 
  String userId;
  double snr; 
  int lastHeardEpochSec;

  MeshNode(this.bluetoothId, this.nodeNum, this.userId, this.snr, this.lastHeardEpochSec);

  Map<String, dynamic> toMap() {
    return {
      'bluetooth_id': bluetoothId,
      'node_num': nodeNum,
      'user_id': userId,
      'snr': snr,
      'last_heard_epoch_sec': lastHeardEpochSec
    };
  }

  static MeshNode fromMap(Map<String, dynamic> m) {
    return MeshNode(m['bluetooth_id'], m['node_num'], m['user_id'], m['snr'], m['last_heard_epoch_sec']);
  }

  static MeshNode fromProtoBuf(int bluetoothId, NodeInfo n) {
    return MeshNode(bluetoothId, n.num, n.user.id, n.snr, n.lastHeard);
  }
}

/*
   bluetooth_id          INTEGER NOT NULL,
   node_num              INTEGER NOT NULL,
   user_id               VARCHAR(100) NOT NULL,
   snr                   REAL NOT NULL,
   last_heard_epoch_sec  INTEGER NOT NULL,
 */