import 'package:flutter/material.dart';
import 'package:meshtastic_flutter/widget/tab_definition.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/bluetooth/ble_scanner.dart';

class ChannelScreen extends StatelessWidget {
  final TabDefinition tabDefinition;

  const ChannelScreen({Key? key, required this.tabDefinition}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tabDefinition.title),
        backgroundColor: tabDefinition.color,
      ),
      backgroundColor: tabDefinition.color[50],
      body: Center(
        child: Text('Channel screen xyz'),
      ),
    );
  }
}
