import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/bluetooth/reactive_state.dart';

class BleStatusMonitor implements ReactiveState<BleStatus?> {
  final FlutterReactiveBle _ble;

  const BleStatusMonitor(this._ble);

  @override
  Stream<BleStatus> get state => _ble.statusStream;
}