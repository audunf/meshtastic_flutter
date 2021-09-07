import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';

class MeshMyNodeInfo {
  int bluetoothId;
  int nodeNum;
  bool hasGps;
  int numBands;
  int maxChannels;
  String firmwareVersion;
  int errorCode;
  int errorAddr;
  int rebootCount;
  int msgTimeoutMSec;
  int minAppVersion;

  MeshMyNodeInfo(this.bluetoothId, this.nodeNum, this.hasGps, this.numBands, this.maxChannels, this.firmwareVersion, this.errorCode, this.errorAddr,
      this.rebootCount, this.msgTimeoutMSec, this.minAppVersion);

  Map<String, dynamic> toMap() {
    return {
      'bluetooth_id': bluetoothId,
      'node_num': nodeNum,
      'has_gps': hasGps ? 1 : 0,
      'num_bands': numBands,
      'max_channels': maxChannels,
      'firmware_version': firmwareVersion,
      'error_code': errorCode,
      'error_addr': errorAddr,
      'reboot_count': rebootCount,
      'msg_timeout_msec': msgTimeoutMSec,
      'min_app_version': minAppVersion
    };
  }

  static MeshMyNodeInfo fromMap(Map<String, dynamic> m) {
    return MeshMyNodeInfo(m['bluetooth_id'], m['node_num'], (m['has_gps'] == 0 ? false : true), m['num_bands'], m['max_channels'], m['firmware_version'], m['error_code'],
        m['error_addr'], m['reboot_count'], m['msg_timeout_msec'], m['min_app_version']);
  }

  static MeshMyNodeInfo fromProtoBuf(int bluetoothId, MyNodeInfo n) {
    return MeshMyNodeInfo(bluetoothId, n.myNodeNum, n.hasGps, n.numBands, n.maxChannels, n.firmwareVersion, n.errorCode.value, n.errorAddress, n.rebootCount, n.messageTimeoutMsec, n.minAppVersion);
  }
}

/*
bluetooth_id     INTEGER NOT NULL,
node_num         INTEGER NOT NULL,
has_gps          INTEGER NOT NULL,
num_bands        INTEGER NOT NULL,
max_channels     INTEGER NOT NULL,
firmware_version VARCHAR(20) NOT NULL,
error_code       INTEGER DEFAULT 0 NOT NULL,
error_addr       INTEGER DEFAULT 0 NOT NULL,
reboot_count     INTEGER DEFAULT 0 NOT NULL,
msg_timeout_msec INTEGER DEFAULT 0 NOT NULL,
min_app_version  INTEGER DEFAULT 0 NOT NULL,
 */
