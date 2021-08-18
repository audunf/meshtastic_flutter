import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/bluetooth/ble_device_connector.dart';
import 'package:meshtastic_flutter/bluetooth/ble_device_interactor.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pbserver.dart';
import 'package:meshtastic_flutter/constants.dart' as Constants;
import 'package:meshtastic_flutter/protocol/to_radio.dart';

import 'ble_status_monitor.dart';

class BleDataStreams {
  BleDeviceInteractor _deviceInteractor;
  BleStatusMonitor _bleStatusMonitor;
  BleDeviceConnector _bleDeviceConnector;

  StreamController<List<int>> _rawFromRadioStream = StreamController.broadcast(); // bytes from the radio
  StreamController<FromRadio> _fromRadioStream = StreamController.broadcast(); // FromRadio packets from the radio

  BleDataStreams({required BleStatusMonitor bleStatusMonitor, required BleDeviceConnector bleDeviceConnector, required BleDeviceInteractor deviceInteractor})
      : _deviceInteractor = deviceInteractor,
        _bleStatusMonitor = bleStatusMonitor,
        _bleDeviceConnector = bleDeviceConnector {
    // func body
    _bleStatusMonitor.state.listen(bleStatusHandler);
    _bleDeviceConnector.state.listen(connectionStateUpdate);
  }

  /// called whenever BLE status changes
  bleStatusHandler(BleStatus status) {
    print("bleStatusHandler status=" + status.toString());
  }

  /// called whenever connection state changes
  connectionStateUpdate(ConnectionStateUpdate u) {
    print("connectionStateUpdate=" + u.toString());
    if (u.connectionState == DeviceConnectionState.connected) { // on new connection, initialize data streams
      _initStreams(u.deviceId);
    }

    if (u.connectionState == DeviceConnectionState.disconnecting) {
      _closeStreams();
    }
  }

  /// initialize streams and ask for initial configuration. This happens whenever we've just connected to a device
  _initStreams(String deviceId) async {
    print("_initStreams with deviceId=" + deviceId);
    StreamTransformer<List<int>, FromRadio> radioTransformer = new StreamTransformer.fromHandlers(handleData: (List<int> data, EventSink<FromRadio> output) {
      FromRadio fr = FromRadio.fromBuffer(data);
      output.add(fr);
    });

    _rawFromRadioStream.stream.transform(radioTransformer).pipe(_fromRadioStream); // Hook up streams: Raw data stream -> FromRadio -> pipe -> fromRadioStream

    // TODO: Consider making this into a transformer with a separate output stream once the format is known/understood
    _deviceInteractor.subScribeToCharacteristic(getCharacteristic(deviceId, Constants.readNotifyWriteCharacteristicId)).listen((List<int> data) {
      print("GOT data on readNotifyWriteCharacteristicId " + data.toString()); // this prints: [1, 0, 0, 0]
      readResponseUntilEmpty(deviceId); // read until empty
    });

    // ask for config from node. Might be better places to put this later
    int configId = DateTime.now().millisecondsSinceEpoch ~/ 1000; // unique number - sent back in config_complete_id (allow to discard old/stale)
    print("readNodeDB with deviceId=" + deviceId);
    ToRadio pkt = MakeToRadio.wantConfig(configId);
    await writeAndReadResponseUntilEmpty(deviceId, pkt);

    print("radioConfigRequest with deviceId=" + deviceId);
    pkt = MakeToRadio.radioConfigRequest();
    await writeAndReadResponseUntilEmpty(deviceId, pkt);
  }

  /// write a ToRadio packet, and keep reading responses until empty
  writeAndReadResponseUntilEmpty(deviceId, ToRadio pkt) async {
    final writeC = getCharacteristic(deviceId, Constants.writeToRadioCharacteristicId);
    await _deviceInteractor.writeCharacteristicWithResponse(writeC, pkt.writeToBuffer());
    return await readResponseUntilEmpty(deviceId);
  }

  /// read data until device returns "empty"
  readResponseUntilEmpty(deviceId) async {
    final readC = getCharacteristic(deviceId, Constants.readFromRadioCharacteristicId);
    var isEmpty = false;
    while (!isEmpty) {
      List<int> buf = await _deviceInteractor.readCharacteristic(readC);
      isEmpty = buf.isEmpty;
      if (!isEmpty) _rawFromRadioStream.sink.add(buf);
    }

  }

  /// getter for raw stream of bytes
  Stream<List<int>> get rawFromRadioStream {
    return _rawFromRadioStream.stream;
  }

  /// getter for FromRadio object stream
  Stream<FromRadio> get fromRadioStream {
    return _fromRadioStream.stream;
  }

  getCharacteristic(deviceIdParam, characteristicIdParam) {
    return QualifiedCharacteristic(serviceId: Constants.meshtasticServiceId, characteristicId: characteristicIdParam, deviceId: deviceIdParam);
  }

  void _closeStreams() {
    print("_closeStreams");
    if (!_fromRadioStream.isClosed) _fromRadioStream.close();
    if (!_rawFromRadioStream.isClosed) _rawFromRadioStream.close();
  }

  void dispose() {
    _closeStreams();
  }
}
