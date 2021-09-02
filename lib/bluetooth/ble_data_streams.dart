import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/bluetooth/ble_device_connector.dart';
import 'package:meshtastic_flutter/bluetooth/ble_device_interactor.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pbserver.dart';
import 'package:meshtastic_flutter/constants.dart' as Constants;

import 'ble_status_monitor.dart';

class BleDataStreams {
  BleDeviceInteractor _deviceInteractor;
  BleStatusMonitor _bleStatusMonitor;
  BleDeviceConnector _bleDeviceConnector;

  Stream<List<int>>? _readNotifyWriteStream; // stream which notifies when there are packets to read (without first having written)
  StreamSubscription<List<int>>? _readNotifyWriteSubscription;
  
  StreamController<List<int>> _rawFromRadioStreamController = StreamController.broadcast(); // bytes from the radio
  StreamController<FromRadio> _fromRadioStreamController = StreamController.broadcast(); // FromRadio packets from the radio

  DeviceConnectionState _deviceConnectionState = DeviceConnectionState.disconnected;


  BleDataStreams({required BleStatusMonitor bleStatusMonitor, required BleDeviceConnector bleDeviceConnector, required BleDeviceInteractor deviceInteractor})
      : _deviceInteractor = deviceInteractor,
        _bleStatusMonitor = bleStatusMonitor,
        _bleDeviceConnector = bleDeviceConnector {
    // func body
    _bleStatusMonitor.state.listen(_bleStatusHandler);
    _bleDeviceConnector.state.listen(_connectionStateUpdateHandler);

    StreamTransformer<List<int>, FromRadio> radioTransformer = StreamTransformer.fromHandlers(handleData: (List<int> data, EventSink<FromRadio> output) async {
      try {
        FromRadio fr = FromRadio.fromBuffer(data);
        if (!_fromRadioStreamController.isClosed) {
          output.add(fr); // only add to stream if it's still open
        }
      } catch(e) {
        print("BleDataStreams - discarding malformed FromRadio data: $data");
      }
    });
    _rawFromRadioStreamController.stream.transform(radioTransformer).pipe(_fromRadioStreamController); // Hook up streams: Raw data stream -> FromRadio -> pipe -> fromRadioStream
  }

  /// called whenever BLE status changes
  _bleStatusHandler(BleStatus status) {
    //print("BleDataStreams::bleStatusHandler status=" + status.toString());
  }

  /// called whenever connection state changes
  _connectionStateUpdateHandler(ConnectionStateUpdate u) async {
    //print("BleDataStreams::_connectionStateUpdate = " + u.toString());
    _deviceConnectionState = u.connectionState;
  }

  /// This happens whenever we've just connected to a device
  connectDataStreams(String deviceId) async {
    print("connectDataStreams with deviceId = " + deviceId);

    if (_deviceConnectionState != DeviceConnectionState.connected) {
      print("connectDataStreams - _deviceConnectionState is not CONNECTED - early return");
      return; 
    }

    try {
      await _readNotifyWriteSubscription?.cancel();
      print("connectDataStreams - setup new subscriptions and listen");
      _readNotifyWriteStream =
          _deviceInteractor.subscribeToCharacteristic(getCharacteristic(deviceId, Constants.readNotifyWriteCharacteristicId)).asBroadcastStream();
    } catch (e, s) {
      print("Ignoring exception while cancelling _readNotifyWriteSubscription or calling subscribeToCharacteristic: $e");
    }
    
    _readNotifyWriteSubscription = _readNotifyWriteStream?.listen((List<int> data) {
      Function.apply(_onReadNotifyWriteHandler, [deviceId, data]);
    }, onError: (err, stack) async {
      // TODO: Exception always occurs when: 1) node disconnects, 2) phone reconnects. If phone disconnects first - there's no exception.
      print("_readNotifyWriteSubscription - error " + err.toString());
      await _readNotifyWriteSubscription?.cancel();
    }, onDone: () {
      print("_readNotifyWriteSubscription - DONE");
    }, cancelOnError: true);
  }

  /// Teardown - whenever disconnected from a device
  disconnectDataStreams(String deviceId) async {
    print("connectDataStreams with deviceId = " + deviceId);
    await _readNotifyWriteSubscription?.cancel();
    _readNotifyWriteSubscription = null;
  }

  /// when device signals data is available (app has explicitly subscribed)
  _onReadNotifyWriteHandler(deviceId, List<int> data) {
    print("GOT data on readNotifyWriteCharacteristicId " + data.toString()); // this prints: [1, 0, 0, 0], sometimes [2, 0, 0, 0]
    return readResponseUntilEmpty(deviceId); // read until empty
  }

  /// write a ToRadio packet, and keep reading responses until empty
  writeAndReadResponseUntilEmpty(String deviceId, ToRadio pkt) async {
    final writeC = getCharacteristic(deviceId, Constants.writeToRadioCharacteristicId);
    if (_deviceConnectionState != DeviceConnectionState.connected) {
      print("writeAndReadResponseUntilEmpty - _deviceConnectionState is not CONNECTED - early return");
      return;
    }
    await _deviceInteractor.writeCharacteristicWithResponse(writeC, pkt.writeToBuffer());
    return await readResponseUntilEmpty(deviceId);
  }

  /// write a ToRadio packet
  writeData(String deviceId, ToRadio pkt) async {
    final writeC = getCharacteristic(deviceId, Constants.writeToRadioCharacteristicId);
    if (_deviceConnectionState != DeviceConnectionState.connected) {
      print("writeData - _deviceConnectionState is not CONNECTED - early return");
      return;
    }
    return await _deviceInteractor.writeCharacteristicWithResponse(writeC, pkt.writeToBuffer());
  }

  /// read data until device returns "empty"
  readResponseUntilEmpty(String deviceId) async {
    final readC = getCharacteristic(deviceId, Constants.readFromRadioCharacteristicId);
    var isEmpty = false;
    while (!isEmpty) {
      if (_deviceConnectionState != DeviceConnectionState.connected) {
        print("readResponseUntilEmpty - _deviceConnectionState is not CONNECTED - early return");
        break;
      }
      List<int> buf = await _deviceInteractor.readCharacteristic(readC);
      isEmpty = buf.isEmpty;
      if (!isEmpty && !_rawFromRadioStreamController.isClosed) {
        _rawFromRadioStreamController.sink.add(buf);
      }
    }
  }

  /// inject a
  addRawPacketToFromRadioSink(FromRadio p) {
    if (!_rawFromRadioStreamController.isClosed) {
      _rawFromRadioStreamController.sink.add(p.writeToBuffer());
    }
  }

  /// getter for raw stream of bytes
  Stream<List<int>> get rawFromRadioStream {
    return _rawFromRadioStreamController.stream;
  }

  /// getter for FromRadio object stream
  Stream<FromRadio> get fromRadioStream {
    return _fromRadioStreamController.stream;
  }

  getCharacteristic(String deviceIdParam, Uuid characteristicIdParam) {
    return QualifiedCharacteristic(serviceId: Constants.meshtasticServiceId, characteristicId: characteristicIdParam, deviceId: deviceIdParam);
  }

  _closeStreams() async {
    print("_closeStreams");
    if (!_fromRadioStreamController.isClosed) await _fromRadioStreamController.close();
    if (!_rawFromRadioStreamController.isClosed) await _rawFromRadioStreamController.close();
  }

  dispose() async {
    await _closeStreams();
  }
}
