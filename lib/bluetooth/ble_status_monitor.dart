import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/bluetooth/reactive_state.dart';

class BleStatusMonitor implements ReactiveState<BleStatus?> {
  final FlutterReactiveBle _ble;
  StreamController<BleStatus> _ctrl = new StreamController.broadcast();

  BleStatusMonitor(this._ble) {
    // make a broadcast stream out of something in the library, which isn't a broadcast stream
    _ble.statusStream.listen((status) {
      _ctrl.sink.add(status);
    });
  }

  dispose() {
    _ctrl.close();
  }

  @override
  Stream<BleStatus> get state => _ctrl.stream;
}