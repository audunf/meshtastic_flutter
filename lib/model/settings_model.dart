
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/constants.dart' as Constants;

class SettingsModel extends ChangeNotifier {
  bool _enableBluetooth = false;
  String _bluetoothDeviceId = "None";
  String _bluetoothDeviceName = "None";
  String _userName = "Unknown"; 
  int _regionCode = 0;

  bool get enableBluetooth {
    return _enableBluetooth;
  }

  String get bluetoothDeviceId {
    return _bluetoothDeviceId;
  }

  String get bluetoothDeviceName {
    return _bluetoothDeviceName;
  }

  String get userName {
    return _userName;
  }

  int get regionCode {
    return _regionCode;
  }

  String get regionName {
    return Constants.regionCodes[_regionCode] ?? 'Unset';
  }

  setEnableBluetooth(bool b) {
    _enableBluetooth = b;
    notifyListeners();
  }

  setBluetoothDeviceId(String s) {
    _bluetoothDeviceId = s;
    notifyListeners();
  }

  setBluetoothDeviceName(String s) {
    _bluetoothDeviceName = s;
    notifyListeners();
  }

  setUserName(String s) {
    _userName = s;
    notifyListeners();
  }

  setRegionCode(int t) {
    if (t >= Constants.regionCodes.keys.first && t <= Constants.regionCodes.keys.last) {
      _regionCode = t;
      notifyListeners();
    }
  }
}