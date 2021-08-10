
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class SettingsModel extends ChangeNotifier {
  String _bluetoothDeviceId = "None";

  String get bluetoothDeviceId {
    return _bluetoothDeviceId;
  }

  setBluetoothDeviceId(String s) {
    _bluetoothDeviceId = s;
    notifyListeners();
  }
}