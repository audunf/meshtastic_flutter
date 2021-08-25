import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meshtastic_flutter/model/tab_definition.dart';
import 'package:meshtastic_flutter/widget/bluetooth_connection_icon.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:bubble/bubble.dart';
import 'package:bubble/issue_clipper.dart';
import 'package:meshtastic_flutter/bluetooth/ble_scanner.dart';

class ChatScreen extends StatelessWidget {
  final TabDefinition tabDefinition;

  static const styleSomebody = BubbleStyle(
    margin: const BubbleEdges.only(top: 5),
    elevation: 10,
    shadowColor: Colors.black54,
    borderColor: Colors.white70,
    alignment: Alignment.topLeft,
    borderWidth: 1,
    nip: BubbleNip.leftTop,
    color: Colors.blue,
    showNip: true,
  );

  static const styleMe = BubbleStyle(
    margin: const BubbleEdges.only(top: 5),
    elevation: 10,
    shadowColor: Colors.black54,
    borderColor: Colors.white70,
    alignment: Alignment.topRight,
    borderWidth: 1,
    nip: BubbleNip.rightBottom,
    color: Colors.green,
    showNip: true,
  );

  const ChatScreen({Key? key, required TabDefinition this.tabDefinition}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(tabDefinition.title),
          backgroundColor: tabDefinition.appbarColor,
          actions: [BluetoothConnectionIcon()],
        ),
        backgroundColor: tabDefinition.backgroundColor,
        body: Column(children: [
          Expanded(
              flex: 10,
              child: ListView(padding: const EdgeInsets.all(8), children: [
                Bubble(
                  alignment: Alignment.center,
                  color: Colors.deepPurple,
                  borderColor: Colors.black12,
                  borderWidth: 2,
                  margin: const BubbleEdges.only(top: 8),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
                Bubble(
                  style: styleSomebody,
                  child: const Text('Hi Jason. Sorry to bother you. I have a queston for you.', style: TextStyle(fontSize: 16)),
                ),
                Bubble(
                  style: styleMe,
                  child: const Text(
                    "Whats'up?",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Bubble(
                  style: styleSomebody,
                  child: const Text(
                    "I've been having a problem with my computer.",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ])),
          Padding(
              padding: EdgeInsets.all(8),
              child: Column(children: [
                Row(children: [
                  Expanded(
                      child: IntrinsicHeight(
                          child: TextFormField(
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(fontSize: 18),
                    maxLines: null, // If the maxLines property is null, there is no limit to the number of lines, and the wrap is enabled.
                    minLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter message',
                      labelStyle: TextStyle(fontSize: 18, color: Colors.black87),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: BorderSide(
                          color: Colors.white70,
                          width: 1.0,
                        ),
                      ),
                    ),
                    onFieldSubmitted: (String value) {},
                  ))),
                  Padding(
                      padding: EdgeInsets.fromLTRB(5, 0,0,0), // add some space to the text input box
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(children: <Widget>[
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: <Color>[
                                      Color(0xFF0D47A1),
                                      Color(0xFF1976D2),
                                      Color(0xFF42A5F5),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.all(16.0),
                                primary: Colors.white,
                                textStyle: const TextStyle(fontSize: 20),
                              ),
                              onPressed: () {},
                              child: const Text('Send'),
                            )
                          ])))
                ])
              ]))
        ]));
  }
}
