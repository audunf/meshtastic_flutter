import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/bluetooth/ble_device_connector.dart';
import 'package:meshtastic_flutter/bluetooth/ble_device_interactor.dart';
import 'package:meshtastic_flutter/bluetooth/ble_scanner.dart';
import 'package:meshtastic_flutter/bluetooth/ble_status_monitor.dart';
import 'package:meshtastic_flutter/model/settings_model.dart';

/// Listen to Models. Listen to BLE events.
/// Control what happens when BLE state changes, or settings change
class BleConnectionLogic {
  final SettingsModel settingsModel;
  BleScanner bleScanner;
  BleStatusMonitor bleStatusMonitor;
  BleDeviceConnector bleDeviceConnector;
  BleDeviceInteractor bleDeviceInteractor;
  List<StreamSubscription<dynamic>> _streamSubscriptions = new List<StreamSubscription<dynamic>>.empty(growable: true);

  BleConnectionLogic(
      {required this.settingsModel,
      required this.bleStatusMonitor,
      required this.bleScanner,
      required this.bleDeviceConnector,
      required this.bleDeviceInteractor}) {
    // TODO: figure out whether it's possible to only listen in on a signle value (BT enable)
    // then, if enabled, - or if app gets started and it's already enabled -
    // keep scanning for devices
    // if found -> connect
    settingsModel.addListener(_settingsChangeHandler);

    _streamSubscriptions.add(bleStatusMonitor.state.listen(_bleStatusHandler));
    _streamSubscriptions.add(bleScanner.state.listen(_bleScannerHandler));
    _streamSubscriptions.add(bleDeviceConnector.state.listen(_bleConnectionStateHandler));
  }

  _settingsChangeHandler() {}

  _bleStatusHandler(BleStatus status) {}

  _bleScannerHandler(BleScannerState s) {}

  _bleConnectionStateHandler(ConnectionStateUpdate u) {}

  dispose() async {
    settingsModel.removeListener(_settingsChangeHandler);
    _streamSubscriptions.forEach((element) async {
      await element.cancel();
    });
  }
}
