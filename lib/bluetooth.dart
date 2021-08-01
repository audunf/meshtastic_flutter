import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class Bluetooth extends ChangeNotifier {
  final ble =  FlutterReactiveBle();
  BleStatus bleStatus = BleStatus.unknown;

  Bluetooth() {
  }

  BleStatus getState() {
    return bleStatus;
  }

  setupBluetooth() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.location,
    ].request();
    print("Permission status: " + statuses[Permission.location].toString());

    ble.statusStream.listen((status) {
      print("BT Status: " + status.toString());
      bleStatus = status;
      notifyListeners();
    });
  }

  scanForDevices() async {
    var serviceIds = <Uuid>[Uuid.parse('6ba1b218-15a8-461f-9fa8-5dcae273eafd')]; // Meshtastic service ID

    ble.scanForDevices(withServices: serviceIds, scanMode: ScanMode.balanced).listen((devices) {
      print('scan result: ' + devices.toString());
    }, onError: (err) {
      print('error during scanForDevices ' + err.toString());
    });
  }

}