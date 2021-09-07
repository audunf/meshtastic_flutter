
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

  // notify of individual changes - attribute name, old value, new value
  var changeStreamController = StreamController<Tuple3<String, dynamic, dynamic>>.broadcast();
  Stream<Tuple3<String, dynamic, dynamic>> get changeStream => changeStreamController.stream;

  /// Must be called with await before continuing
  Future<void> initializeSettingsFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setBluetoothEnabled(prefs.getBool('bluetoothEnabled') ?? _bluetoothEnabled);
    setBluetoothDeviceId(prefs.getString('bluetoothDeviceId') ?? _bluetoothDeviceId);
    setBluetoothDeviceName(prefs.getString('bluetoothDeviceName') ?? _bluetoothDeviceName);
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

  int get bluetoothDeviceIdInt {
    return MeshUtils.convertBluetoothAddressToInt(_bluetoothDeviceId);
  }

  String get bluetoothDeviceName {
    return _bluetoothDeviceName;
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

  /// true if current BT ID is a valid MAC address
  bool isBluetoothDeviceIdValidMac() {
    return MeshUtils.isValidBluetoothMac(bluetoothDeviceId);
  }

  void dispose() async {
    changeStreamController.close();
    super.dispose();
  }
}