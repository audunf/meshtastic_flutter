import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/model/settings_model.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';
import 'package:meshtastic_flutter/protocol/to_radio.dart';
import 'package:tuple/tuple.dart';

import 'ble_data_streams.dart';
import 'ble_device_connector.dart';
import 'ble_device_interactor.dart';
import 'ble_scanner.dart';
import 'ble_status_monitor.dart';
import 'package:meshtastic_flutter/constants.dart' as Constants;
import 'package:meshtastic_flutter/mesh_utilities.dart' as MeshUtils;

class BleConnectionLogic {
  BleScanner scanner;
  BleStatusMonitor monitor;
  BleDeviceConnector connector;
  BleDeviceInteractor interactor;
  BleDataStreams bleDataStreams;
  SettingsModel settingsModel;

  bool _bleScanIsInProgress = false;
  BleStatus _currentBleStatus = BleStatus.unknown;
  DeviceConnectionState _currentConnectionState = DeviceConnectionState.disconnected;

  /// ctor
  BleConnectionLogic(
      {required this.settingsModel,
      required this.scanner,
      required this.monitor,
      required this.connector,
      required this.interactor,
      required this.bleDataStreams}) {
    settingsModel.changeStream.listen(_settingsModelHandler);
    scanner.state.listen(_btScannerStateHandler);
    monitor.state.listen(_btStatusMonitorHandler);
    connector.state.listen(_btConnectionUpdateHandler);
  }

  /// scan for the device from settingsModel.bluetoothDeviceId
  _startScan() {
    print("BleConnectionLogic::_startScan");
    if (settingsModel.bluetoothEnabled == false) {
      print("BleConnectionLogic::_startScan - BT disabled");
      return;
    }
    if (!MeshUtils.isValidBluetoothMac(settingsModel.bluetoothDeviceId)) {
      print("BleConnectionLogic::_startScan - bluetoothDeviceId not valid ${settingsModel.bluetoothDeviceId}");
      return;
    }
    if (_bleScanIsInProgress) {
      print("BleConnectionLogic::_startScan -> scan already in progress -> do nothing");
      return;
    }
    print("BleConnectionLogic::_startScan -> starting scan");
    _bleScanIsInProgress = true;
    scanner.startScan(<Uuid>[Constants.meshtasticServiceId], ScanMode.balanced);
  }


  ///
  _stopScan() async {
    if (!_bleScanIsInProgress) {
      print("BleConnectionLogic::_stopScan -> no scan in progress -> return");
      return;
    }
    await scanner.stopScan();
    _bleScanIsInProgress = false;
  }


  /// handle changes to different settings
  _settingsModelHandler(Tuple3<String, dynamic, dynamic> c) {
    var paramName = c.item1;
    var oldValue = c.item2;
    var newValue = c.item3;
    print("BleConnectionLogic settingsModel changed (stream!) -> attribute name='${c.item1}' oldValue='${c.item2}' newValue='${c.item3}'");

    switch (paramName) {
      case 'bluetoothEnabled':
        _settingsBluetoothEnabled(oldValue, newValue);
        break;
      case 'bluetoothDeviceId':
        _settingsBluetoothDeviceId(oldValue, newValue);
        break;
    }
  }


  /// handle enable/disable BT in settings
  _settingsBluetoothEnabled(oldValue, newValue) {
    if (!settingsModel.isBluetoothDeviceIdValidMac()) return;
    if (newValue == true) {
      _startScan();
    } else if (newValue == false) {
      connector.disconnect(settingsModel.bluetoothDeviceId);
    }
  }


  /// if BT enabled, disconnect old device, connect to new device
  _settingsBluetoothDeviceId(oldValue, newValue) {
    if (oldValue == newValue) return; // ignore if old/new device IDs are the same
    if (settingsModel.bluetoothEnabled == false) return; // ignore change to device ID if BT is disabled
    if (MeshUtils.isValidBluetoothMac(oldValue) && _currentConnectionState == DeviceConnectionState.connected) connector.disconnect(oldValue);
    if (MeshUtils.isValidBluetoothMac(newValue)) _startScan();
  }


  ///
  _btScannerStateHandler(BleScannerState s) async {
    _bleScanIsInProgress = s.scanIsInProgress; // update state

    if (s.scanIsInProgress == false) {
      return; // this happens as a result of "stopScan". Store status, then ignore it
    }

    if (s.discoveredDevices.isEmpty) {
      return;
    }

    // check whether discovered device contains selected BT deviceId -> connect
    var i = s.discoveredDevices.iterator;
    while (i.moveNext()) {
      DiscoveredDevice d = i.current;
      if (d.id != settingsModel.bluetoothDeviceId) continue; // keep going until found

      print("BleConnectionLogic::_btScannerStateHandler - found the selected deviceId=${d.id} -> connect!");
      if (_bleScanIsInProgress) {
        await _stopScan(); // this triggers one last event where 'scanIsInProgress' is false
      }
      await connector.connect(d.id);
      break;  // stop the search early
    }
  }

  /// called whenever BLE status changes
  _btStatusMonitorHandler(BleStatus s) {
    print("BleConnectionLogic: BleStatusMonitor change " + s.toString());
    switch (s) {
      case BleStatus.unknown:
        break;
      case BleStatus.locationServicesDisabled:
        break;
      case BleStatus.poweredOff:
        break;
      case BleStatus.unauthorized:
        break;
      case BleStatus.unsupported:
        break;
      case BleStatus.ready:
        _startScan();
        break;
    }
  }

  /// called whenever connection state changes
  _btConnectionUpdateHandler(ConnectionStateUpdate s) async {
    print("BleConnectionLogic: BleDeviceConnector change ${s}");
    _currentConnectionState = s.connectionState;

    if (s.connectionState == DeviceConnectionState.connected) {
      await bleDataStreams.connectDataStreams(s.deviceId); // on new connection, initialize data streams
      await _sendWantConfig(s.deviceId);
    } else if (s.connectionState == DeviceConnectionState.disconnected) {
      await bleDataStreams.disconnectDataStreams(s.deviceId);
      _startScan(); // on disconnect, start scanning again...
    }
  }

  /// ask for config from node.
  _sendWantConfig(String deviceId) async {
    print("_sendWantConfig with deviceId=" + deviceId);

    int configId = DateTime.now().millisecondsSinceEpoch ~/ 1000; // unique number - sent back in config_complete_id (allow to discard old/stale)
    ToRadio pkt = MakeToRadio.wantConfig(configId);
    await bleDataStreams.writeAndReadResponseUntilEmpty(deviceId, pkt);

    // TODO: this doesn't work... might not be the right thing to do...
    print("radioConfigRequest with deviceId=" + deviceId);
    pkt = MakeToRadio.radioConfigRequest();
    await bleDataStreams.writeAndReadResponseUntilEmpty(deviceId, pkt);
  }
}
