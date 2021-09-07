

import 'dart:typed_data';

import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';

class MeshUser {
  int bluetoothId;
  String userId;
  String longName;
  String shortName;
  List<int> macAddr;
  int hwModel;
  bool isLicensed;

  MeshUser(this.bluetoothId, this.userId, this.longName, this.shortName, this.macAddr, this.hwModel, this.isLicensed);

  Map<String, dynamic> toMap() {
    return {
      'bluetooth_id': bluetoothId,
      'user_id': userId,
      'long_name': longName,
      'short_name': shortName,
      'mac_addr': Uint8List.fromList(macAddr),
      'hw_model': hwModel,
      'is_licensed': isLicensed ? 1 : 0
    };
  }

  static MeshUser fromMap(Map<String, dynamic> m) {
    return MeshUser(m['bluetooth_id'], m['user_id'], m['long_name'], m['short_name'], m['mac_addr'], m['hw_model'], (m['is_licensed'] == 0 ? false : true));
  }

  static MeshUser fromProtoBuf(int bluetoothId, User u) {
    return MeshUser(bluetoothId, u.id, u.longName, u.shortName, u.macaddr, u.hwModel.value, u.isLicensed);
  }
}

/*
bluetooth_id    INTEGER NOT NULL,
user_id         VARCHAR(100) NOT NULL,
long_name       VARCHAR(255) NOT NULL,
short_name      VARCHAR(10) NOT NULL,
mac_addr        BLOB NOT NULL,
hw_model        INTEGER NOT NULL,
is_licensed     INTEGER DEFAULT 0 NOT NULL,
 */
