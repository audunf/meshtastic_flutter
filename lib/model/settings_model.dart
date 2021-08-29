
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';

import 'package:meshtastic_flutter/constants.dart' as Constants;
import 'package:meshtastic_flutter/mesh_utilities.dart' as MeshUtils;

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

  // notify of individual changes - attribute name, old value, new value
  var changeStreamController = StreamController<Tuple3<String, dynamic, dynamic>>.broadcast();
  Stream<Tuple3<String, dynamic, dynamic>> get changeStream => changeStreamController.stream;

  /// Must be called with await before continuing
  Future<void> initializeSettingsFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setBluetoothEnabled(prefs.getBool('bluetoothEnabled') ?? _bluetoothEnabled);
    setBluetoothDeviceId(prefs.getString('bluetoothDeviceId') ?? _bluetoothDeviceId);
    setBluetoothDeviceName(prefs.getString('bluetoothDeviceName') ?? _bluetoothDeviceName);
    setUserLongName(prefs.getString('userLongName') ?? _userLongName);
    setUserShortName(prefs.getString('userShortName') ?? _userShortName);
    setMyNodeNum(prefs.getInt('myNodeNum') ?? _myNodeNum);
    setRegionCode(prefs.getInt('regionCode') ?? _regionCode);
  }

  /// handle two competing/complementary ways to distribute state changes, and persist settings
  publishChange(String fieldName, dynamic oldValue, dynamic newValue) {
    notifyListeners(); // notify via 'ChangeNotifier'
    changeStreamController.sink.add(Tuple3(fieldName, oldValue, newValue)); // notify via home grown mechanism

    // persist
    if (newValue is String) {
      SharedPreferences.getInstance().then((prefs) => prefs.setString(fieldName, newValue));
    } else if (newValue is bool) {
      SharedPreferences.getInstance().then((prefs) => prefs.setBool(fieldName, newValue));
    } else if (newValue is int) {
      SharedPreferences.getInstance().then((prefs) => prefs.setInt(fieldName, newValue));
    } else if (newValue is double) {
      SharedPreferences.getInstance().then((prefs) => prefs.setDouble(fieldName, newValue));
    }
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

  setBluetoothEnabled(bool newValue) {
    var oldValue = _bluetoothEnabled;
    _bluetoothEnabled = newValue;
    publishChange('bluetoothEnabled', oldValue, _bluetoothEnabled);
  }

  setBluetoothDeviceId(String s) {
    var oldValue = _bluetoothDeviceId;
    _bluetoothDeviceId = s;
    publishChange('bluetoothDeviceId', oldValue, _bluetoothDeviceId);
  }

  setBluetoothDeviceName(String s) {
    var oldValue = _bluetoothDeviceName;
    _bluetoothDeviceName = s;
    publishChange('bluetoothDeviceName', oldValue, _bluetoothDeviceName);
  }

  setUserLongName(String s) async {
    var oldValue = _userLongName;
    _userLongName = s;
    publishChange('userLongName', oldValue, _userLongName);
  }

  setUserShortName(String s) async {
    var oldValue = _userShortName;
    _userShortName = s;
    publishChange('userShortName', oldValue, _userShortName);
  }

  setRegionCode(int c) async {
    if (c >= Constants.regionCodes.keys.first && c <= Constants.regionCodes.keys.last) {
      var oldValue = _regionCode;
      _regionCode = c;
      publishChange('regionCode', oldValue, _regionCode);
    }
  }

  setMyNodeNum(int num) async {
    var oldValue = _myNodeNum;
    _myNodeNum = num;
    publishChange('myNodeNum', oldValue, _myNodeNum);
  }

  void dispose() async {
    changeStreamController.close();
    super.dispose();
  }

  bool isBluetoothDeviceIdValidMac() {
    return MeshUtils.isValidBluetoothMac(bluetoothDeviceId);
  }
}