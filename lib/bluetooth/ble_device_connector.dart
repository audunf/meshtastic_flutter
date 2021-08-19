import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/bluetooth/reactive_state.dart';
import 'package:meshtastic_flutter/constants.dart' as Constants;

class BleDeviceConnector extends ReactiveState<ConnectionStateUpdate> {
  String _currentConnectedDeviceId = "";
  final FlutterReactiveBle _ble;
  final void Function(String message) _logMessage;
  final _deviceConnectionController = StreamController<ConnectionStateUpdate>.broadcast();
  // ignore: cancel_subscriptions
  StreamSubscription<ConnectionStateUpdate>? _connection;

  @override
  Stream<ConnectionStateUpdate> get state => _deviceConnectionController.stream;

  BleDeviceConnector({
    required FlutterReactiveBle ble,
    required Function(String message) logMessage,
  })  : _ble = ble,
        _logMessage = logMessage {
    //_logMessage("BleDeviceConnector::ctor");
  }

  Future<void> connect(String deviceId) async {
    _logMessage('Start connecting to $deviceId');

    // Search for specific services
    Map<Uuid, List<Uuid>> servicesWithCharacteristics = new Map();
    servicesWithCharacteristics[Constants.meshtasticServiceId] = <Uuid>[Constants.readFromRadioCharacteristicId, Constants.writeToRadioCharacteristicId];

    // if there is an active connection -> disconnect before attempting to connect
    if (_connection != null && _currentConnectedDeviceId.length > 0) {
      disconnect(_currentConnectedDeviceId);
    }

    _connection = _ble
        .connectToAdvertisingDevice(
            id: deviceId,
            withServices: <Uuid>[Constants.meshtasticServiceId],
            servicesWithCharacteristicsToDiscover: servicesWithCharacteristics,
            prescanDuration: const Duration(seconds: 5),
            connectionTimeout: const Duration(seconds: 5))
        .listen(
      (conState) async {
        _logMessage('ConnectionState for device $deviceId : ${conState.connectionState}');
        if (conState.connectionState == DeviceConnectionState.connected) {
          await _ble.requestMtu(deviceId: deviceId, mtu: 500);
        }
        _deviceConnectionController.add(conState);
      },
      onError: (dynamic err) {
        _logMessage('Connecting to device $deviceId resulted in error $err');
      },
    );
  }

  Future<void> disconnect(String deviceId) async {
    try {
      _logMessage('disconnecting from device: $deviceId');
      _currentConnectedDeviceId = "";  // clear ID of current connected device
      await _connection?.cancel();
      _connection = null;
    } on Exception catch (e, _) {
      _logMessage("Error disconnecting from a device: $e");
    } finally {
      // Since [_connection] subscription is terminated, the "disconnected" state cannot be received and propagated
      _deviceConnectionController.add(
        ConnectionStateUpdate(
          deviceId: deviceId,
          connectionState: DeviceConnectionState.disconnected,
          failure: null,
        ),
      );
    }
  }

  Future<void> dispose() async {
    await _deviceConnectionController.close();
  }
}
