import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/bluetooth/ble_scanner.dart';


class ChatScreen extends StatelessWidget {
  ChatScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:  Text('Chat screen'),
      ),
    );
  }
}