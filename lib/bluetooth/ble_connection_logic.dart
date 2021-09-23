import 'dart:async';
import 'dart:collection';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/model/mesh_data_model.dart';
import 'package:meshtastic_flutter/model/mesh_my_node_info.dart';
import 'package:meshtastic_flutter/model/mesh_data_packet_queue.dart';
import 'package:meshtastic_flutter/model/mesh_node.dart';
import 'package:meshtastic_flutter/model/mesh_position.dart';
import 'package:meshtastic_flutter/model/mesh_user.dart';
import 'package:meshtastic_flutter/model/settings_model.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';
import 'package:meshtastic_flutter/protocol/make_to_radio.dart';
import 'package:tuple/tuple.dart';

import 'ble_data_streams.dart';
import 'ble_device_connector.dart';
import 'ble_device_interactor.dart';
import 'ble_scanner.dart';
import 'ble_status_monitor.dart';
import 'package:meshtastic_flutter/constants.dart' as Constants;
import 'package:meshtastic_flutter/mesh_utilities.dart' as MeshUtils;

enum BleConnectionLogicMode {
  scanOnly, // only scan - no connections are allowed
  canConnect
}

class BleConnectionLogic {
  BleScanner scanner;
  BleStatusMonitor monitor;
  BleDeviceConnector connector;
  BleDeviceInteractor interactor;
  BleDataStreams bleDataStreams;
  SettingsModel settingsModel;
  MeshDataPacketQueue dataPacketQueue;
  MeshDataModel meshDataModel;

  BleStatus _currentBleStatus = BleStatus.unknown;
  DeviceConnectionState _currentConnectionState = DeviceConnectionState.disconnected;

  Timer? _periodicScan;
  BleConnectionLogicMode _bleConnectionLogicMode = BleConnectionLogicMode.canConnect;
  int _previousNodeConnectEpochMs = 0; //

  /// ctor
  BleConnectionLogic(
      {required this.settingsModel,
      required this.scanner,
      required this.monitor,
      required this.connector,
      required this.interactor,
      required this.bleDataStreams,
      required this.dataPacketQueue,
      required this.meshDataModel}) {
    settingsModel.changeStream.listen(_settingsModelHandler);
    scanner.state.listen(_btScannerStateHandler);
    monitor.state.listen(_btStatusMonitorHandler);
    connector.state.listen(_btConnectionUpdateHandler);
    bleDataStreams.fromRadioStream.listen(_fromRadioHandler);

    // periodic function which checks the command queue. If there are commands, then scan, which might lead to connect, which sends the packets
    Timer.periodic(Duration(seconds: 5
    ), (Timer t) {
      print("timer triggered state=$_bleConnectionLogicMode");
      _periodicScan = t;
      if (_bleConnectionLogicMode != BleConnectionLogicMode.canConnect) return; // bail out if not allowed to connect

      // try to connect whenever there are packets, if app never connected, or every once in a while regardless - to receive packets
      bool hasPackets = dataPacketQueue.hasUnAcknowledgedToRadioPackets();
      bool noPreviousConnect = _previousNodeConnectEpochMs == 0;
      bool dueForConnect = MeshUtils.isTimeNowAfterEpochMsPlusDuration(_previousNodeConnectEpochMs, const Duration(seconds: 60));
      print("hasPacket=$hasPackets, noPreviousConnect=$noPreviousConnect, dueForConnect=$dueForConnect");
      if (hasPackets || noPreviousConnect || dueForConnect) {
        _startScanForSelectedDeviceId();
        return;
      }
    });
  }

  ///
  void dispose() {
    _periodicScan?.cancel();
  }

  void setConnectionMode(BleConnectionLogicMode m) {
    _bleConnectionLogicMode = m;
    if (_bleConnectionLogicMode == BleConnectionLogicMode.scanOnly) {
      if (_currentConnectionState == DeviceConnectionState.connected || _currentConnectionState == DeviceConnectionState.connecting) {
        connector.disconnect(settingsModel.bluetoothDeviceId);
      }
    } else if (_bleConnectionLogicMode == BleConnectionLogicMode.canConnect) {}
  }

