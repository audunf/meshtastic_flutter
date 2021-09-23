import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:meshtastic_flutter/model/mesh_data_packet_queue.dart';
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
  final _scrollController = ScrollController();
  int _textMessageQueueLength = 0;

  _ChatScreenState({required this.tabDefinition}) : super();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    int newLength = Provider.of<MeshDataPacketQueue>(context, listen: true).getTextMessageQueue().length;
    if (newLength > _textMessageQueueLength) {
      _textMessageQueueLength = newLength;
      scrollToEnd();
    }
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

  void scrollToEnd() {
    // wait some time, then scroll to end
    Timer(
        Duration(milliseconds: 200),
        () => _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 200),
              curve: Curves.fastOutSlowIn,
            ));
  }

  ///
  Widget getBubble(MeshDataPacket r) {
    BubbleStyle s = (r.direction == MeshDataPacketDirection.fromRadio ? styleSomebody : styleMe);
    String txt = "";
    CrossAxisAlignment align = CrossAxisAlignment.start;
    if (r.direction == MeshDataPacketDirection.fromRadio) {
      // others
      txt = AppFromRadioHandler.getTextMessageUtf8Payload(r.payload as FromRadio);
      align = CrossAxisAlignment.end;
    } else if (r.direction == MeshDataPacketDirection.toRadio) {
      // me
      txt = MakeToRadio.getTextMessageUtf8Payload(r.payload as ToRadio);
      align = CrossAxisAlignment.start;
    }

    return Bubble(
        style: s,
        child: Column(crossAxisAlignment: align, children: [
          Text(txt, style: TextStyle(fontSize: 16)),
          Text(timeago.format(r.getDateTime()), style: TextStyle(color: Colors.white70, fontSize: 10))
        ]));
  }

  @override
  Widget build(BuildContext context) => Consumer<MeshDataPacketQueue>(
      builder: (ctx, radioCommandQueue, __) => Scaffold(
          appBar: AppBar(
            title: Text(tabDefinition.title),
            backgroundColor: tabDefinition.appbarColor,
            actions: [BluetoothConnectionIcon()],
          ),
          backgroundColor: tabDefinition.backgroundColor,
          body: Column(children: [
            Expanded(
                flex: 10,
                child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    children: radioCommandQueue.getTextMessageQueue().map((e) {
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
                        labelStyle: TextStyle(fontSize: 18, color: Colors.grey),
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
                                  builder: (ctx, meshDataModel, __) => TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(16.0),
                                          primary: Colors.white,
                                          textStyle: const TextStyle(fontSize: 20),
                                        ),
                                        onPressed: () {
                                          var text = _chatEditCtrl.text.trim();
                                          if (text.length <= 0) return;
                                          print("SEND pressed. Data='$text'");
                                          radioCommandQueue.addToRadioBack(MakeToRadio.createTextMessageApp(meshDataModel.myNodeInfo.nodeNum, text));
                                          _chatEditCtrl.clear();
                                          scrollToEnd(); // scroll to the last message in the list
                                        },
                                        child: const Text('Send'),
                                      ))
                            ])))
                  ])
                ]))
          ])));
}
