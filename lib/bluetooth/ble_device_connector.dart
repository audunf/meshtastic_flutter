import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/bluetooth/reactive_state.dart';
import 'package:meshtastic_flutter/constants.dart' as Constants;

class BleDeviceConnector extends ReactiveState<ConnectionStateUpdate> {
  final FlutterReactiveBle _ble;
  final void Function(String message) _logMessage;
  final _deviceConnectionController = StreamController<ConnectionStateUpdate>.broadcast();
  // ignore: cancel_subscriptions
  late StreamSubscription<ConnectionStateUpdate> _connection;

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
    _connection = _ble
        .connectToAdvertisingDevice(
            id: deviceId,
            withServices: <Uuid>[Constants.meshtasticServiceId],
            prescanDuration: const Duration(seconds: 5),
            connectionTimeout: const Duration(seconds: 2))
        .listen(
      (conState) async {
        _logMessage('ConnectionState for device $deviceId : ${conState.connectionState}');
        await _ble.requestMtu(deviceId: deviceId, mtu: 500);
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
      await _connection.cancel();
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
