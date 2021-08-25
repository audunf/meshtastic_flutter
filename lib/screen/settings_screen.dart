import 'package:flutter/material.dart';
import 'package:meshtastic_flutter/bluetooth/ble_device_connector.dart';
import 'package:meshtastic_flutter/constants.dart' as Constants;
import 'package:meshtastic_flutter/model/settings_model.dart';
import 'package:meshtastic_flutter/model/tab_definition.dart';
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
            backgroundColor: tabDefinition.appbarColor,
          ),
          backgroundColor: tabDefinition.backgroundColor,
          body: SettingsList(
            backgroundColor: tabDefinition.backgroundColor,
            sections: [
              SettingsSection(
                title: 'Bluetooth',
                tiles: [
                  SettingsTile.switchTile(
                    title: 'Enable bluetooth',
                    leading: Icon(Icons.bluetooth),
                    switchValue: settingsModel.bluetoothEnabled,
                    onToggle: (bool newValue) async {
                      settingsModel.setBluetoothEnabled(newValue);
                      if (newValue == true && settingsModel.bluetoothDeviceId == "Unknown") { // show available devices
                        Navigator.pushNamed(context, "/selectBluetoothDevice");
                      }
                    },
                  ),
                  SettingsTile(
                    title: 'Device',
                    enabled: settingsModel.bluetoothEnabled,
                    subtitle: settingsModel.bluetoothDeviceName + ", " + settingsModel.bluetoothDeviceId,
                    leading: Icon(Icons.bluetooth),
                    onPressed: (BuildContext ctx) {
                      Navigator.pushNamed(context, "/selectBluetoothDevice");
                    },
                  ),
                ],
              ),
              SettingsSection(title: 'User', tiles: [
                SettingsTile(
                  leading: Icon(Icons.person),
                  title: 'User name',
                  subtitle: settingsModel.userLongName,
                  enabled: settingsModel.bluetoothEnabled,
                  onPressed: (BuildContext ctx) {
                    Navigator.pushNamed(context, "/userName");
                  },
                ),
              ]),
              SettingsSection(title: 'Region', tiles: [
                SettingsTile(
                  leading: Icon(Icons.place),
                  title: 'Region',
                  subtitle: settingsModel.regionName,
                  enabled: settingsModel.bluetoothEnabled,
                  onPressed: (BuildContext ctx) {
                    Navigator.pushNamed(context, "/selectRegion");
                  },
                ),
              ])
            ],
          )));
}


/// Show status message - or devices
class SelectBluetoothDeviceScreen extends StatelessWidget {
  final TabDefinition tabDefinition;

  const SelectBluetoothDeviceScreen({Key? key, required this.tabDefinition}) : super(key: key);

  @override
  Widget build(BuildContext context) => Consumer2<BleScanner, BleScannerState>(
        builder: (_, bleScanner, bleScannerState, __) => _DeviceList(
          scannerState: bleScannerState,
          startScan: bleScanner.startScan,
          stopScan: bleScanner.stopScan,
        ),
      );
}


///
class _DeviceList extends StatefulWidget {
  final BleScannerState scannerState;
  final void Function(List<Uuid>, ScanMode) startScan;
  final Future<void> Function() stopScan;

  const _DeviceList({required this.scannerState, required this.startScan, required this.stopScan});

  @override
  _DeviceListState createState() => _DeviceListState();
}


///
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
    widget.startScan(<Uuid>[Constants.meshtasticServiceId], ScanMode.balanced);
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
                        await widget.stopScan();
                        settingsModel.setBluetoothDeviceName(device.name);
                        settingsModel.setBluetoothDeviceId(device.id);
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


///
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


///
class EditUserNameScreen extends StatelessWidget {
  final TabDefinition tabDefinition;
  const EditUserNameScreen({Key? key, required this.tabDefinition}) : super(key: key);

  @override
  Widget build(BuildContext context) => Consumer<SettingsModel>(
      builder: (ctx, settingsModel, __) => Scaffold(
          body: Center(
              child: TextFormField(
                  autofocus: true,
                  initialValue: settingsModel.userLongName,
                  onFieldSubmitted: (text) {
                    settingsModel.setUserLongName(text);
                    Navigator.of(context).pop();
                  }))));
}


///
class SelectRegionScreen extends StatelessWidget {
  final TabDefinition tabDefinition;
  const SelectRegionScreen({Key? key, required this.tabDefinition}) : super(key: key);

  @override
  Widget build(BuildContext context) => Consumer<SettingsModel>(
      builder: (ctx, settingsModel, __) => SettingsList(sections: [
            SettingsSection(
                title: 'Region',
                tiles: Constants.regionCodes.entries
                    .map((regionCode) => SettingsTile(
                        title: regionCode.value,
                        trailing: trailingWidget(regionCode.key, settingsModel.regionCode),
                        onPressed: (BuildContext context) async {
                          settingsModel.setRegionCode(regionCode.key);
                          Navigator.of(context).pop();
                        }))
                    .toList())
          ]));

  Widget trailingWidget(regionCode, selectedRegionCode) {
    return (regionCode == selectedRegionCode) ? Icon(Icons.check, color: Colors.blue) : Icon(null);
  }
}