  /// scan for the device from settingsModel.bluetoothDeviceId
  _startScanForSelectedDeviceId() {
    print("BleConnectionLogic::_startScanForSelectedDeviceId");

    if (_currentBleStatus != BleStatus.ready) {
      print("BleConnectionLogic::_startScanForSelectedDeviceId - _currentBleStatus: $_currentBleStatus - can't scan");
      return;
    }
    if (settingsModel.bluetoothEnabled == false) {
      print("BleConnectionLogic::_startScanForSelectedDeviceId - bluetoothEnabled setting = false");
      return;
    }
    if (scanner.isScanInProgress()) {
      print("BleConnectionLogic::_startScanForSelectedDeviceId -> scan already in progress -> do nothing");
      return;
    }
    if (!MeshUtils.isValidBluetoothMac(settingsModel.bluetoothDeviceId)) {
      print("BleConnectionLogic::_startScanForSelectedDeviceId - bluetoothDeviceId not valid ${settingsModel.bluetoothDeviceId}");
      return;
    }

    print("BleConnectionLogic::_startScanForSelectedDeviceId -> starting scan");
    scanner.startScan(<Uuid>[Constants.meshtasticServiceId], ScanMode.lowPower);
  }

  ///
  _stopScan() async {
    if (!scanner.isScanInProgress()) {
      print("BleConnectionLogic::_stopScan -> no scan in progress -> return");
      return;
    }
    print("BleConnectionLogic::_stopScan!");
    await scanner.stopScan();
  }

  /// handle changes to different settings
  /// Called with tuple consisting of: Name of setting, oldValue, newValue
  _settingsModelHandler(Tuple3<String, dynamic, dynamic> c) async {
    var settingName = c.item1;
    var oldValue = c.item2;
    var newValue = c.item3;
    print("BleConnectionLogic settingsModel changed (stream!) -> setting name='$settingName' oldValue='$oldValue' newValue='$newValue'");

    switch (settingName) {
      case 'bluetoothEnabled':
        await _settingsBluetoothEnabled(oldValue, newValue);
        break;
      case 'bluetoothDeviceId':
        await _settingsBluetoothDeviceId(oldValue, newValue);
        break;
    }
  }

  /// handle enable/disable BT in settings
  _settingsBluetoothEnabled(oldValue, newValue) {
    if (!settingsModel.isBluetoothDeviceIdValidMac()) {
      return;
    }

    if (newValue == false) {
      _stopScan();
      if (_currentConnectionState == DeviceConnectionState.connected || _currentConnectionState == DeviceConnectionState.connecting) {
        connector.disconnect(settingsModel.bluetoothDeviceId);
      }
    }
  }

  /// if BT enabled, disconnect old device, connect to new device
  _settingsBluetoothDeviceId(String oldValue, String newBluetoothId) async {
    if (oldValue == newBluetoothId) return; // ignore if old/new device IDs are the same

    // On new BT deviceId, dump old data, and read any known data for new ID
    bool btIdChanged = await dataPacketQueue.setBluetoothIdFromString(newBluetoothId);
    if (btIdChanged) {
      // ID changed
      print("_settingsBluetoothDeviceId oldBtId=$oldValue newBluetoothId=$newBluetoothId -> triggering save, purge, load, and playback or radio commands");

      if (settingsModel.bluetoothEnabled == true && MeshUtils.isValidBluetoothMac(oldValue) && _currentConnectionState == DeviceConnectionState.connected) {
        await connector.disconnect(oldValue);
      }

      await meshDataModel.save();
      meshDataModel.clearModel();
      await meshDataModel.load(MeshUtils.convertBluetoothAddressToInt(newBluetoothId));

      _previousNodeConnectEpochMs = 0; // pretend no previous connection to the node - to trigger a sync
    }
  }

  ///
  _btScannerStateHandler(BleScannerState s) async {
    if (s.scanIsInProgress == false) {
      return; // this happens as a result of "stopScan". Ignore it
    }

    if (s.discoveredDevices.isEmpty) {
      return;
    }

    // state says we can't connect, then bail out
    if (_bleConnectionLogicMode != BleConnectionLogicMode.canConnect) return;

    // check whether discovered device contains selected BT deviceId -> connect
    var i = s.discoveredDevices.iterator;
    while (i.moveNext()) {
      DiscoveredDevice d = i.current;
      if (d.id != settingsModel.bluetoothDeviceId) continue; // keep going until found

      print("BleConnectionLogic::_btScannerStateHandler - found the selected deviceId=${d.id} -> connect!");
      if (scanner.isScanInProgress()) {
        await _stopScan(); // this triggers one last event where 'scanIsInProgress' is false
      }
      await connector.connect(d.id);
      break; // stop the search early
    }
  }

