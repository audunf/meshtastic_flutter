

import 'package:latlong2/latlong.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';

import '../mesh_utilities.dart' as Utils;

class MeshPosition {
  int bluetoothId; // Bt ID of the radio which 'owns" this position -
  int nodeNum;
  double latitude;
  double longitude;
  int altitude;
  int batteryLevel;
  int timestampEpochSec;

  MeshPosition(this.bluetoothId, this.nodeNum, this.latitude, this.longitude, this.altitude, this.batteryLevel, this.timestampEpochSec);

  LatLng getLatLng() {
    return LatLng (latitude, longitude);
  }

  Map<String, dynamic> toMap() {
    return {
      'bluetooth_id': bluetoothId,
      'node_num': nodeNum,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'battery_level': batteryLevel,
      'timestamp_epoch_sec': timestampEpochSec
    };
  }

  static MeshPosition fromMap(Map<String, dynamic> m) {
    return MeshPosition(m['bluetooth_id'], m['node_num'], m['latitude'], m['longitude'], m['altitude'], m['battery_level'], m['timestamp_epoch_sec']);
  }

  static MeshPosition fromProtoBuf(int bluetoothId, int nodeNum, Position p) {
    LatLng ll = Utils.convertPositionToLatLng(p);
    return MeshPosition(bluetoothId, nodeNum, ll.latitude, ll.longitude, p.altitude, p.batteryLevel, p.time);
  }
}

/*
bluetooth_id         INTEGER NOT NULL,
node_num             INTEGER NOT NULL,
latitude             INTEGER NOT NULL,
longitude            INTEGER NOT NULL,
altitude             INTEGER NOT NULL,
battery_level        INTEGER NOT NULL,
timestamp_epoch_sec  INTEGER NOT NULL,
*/
