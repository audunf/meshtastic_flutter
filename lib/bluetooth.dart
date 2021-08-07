import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/from_radio_parser.dart';
import 'package:meshtastic_flutter/to_radio.dart';
import 'package:meshtastic_flutter/proto-autogen/admin.pb.dart';
import 'package:meshtastic_flutter/proto-autogen/portnums.pb.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';
import 'package:protobuf/protobuf.dart';



class Bluetooth extends ChangeNotifier {
  final ble =  FlutterReactiveBle();
  BleStatus _bleStatus = BleStatus.unknown;
  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;
  final _parser = new FromRadioParser();

  // Meshtastic service ID. See: https://meshtastic.org/docs/developers/device/device-api
  final _serviceId = Uuid.parse('6ba1b218-15a8-461f-9fa8-5dcae273eafd');
  final _readFromRadioCharacteristicId = Uuid.parse('8ba2bcc2-ee02-4a55-a531-c525c5e454d5'); // read fromradio
  final _writeToRadioCharacteristicId = Uuid.parse('f75c76d2-129e-4dad-a1dd-7866124401e7'); //write toradio
  final _readNotifyWriteCharacteristicId = Uuid.parse('ed9da18c-a800-4f66-a670-aa7547e34453'); // read,notify,write fromnum

  Bluetooth();

  BleStatus getState() {
    return _bleStatus;
  }

  getCharacteristic(deviceIdParam, characteristicIdParam) {
    return QualifiedCharacteristic(serviceId: _serviceId, characteristicId: characteristicIdParam, deviceId: deviceIdParam);
  }

  setupBluetooth() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.location,
    ].request();

    print("Permission status: " + statuses[Permission.location].toString());

    ble.statusStream.listen((status) {
      if (status == _bleStatus) return;
      print("BT Status: " + status.toString());
      _bleStatus = status;
      notifyListeners();
    });
  }

  List <Uuid> getServiceCharacteristicsList() { // Meshtastic service characteristics. See: https://meshtastic.org/docs/developers/device/device-api
    return <Uuid>[_readFromRadioCharacteristicId, _writeToRadioCharacteristicId, _readNotifyWriteCharacteristicId];
  }

  scanForDevices(callback) async {
    ble.scanForDevices(withServices: <Uuid>[_serviceId], scanMode: ScanMode.balanced).listen((devices) async {
      //print('scan result: ' + devices.toString());
      callback(devices.id);
    }, onError: (error) {
      print('error during scanForDevices ' + error.toString());
    });
  }

  connect(deviceId) async {
    print("try to connect with ID=" + deviceId);
    ble.connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds:  5),
    ).listen((connState) async {
      if (connState.connectionState == _connectionState) return;
      print("connection state " + connState.toString());
      if (connState.connectionState == DeviceConnectionState.connected && _connectionState == DeviceConnectionState.connecting) {
        // wasn't connected - is connected now
        print("connected " + connState.toString());
        await setMTU(deviceId);
        readNodeDB(connState.deviceId);

        ble.subscribeToCharacteristic(getCharacteristic(deviceId, _readNotifyWriteCharacteristicId)).listen((data) {
          print("*** READ/NOTIFY/WRITE got data: " + data.toString());
        }, onError: (dynamic error) {
          print("*** READ/NOTIFY/WRITE ERROR: " + error.toString());
        });
      }
      _connectionState = connState.connectionState;
    }, onError: (dynamic error) {
      print('error during connect: ' + error.toString());
    });
  }

  setMTU(foundDeviceId) async {
    print("setMTU");
    final mtu = await ble.requestMtu(deviceId: foundDeviceId, mtu: 500);
  }

  readNodeDB(foundDeviceId) async {
    int configId = DateTime.now().millisecondsSinceEpoch ~/ 1000; // unique number - sent back in config_complete_id (allow to discard old/stale)
    print("readNodeDB with ID=" + foundDeviceId);

    ToRadio pkt = MakeToRadio.wantConfig(configId);
    final wc = getCharacteristic(foundDeviceId, _writeToRadioCharacteristicId);
    await ble.writeCharacteristicWithResponse(wc, value: pkt.writeToBuffer())
        .onError((error, stackTrace) {
          print("error during writeCharacteristicWithResponse: " + error.toString());
        });

    final rc = getCharacteristic(foundDeviceId, _readFromRadioCharacteristicId);
    do {
      var buf = await ble.readCharacteristic(rc); 
      if (buf.isEmpty) {
        print("end of data");
        break;
      }
      _parser.handleFromRadio(buf);
    } while(true);

  }

}