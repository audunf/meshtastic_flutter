import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/bluetooth/reactive_state.dart';
import 'package:meta/meta.dart';


/// Provided in a stream
@immutable
class BleScannerState {
  const BleScannerState({
    required this.discoveredDevices,
    required this.scanIsInProgress,
  });

  final List<DiscoveredDevice> discoveredDevices;
  final bool scanIsInProgress;

  String toString() {
    String s = "scanIsInProgress=$scanIsInProgress, found devices: ";
    discoveredDevices.forEach((e) { s += "MAC=: ${e.id}, "; });
    return s;
  }
}


///
class BleScanner implements ReactiveState<BleScannerState> {
  final FlutterReactiveBle _ble;
  final void Function(String message) _logMessage;
  final StreamController<BleScannerState> _stateStreamController = StreamController.broadcast();
  final _devices = <DiscoveredDevice>[];
  StreamSubscription? _subscription;

  @override
  Stream<BleScannerState> get state => _stateStreamController.stream;

  /// ctor
  BleScanner({
    required FlutterReactiveBle ble,
    required Function(String message) logMessage,
  })  : _ble = ble,
        _logMessage = logMessage;


  ///
  void startScan(List<Uuid> serviceIds, ScanMode scanMode) {
    _logMessage('BleScanner::startScan - starting BLE discovery');

    _devices.clear();
    _subscription?.cancel();

    _subscription = _ble.scanForDevices(withServices: serviceIds, scanMode: scanMode).listen((device) {
      final knownDeviceIndex = _devices.indexWhere((d) => d.id == device.id);
      if (knownDeviceIndex >= 0) {
        _devices[knownDeviceIndex] = device;
      } else {
        _devices.add(device);
      }
      _pushState();
    }, onError: (Object e) => _logMessage('Device scan fails with error: $e'));
    _pushState();
  }

  ///
  void _pushState() {
    if (_stateStreamController.isClosed) return;

    _stateStreamController.add(
      BleScannerState(
        discoveredDevices: _devices,
        scanIsInProgress: _subscription != null,
      ),
    );
  }

  ///
  Future<void> stopScan() async {
    _logMessage('stopScan - stop BLE discovery');
    await _subscription?.cancel();
    _subscription = null;
    _pushState();
  }

  ///
  isScanInProgress() {
    return _subscription != null;
  }

  ///
  Future<void> dispose() async {
    await _stateStreamController.close();
  }
}
