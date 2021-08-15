import 'package:flutter/material.dart';
import 'package:meshtastic_flutter/bluetooth/ble_device_connector.dart';
import 'package:meshtastic_flutter/bluetooth/ble_device_interactor.dart';
import 'package:meshtastic_flutter/constants.dart' as Constants;
import 'package:meshtastic_flutter/model/settings_model.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';
import 'package:meshtastic_flutter/protocol/to_radio.dart';
import 'package:meshtastic_flutter/widget/tab_definition.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:meshtastic_flutter/bluetooth/ble_scanner.dart';

class SettingsScreen extends StatelessWidget {
  final TabDefinition tabDefinition;

  const SettingsScreen({Key? key, required this.tabDefinition}) : super(key: key);

  @override
  Widget build(BuildContext context) => Consumer2<SettingsModel, BleDeviceConnector>(
      builder: (ctx, settingsModel, bleConnector, __) => Scaffold(
          appBar: AppBar(
            title: Text(tabDefinition.title),
            backgroundColor: tabDefinition.color,
          ),
          backgroundColor: tabDefinition.color[50],
          body: SettingsList(
            sections: [
              SettingsSection(
                title: 'Bluetooth',
                tiles: [
                  SettingsTile.switchTile(
                    title: 'Disconnect',
                    leading: Icon(Icons.bluetooth),
                    switchValue: settingsModel.enableBluetooth,
                    onToggle: (bool value) {
                      settingsModel.setEnableBluetooth(value);
                      if (settingsModel.bluetoothDeviceId != "None") {
                        bleConnector.connect(settingsModel.bluetoothDeviceId);
                      }
                    },
                  ),
                  SettingsTile(
                    title: 'Device',
                    enabled: settingsModel.enableBluetooth,
                    subtitle: settingsModel.bluetoothDeviceName + ", " + settingsModel.bluetoothDeviceId,
                    leading: Icon(Icons.bluetooth),
                    onPressed: (BuildContext ctx) {
                      Navigator.pushNamed(context, "/bluetoothDevices");
                      /*
                      Navigator.of(ctx).push(MaterialPageRoute(
                        builder: (_) => BluetoothDeviceListScreen(tabDefinition: this.tabDefinition),
                      ));
                       */
                    },
                  ),
                ],
              ),
            ],
          )));
}

// Show status message - or devices
class BluetoothDeviceListScreen extends StatelessWidget {
  final TabDefinition tabDefinition;

  const BluetoothDeviceListScreen({Key? key, required this.tabDefinition}) : super(key: key);

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
    widget.startScan(<Uuid>[Constants.meshtasticServiceId]);
  }

  @override
  Widget build(BuildContext context) => Consumer2<SettingsModel, BleDeviceConnector>(
      builder: (ctx, settingsModel, bleDeviceConnector, __) => SettingsList(sections: [
            SettingsSection(
              title: 'Discovered devices',
              tiles: widget.scannerState.discoveredDevices
                  .map(
                    (device) => SettingsTile(
                      title: device.name + ", " + device.id,
                      trailing: trailingWidget(device.id, settingsModel.bluetoothDeviceId),
                      onPressed: (BuildContext context) async {
                        widget.stopScan();
                        settingsModel.setBluetoothDeviceId(device.id);
                        settingsModel.setBluetoothDeviceName(device.name);
                        bleDeviceConnector.connect(device.id);
                        Navigator.of(context).pop();
                      },
                    ),
                  )
                  .toList(),
            )
          ]));

  Widget trailingWidget(deviceId, selectedDeviceId) {
    return (deviceId == selectedDeviceId) ? Icon(Icons.check, color: Colors.blue) : Icon(null);
  }
}

class BleStatusWidget extends StatelessWidget {
  const BleStatusWidget({required this.status, Key? key}) : super(key: key);
  final BleStatus status;

  String determineText(BleStatus status) {
    switch (status) {
      case BleStatus.unsupported:
        return "This device does not support Bluetooth";
      case BleStatus.unauthorized:
        return "Authorize the app to use Bluetooth and location";
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
