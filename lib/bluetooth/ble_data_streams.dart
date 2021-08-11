import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/bluetooth/ble_device_connector.dart';
import 'package:meshtastic_flutter/bluetooth/ble_device_interactor.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pbserver.dart';
import 'package:meshtastic_flutter/constants.dart' as Constants;
import 'package:meshtastic_flutter/protocol/from_radio_parser.dart';
import 'package:meshtastic_flutter/protocol/to_radio.dart';

import 'ble_status_monitor.dart';

class BleDataStreams {
  BleDeviceInteractor _deviceInteractor;
  BleStatusMonitor _bleStatusMonitor;
  BleDeviceConnector _bleDeviceConnector;

  StreamController<List<int>> _rawFromRadioStream = StreamController.broadcast();
  StreamController<FromRadio> _fromRadioStream = StreamController.broadcast();

  BleDataStreams({required BleStatusMonitor bleStatusMonitor, required BleDeviceConnector bleDeviceConnector, required BleDeviceInteractor deviceInteractor})
      : _deviceInteractor = deviceInteractor,
        _bleStatusMonitor = bleStatusMonitor,
        _bleDeviceConnector = bleDeviceConnector {
    // func body
    _bleStatusMonitor.state.listen(bleStatusHandler);
    _bleDeviceConnector.state.listen(connectionStateUpdate);
  }

  bleStatusHandler(BleStatus status) {
    print("bleStatusHandler status=" + status.toString());
    if (status != BleStatus.ready) {}
  }

  connectionStateUpdate(ConnectionStateUpdate u) {
    print("connectionStateUpdate=" + u.toString());
    if (u.connectionState == DeviceConnectionState.connected) {
      _initStreams(u.deviceId);
    }
  }

  _initStreams(String deviceId) async {
    print("_initStreams with deviceId=" + deviceId);
    StreamTransformer<List<int>, FromRadio> radioTransformer = new StreamTransformer.fromHandlers(handleData: (List<int> data, EventSink<FromRadio> output) {
      FromRadio fr = FromRadio.fromBuffer(data);
      output.add(fr);
    });

    _rawFromRadioStream.stream.transform(radioTransformer).pipe(_fromRadioStream); // Hook up streams: Raw data stream -> FromRadio -> pipe -> fromRadioStream

    // TODO move this bit - but where?
    // what kind of pattern can be used here? writeWithResponse -> onError -> read until empty
    //  very temporary hack just to see if data can be obtained
    int configId = DateTime.now().millisecondsSinceEpoch ~/ 1000; // unique number - sent back in config_complete_id (allow to discard old/stale)
    print("readNodeDB with ID=" + deviceId);
    ToRadio pkt = MakeToRadio.wantConfig(configId);
    writeAndReadResponse(deviceId, pkt);
  }

  writeAndReadResponse(deviceId, ToRadio pkt) async {
    final readC = getCharacteristic(deviceId, Constants.readFromRadioCharacteristicId);
    final writeC = getCharacteristic(deviceId, Constants.writeToRadioCharacteristicId);
    await _deviceInteractor.writeCharacteristicWithResponse(writeC, pkt.writeToBuffer());
    var isEmpty = false;
    while (!isEmpty) {
      List<int> buf = await _deviceInteractor.readCharacteristic(readC);
      isEmpty = buf.isEmpty;
      if (!isEmpty) _rawFromRadioStream.sink.add(buf);
    }
  }

  Stream<List<int>> get rawFromRadioStream {
    return _rawFromRadioStream.stream;
  }

  Stream<FromRadio> get fromRadioStream {
    return _fromRadioStream.stream;
  }

  getCharacteristic(deviceIdParam, characteristicIdParam) {
    return QualifiedCharacteristic(serviceId: Constants.meshtasticServiceId, characteristicId: characteristicIdParam, deviceId: deviceIdParam);
  }

  void dispose() {
    _fromRadioStream.close();
    _rawFromRadioStream.close();
  }
}
