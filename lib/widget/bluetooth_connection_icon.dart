import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/bluetooth/ble_scanner.dart';
import 'package:provider/provider.dart';

class BluetoothConnectionIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Consumer3<BleStatus, BleScannerState, ConnectionStateUpdate>(
      builder: (_, status, scannerState, connectionState, __) => IconButton(
        icon: getIcon(status, scannerState, connectionState),
        onPressed: () {},
      ));

  Widget getIcon(BleStatus status, BleScannerState scannerState, ConnectionStateUpdate connectionState) {
    IconData icon = Icons.bluetooth_disabled;
    if (status != BleStatus.ready) {
      icon = Icons.bluetooth_disabled;
    }
    if (scannerState.scanIsInProgress) {
      icon = Icons.bluetooth_searching;
    }

    if (connectionState.connectionState == DeviceConnectionState.connected) {
      icon = Icons.bluetooth_connected_outlined;
    } else if (connectionState.connectionState == DeviceConnectionState.connected) {
      icon = Icons.bluetooth_connected;
    }

    return Icon(
      icon,
      color: Colors.white,
    );
  }
}