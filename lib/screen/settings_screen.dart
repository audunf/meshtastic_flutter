import 'package:flutter/material.dart';
import 'package:meshtastic_flutter/constants.dart' as Constants;
import 'package:meshtastic_flutter/model/settings_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:meshtastic_flutter/bluetooth/ble_scanner.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var bluetoothDeviceId = Provider.of<SettingsModel>(context).bluetoothDeviceId;
    //BleScannerState status = Provider.of<BleScannerState>(context);
    var status = Provider.of<BleStatus>(context);
    print("xyzz " + status.toString());

    return Scaffold(
        body: SettingsList(
      sections: [
        SettingsSection(
          title: 'Bluetooth',
          tiles: [
            SettingsTile(
              title: 'Device',
              subtitle: bluetoothDeviceId,
              leading: Icon(Icons.bluetooth),
              onPressed: (BuildContext ctx) {
                //print("BLE STATUS: " + status.toString());
                Navigator.of(ctx).push(MaterialPageRoute(
                  builder: (_) => BluetoothDeviceScreen(),
                ));
              },
            ),
          ],
        ),
      ],
    ));
  }
}

// Show status message - or devices
class BluetoothDeviceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Consumer2<BleScanner, BleScannerState>(
    builder: (_, bleScanner, bleScannerState, __) => _DeviceList(
      scannerState: bleScannerState,
      startScan: bleScanner.startScan,
      stopScan: bleScanner.stopScan,
    ),
  );
}

class _DeviceList extends StatefulWidget {
  const _DeviceList({required this.scannerState, required this.startScan, required this.stopScan});

  final BleScannerState scannerState;
  final void Function(List<Uuid>) startScan;
  final VoidCallback stopScan;

  @override
  _DeviceListState createState() => _DeviceListState();
}

class _DeviceListState extends State<_DeviceList> {
  int _selectedDevice = 0;

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  @override
  void dispose() {
    widget.stopScan();
    super.dispose();
  }

  void _startScanning() {
    print("_startScanning");
    widget.startScan(<Uuid>[Constants.meshtasticServiceId]);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsList(sections: [
      SettingsSection(
        tiles: widget.scannerState.discoveredDevices
            .map(
              (device) => SettingsTile(
                title: device.name + device.id,
                trailing: trailingWidget(device.id),
                onPressed: (BuildContext context) async {
                  widget.stopScan();
                  selectDevice(device.id);
                },
              ),
            )
            .toList(),
      )
    ]);
  }

  selectDevice(deviceId) {
    _selectedDevice = deviceId;
  }

  Widget trailingWidget(deviceId) {
    return (deviceId == _selectedDevice) ? Icon(Icons.check, color: Colors.blue) : Icon(null);
  }
}

class BleStatusScreen extends StatelessWidget {
  const BleStatusScreen({required this.status, Key? key}) : super(key: key);
  final BleStatus status;

  String determineText(BleStatus status) {
    switch (status) {
      case BleStatus.unsupported:
        return "This device does not support Bluetooth";
      case BleStatus.unauthorized:
        return "Authorize the FlutterReactiveBle example app to use Bluetooth and location";
      case BleStatus.poweredOff:
        return "Bluetooth is off on your device - turn it on";
      case BleStatus.locationServicesDisabled:
        return "Enable location services";
      case BleStatus.ready:
        return "Bluetooth is up and running";
      default:
        return "Waiting to fetch Bluetooth status $status";
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Text(determineText(status)),
        ),
      );
}