  /// called whenever BLE status changes
  _btStatusMonitorHandler(BleStatus s) {
    _currentBleStatus = s;
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
        break;
    }
  }

  /// called whenever connection state changes
  _btConnectionUpdateHandler(ConnectionStateUpdate s) async {
    _currentConnectionState = s.connectionState;

    print("BleConnectionLogic: BleDeviceConnector change $s");

    if (s.connectionState == DeviceConnectionState.connected) {
      /// CONNECTED
      _previousNodeConnectEpochMs = DateTime.now().millisecondsSinceEpoch; // set time of connection

      await bleDataStreams.connectDataStreams(s.deviceId); // on new connection, initialize data streams
      await _sendWantConfig(s.deviceId);
      await _sendToRadioCommandQueue(); // send all other pending commands

      Future.delayed(const Duration(milliseconds: 5000), () async {
        await connector.disconnect(s.deviceId); // disconnect after a delay
      });
    } else if (s.connectionState == DeviceConnectionState.disconnected) {
      /// DISCONNECTED
      dataPacketQueue.save(); // save command queues and whatever radio state on disconnect
    }
  }

  /// When attached to the radio, send all the ToRadio packets
  Future<void> _sendToRadioCommandQueue() async {
    Queue<MeshDataPacket> pLst = dataPacketQueue.getToRadioQueue(acknowledged: false); // all packets that haven't been sent yet
    print('_sendToRadioCommandQueue length: ${pLst.length}');
    for (var p in pLst) {
      ToRadio tr = p.payload as ToRadio;
      // normally, just write whatever packets
      try {
        await bleDataStreams.writeData(p.getBluetoothIdAsString(), tr);
      } catch (e) {
        print("_sendRadioCommandQueue error when sending BT: $e");
      } finally {
        // TODO: do something more sensible about the "ack". Preferably only mark as "acknowledged" once radio actually said so. Is that possible?
        p.acknowledged = true; // mark packet as sent
        p.dirty = true; // mark as needing save
        print('_sendToRadioCommandQueue -> DONE');
      }
    }
    dataPacketQueue.save();
  }

  /// ask for config from node.
  _sendWantConfig(String deviceId) async {
    print("_sendWantConfig with deviceId=" + deviceId);
    int configId = DateTime.now().millisecondsSinceEpoch ~/ 1000; // unique number - sent back in config_complete_id (allow to discard old/stale)
    ToRadio pkt = MakeToRadio.createWantConfig(configId);

    // wantConfig is special - we don't add the ToRadio packet to the command queue
    await bleDataStreams.writeAndReadResponseUntilEmpty(deviceId, pkt);
  }

  /// Handle incoming FromRadio packets
  _fromRadioHandler(FromRadio pkt) {
    switch (pkt.whichPayloadVariant()) {
      case FromRadio_PayloadVariant.packet:
        dataPacketQueue.addFromRadioBack(pkt);
        break;
      case FromRadio_PayloadVariant.nodeInfo:
        meshDataModel.updateMeshNode(MeshNode.fromProtoBuf(settingsModel.bluetoothDeviceIdInt, pkt.nodeInfo));
        meshDataModel.updateUser(MeshUser.fromProtoBuf(settingsModel.bluetoothDeviceIdInt, pkt.nodeInfo.user));
        meshDataModel.updatePosition(MeshPosition.fromProtoBuf(settingsModel.bluetoothDeviceIdInt, pkt.nodeInfo.num, pkt.nodeInfo.position));
        break;
      case FromRadio_PayloadVariant.myInfo:
        meshDataModel.setMyNodeInfo(MeshMyNodeInfo.fromProtoBuf(settingsModel.bluetoothDeviceIdInt, pkt.myInfo));
        break;
      case FromRadio_PayloadVariant.logRecord:
        break;
      case FromRadio_PayloadVariant.rebooted:
        break;
      case FromRadio_PayloadVariant.configCompleteId:
        break;
      case FromRadio_PayloadVariant.notSet:
        break;
    }
  }
}
