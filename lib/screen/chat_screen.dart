import 'package:flutter/material.dart';
import 'package:meshtastic_flutter/model/tab_definition.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/bluetooth/ble_scanner.dart';


class ChatScreen extends StatelessWidget {
  final TabDefinition tabDefinition;

  const ChatScreen({ Key? key, required TabDefinition this.tabDefinition }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tabDefinition.title),
        backgroundColor: tabDefinition.color,
      ),
      backgroundColor: tabDefinition.color[50],
      body: Center(
        child:  Text('Chat screen xyz'),
      ),
    );
  }
}