import 'package:flutter/material.dart';
import 'package:meshtastic_flutter/bluetooth/ble_device_connector.dart';
import 'package:meshtastic_flutter/constants.dart' as Constants;
import 'package:meshtastic_flutter/model/mesh_data_model.dart';
import 'package:meshtastic_flutter/model/mesh_user.dart';
import 'package:meshtastic_flutter/model/settings_model.dart';
import 'package:meshtastic_flutter/model/tab_definition.dart';
import 'package:meshtastic_flutter/widget/bluetooth_connection_icon.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:meshtastic_flutter/bluetooth/ble_scanner.dart';

class SettingsScreen extends StatelessWidget {
  final TabDefinition tabDefinition;

  const SettingsScreen({Key? key, required this.tabDefinition}) : super(key: key);

  @override
  Widget build(BuildContext context) => Consumer3<SettingsModel, MeshDataModel, BleDeviceConnector>(
      builder: (ctx, settingsModel, meshDataModel, bleConnector, __) => Scaffold(
          appBar: AppBar(
            title: Text(tabDefinition.title),
            backgroundColor: tabDefinition.appbarColor,
            actions: [BluetoothConnectionIcon()],
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
                      if (newValue == true && settingsModel.bluetoothDeviceId == "Unknown") {
                        // show available devices
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
                  subtitle: meshDataModel.getMyUser()?.longName ?? "Unknown",
                  enabled: settingsModel.bluetoothEnabled,
                  onPressed: (BuildContext ctx) {
                    Navigator.pushNamed(context, "/userName");
                  },
                ),
              ]),
              /*
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
              ])*/
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
          bleScanner: bleScanner
        ),
      );
}

///
class _DeviceList extends StatefulWidget {
  final BleScannerState scannerState;
  final BleScanner bleScanner;

  const _DeviceList({required this.scannerState, required this.bleScanner});

  @override
  _DeviceListState createState() => _DeviceListState();
}

///
class _DeviceListState extends State<_DeviceList> {
  @override
  void initState() {
    super.initState();
    widget.bleScanner.startScan(<Uuid>[Constants.meshtasticServiceId], ScanMode.balanced);
  }

  @override
  void dispose() {
    // Don't call widget.stopScan(); here - because it will terminate the legitimate scanning for the selected device
    // and if no ID is selected, it won't scan anyway
    super.dispose();
  }

  Widget trailingWidget(deviceId, selectedDeviceId) {
    return (deviceId == selectedDeviceId) ? Icon(Icons.check, color: Colors.blue) : Icon(null);
  }

  /// list of tiles - one for each BLE device located during scan
  List<SettingsTile> getTileList(BleScannerState bleScannerState, SettingsModel settingsModel) {
    print("******** YOHOO: repainting. Found more devices: ${bleScannerState.discoveredDevices.toString()}");
    return bleScannerState.discoveredDevices
        .map(
          (device) => SettingsTile(
            title: device.name + ", " + device.id,
            trailing: trailingWidget(device.id, settingsModel.bluetoothDeviceId),
            onPressed: (BuildContext context) async {
              await widget.bleScanner.stopScan();
              settingsModel.setBluetoothDeviceName(device.name);
              settingsModel.setBluetoothDeviceId(device.id);
              Navigator.of(context).pop();
            },
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) => Consumer2<SettingsModel, BleScannerState>(
      builder: (ctx, settingsModel, bleScannerState, __) => SettingsList(sections: [
            SettingsSection(
              title: 'Discovered devices',
              tiles: getTileList(bleScannerState, settingsModel),
            )
          ]));
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
  Widget build(BuildContext context) => Consumer<MeshDataModel>(
      builder: (ctx, meshDataModel, __) => Scaffold(
          body: Center(
              child: TextFormField(
                  autofocus: true,
                  initialValue: meshDataModel.getMyUser()?.longName ?? "Unknown",
                  onFieldSubmitted: (text) {
                    MeshUser? u = meshDataModel.getMyUser();
                    if (u != null) {
                      u.longName = text;
                      meshDataModel.updateUser(u);
                    }
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
                        trailing: trailingWidget(regionCode.key, 0), //settingsModel.regionCode),
                        onPressed: (BuildContext context) async {
                          //settingsModel.setRegionCode(regionCode.key); - no longer exists
                          Navigator.of(context).pop();
                        }))
                    .toList())
          ]));

  Widget trailingWidget(regionCode, selectedRegionCode) {
    return (regionCode == selectedRegionCode) ? Icon(Icons.check, color: Colors.blue) : Icon(null);
  }
}
