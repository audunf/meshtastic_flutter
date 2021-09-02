import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meshtastic_flutter/model/radio_cmd_queue.dart';
import 'package:meshtastic_flutter/model/mesh_data_model.dart';
import 'package:meshtastic_flutter/model/tab_definition.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';
import 'package:meshtastic_flutter/protocol/app_from_radio_handler.dart';
import 'package:meshtastic_flutter/protocol/make_to_radio.dart';
import 'package:meshtastic_flutter/widget/bluetooth_connection_icon.dart';
import 'package:bubble/bubble.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final TabDefinition tabDefinition;

  const ChatScreen({Key? key, required this.tabDefinition}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState(tabDefinition: tabDefinition);
}

class _ChatScreenState extends State<ChatScreen> {
  final TabDefinition tabDefinition;
  TextEditingController _chatEditCtrl = TextEditingController();

  _ChatScreenState({required this.tabDefinition}) : super();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

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


  ///
  Widget getBubble(RadioCommand r) {
    BubbleStyle s = (r.direction == RadioCommandDirection.fromRadio ? styleSomebody : styleMe);
    String txt = "";
    if (r.direction == RadioCommandDirection.fromRadio) {
      txt = AppFromRadioHandler.getTextMessageUtf8Payload(r.payload as FromRadio);
    } else if (r.direction == RadioCommandDirection.toRadio) {
      txt = MakeToRadio.getTextMessageUtf8Payload(r.payload as ToRadio);
    }
    return Bubble(
        style: s,
        child: Text(txt, style: TextStyle(fontSize: 16))
    );
  }

  @override
  Widget build(BuildContext context) =>
      Consumer<RadioCommandQueue>(builder: (ctx, radioCommandQueue, __) =>
          Scaffold(
              appBar: AppBar(
                title: Text(tabDefinition.title),
                backgroundColor: tabDefinition.appbarColor,
                actions: [BluetoothConnectionIcon()],
              ),
              backgroundColor: tabDefinition.backgroundColor,
              body: Column(children: [
                Expanded(
                    flex: 10,
                    child: ListView(padding: const EdgeInsets.all(8), children: radioCommandQueue.getTextMessageQueue().map((e) {
                      return getBubble(e);
                    }).toList())),
                Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                            child: IntrinsicHeight(
                                child: TextFormField(
                                  controller: _chatEditCtrl,
                                  keyboardType: TextInputType.multiline,
                                  style: TextStyle(fontSize: 18),
                                  maxLines: null,
                                  // If the maxLines property is null, there is no limit to the number of lines, and the wrap is enabled.
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
                            padding: EdgeInsets.fromLTRB(5, 0, 0, 0), // add some space to the text input box
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
                                  Consumer<MeshDataModel>(
                                      builder: (ctx, meshDataModel, __) =>
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.all(16.0),
                                              primary: Colors.white,
                                              textStyle: const TextStyle(fontSize: 20),
                                            ),
                                            onPressed: () {
                                              print("SEND pressed. Data='${_chatEditCtrl.text.trim()}'");
                                              radioCommandQueue.addToRadioBack(
                                                  MakeToRadio.createTextMessageApp(meshDataModel.myNodeInfo.myNodeNum, _chatEditCtrl.text.trim()));
                                              _chatEditCtrl.clear();
                                            },
                                            child: const Text('Send'),
                                          ))
                                ])))
                      ])
                    ]))
              ])));
}