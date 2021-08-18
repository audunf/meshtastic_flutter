
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/constants.dart' as Constants;

/// Settings related to the app itself and to the connected node.
class SettingsModel extends ChangeNotifier {
  bool _bluetoothEnabled = false;
  String _bluetoothDeviceId = "None";
  String _bluetoothDeviceName = "None";

  int _myNodeNum = 0;
  int _regionCode = 0;
  String _userLongName = "Unknown";
  String _userShortName = "Unknown";

  bool get bluetoothEnabled {
    return _bluetoothEnabled;
  }

  String get bluetoothDeviceId {
    return _bluetoothDeviceId;
  }

  String get bluetoothDeviceName {
    return _bluetoothDeviceName;
  }

  String get userLongName {
    return _userLongName;
  }

  String get userShortName {
    return _userShortName;
  }

  int get regionCode {
    return _regionCode;
  }

  int get myNodeNum {
    return _myNodeNum;
  }

  String get regionName {
    return Constants.regionCodes[_regionCode] ?? 'Unset';
  }

  setBluetoothEnabled(bool b) {
    _bluetoothEnabled = b;
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

  setUserLongName(String s) {
    _userLongName = s;
    notifyListeners();
  }

  setUserShortName(String s) {
    _userShortName = s;
    notifyListeners();
  }

  setRegionCode(int t) {
    if (t >= Constants.regionCodes.keys.first && t <= Constants.regionCodes.keys.last) {
      _regionCode = t;
      notifyListeners();
    }
  }

  setMyNodeNum(int num) {
    _myNodeNum = num;
    notifyListeners();
  }

}