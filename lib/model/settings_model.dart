
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtastic_flutter/constants.dart' as Constants;

/// Settings related to the app itself and to the connected node.
/// Settings are persisted. User *MUST* call 'initializeSettingsFromStorage' before using!
class SettingsModel extends ChangeNotifier {
  bool _bluetoothEnabled = false;
  String _bluetoothDeviceId = "Unknown";
  String _bluetoothDeviceName = "Unknown";
  String _userLongName = "Unknown";
  String _userShortName = "Unknown";
  int _myNodeNum = 0;
  int _regionCode = 0;

  /// Must be called with await before continuing
  initializeSettingsFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _bluetoothEnabled = (prefs.getBool('bluetoothEnabled') ?? _bluetoothEnabled);
    _bluetoothDeviceId = (prefs.getString('bluetoothDeviceId') ?? _bluetoothDeviceId);
    _bluetoothDeviceName = (prefs.getString('bluetoothDeviceName') ?? _bluetoothDeviceName);
    _userLongName =  (prefs.getString('userLongName') ?? _userLongName);
    _userShortName =  (prefs.getString('userShortName') ?? _userShortName);
    _myNodeNum = (prefs.getInt('myNodeNum') ?? _myNodeNum);
    _regionCode = (prefs.getInt('regionCode') ?? _regionCode);
  }

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
    return Constants.regionCodes[this.regionCode] ?? 'Unknown';
  }

  setBluetoothEnabled(bool b) {
    _bluetoothEnabled = b;
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('bluetoothEnabled', b));
    notifyListeners();
  }

  setBluetoothDeviceId(String s) {
    _bluetoothDeviceId = s;
    SharedPreferences.getInstance().then((prefs) => prefs.setString('bluetoothDeviceId', s));
    notifyListeners();
  }

  setBluetoothDeviceName(String s) {
    _bluetoothDeviceName = s;
    SharedPreferences.getInstance().then((prefs) => prefs.setString('bluetoothDeviceName', s));
    notifyListeners();
  }

  setUserLongName(String s) async {
    _userLongName = s;
    SharedPreferences.getInstance().then((prefs) => prefs.setString('userLongName', s));
    notifyListeners();
  }

  setUserShortName(String s) async {
    _userShortName = s;
    SharedPreferences.getInstance().then((prefs) => prefs.setString('userShortName', s));
    notifyListeners();
  }

  setRegionCode(int c) async {
    if (c >= Constants.regionCodes.keys.first && c <= Constants.regionCodes.keys.last) {
      _regionCode = c;
      SharedPreferences.getInstance().then((prefs) => prefs.setInt('regionCode', c));
      notifyListeners();
    }
  }

  setMyNodeNum(int num) async {
    _myNodeNum = num;
    SharedPreferences.getInstance().then((prefs) => prefs.setInt('myNodeNum', num));
    notifyListeners();
  }

}