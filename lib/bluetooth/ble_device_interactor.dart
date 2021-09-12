import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'ble_device_connector.dart';

class BleDeviceInteractor {
  FlutterReactiveBle ble;
  BleDeviceConnector connector;
  final void Function(String message) _logMessage;
  DeviceConnectionState _currentConnectionState = DeviceConnectionState.disconnected;

  BleDeviceInteractor({
    required this.ble,
    required this.connector,
    required void Function(String message) logMessage,
  })  :  _logMessage = logMessage {
    connector.state.listen(_btConnectionUpdateHandler);
  }

  /// keep track of connection state
  _btConnectionUpdateHandler(ConnectionStateUpdate s) async {
    _currentConnectionState = s.connectionState;
  }

  Future<List<DiscoveredService>> discoverServices(String deviceId) async {
    try {
      _logMessage('Start discovering services for: $deviceId');
      final result = await ble.discoverServices(deviceId);
      _logMessage('Discovering services finished');
      return result;
    } on Exception catch (e, s) {
      _logMessage('Error occurred when discovering services: $e');
      //print(s);
      rethrow;
    }
  }

  Future<List<int>> readCharacteristic(QualifiedCharacteristic characteristic) async {
    if (_currentConnectionState != DeviceConnectionState.connected) {
      print("BleDeviceInteractor::readCharacteristic - discarding attempt to read while not in CONNECTED state");
      return <int>[];
    }

    try {
      final result = await ble.readCharacteristic(characteristic);
      //_logMessage('Read ${characteristic.characteristicId}: value = $result');
      return result;
    } on Exception catch (e, s) {
      _logMessage(
        'Error occurred when reading ${characteristic.characteristicId}: $e',
      );
      //print(s);
      rethrow;
    }
  }

  Future<void> writeCharacteristicWithResponse(QualifiedCharacteristic characteristic, List<int> value) async {
    if (_currentConnectionState != DeviceConnectionState.connected) {
      print("BleDeviceInteractor::writeCharacteristicWithResponse - discarding attempt to write with response while not in CONNECTED state");
      return;
    }

    try {
      //_logMessage('Write with response value : $value to ${characteristic.characteristicId}');
      await ble.writeCharacteristicWithResponse(characteristic, value: value);
    } on Exception catch (e, s) {
      _logMessage(
        'Error occurred when writing with response ${characteristic.characteristicId}: $e',
      );
      //print(s);
      rethrow;
    }
  }

  Future<void> writeCharacteristicWithoutResponse(QualifiedCharacteristic characteristic, List<int> value) async {
    if (_currentConnectionState != DeviceConnectionState.connected) {
      print("BleDeviceInteractor::writeCharacteristicWithoutResponse - discarding attempt to write without response while not in CONNECTED state");
      return;
    }

    try {
      await writeCharacteristicWithoutResponse(characteristic, value);
      //_logMessage('Write without response value: $value to ${characteristic.characteristicId}');
    } on Exception catch (e, s) {
      _logMessage(
        'Error occurred when writing without response ${characteristic.characteristicId}: $e',
      );
      //print(s);
      rethrow;
    }
  }

  Stream<List<int>>? subscribeToCharacteristic(QualifiedCharacteristic characteristic) {
    if (_currentConnectionState != DeviceConnectionState.connected) {
      print("BleDeviceInteractor::subscribeToCharacteristic - discarding attempt to subscribe while not in CONNECTED state");
      return null;
    }
    _logMessage('Subscribing to: ${characteristic.characteristicId}');
    return ble.subscribeToCharacteristic(characteristic);
  }
}
