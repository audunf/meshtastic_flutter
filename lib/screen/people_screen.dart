import 'package:flutter/material.dart';
import 'package:meshtastic_flutter/model/mesh_data_model.dart';
import 'package:meshtastic_flutter/model/mesh_node.dart';
import 'package:meshtastic_flutter/model/tab_definition.dart';
import 'package:meshtastic_flutter/widget/bluetooth_connection_icon.dart';
import 'package:provider/provider.dart';
import 'package:meshtastic_flutter/mesh_utilities.dart' as MeshUtils;


class PeopleScreen extends StatelessWidget {
  final TabDefinition tabDefinition;

  const PeopleScreen({Key? key, required this.tabDefinition}) : super(key: key);

  @override
  Widget build(BuildContext context) => Consumer<MeshDataModel>(
      builder: (ctx, meshDataModel, __) => Scaffold(
          appBar: AppBar(
            title: Text(tabDefinition.title),
            backgroundColor: tabDefinition.appbarColor,
            actions: [BluetoothConnectionIcon()],
          ),
          backgroundColor: tabDefinition.backgroundColor,
          body: Center(
              child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: meshDataModel
                      .getMeshNodeIterable()
                      .map((MeshNode mn) => ListTile(
                        dense: true,
                        tileColor: Colors.black87,
                        leading: FlutterLogo(size: 72.0),
                        title: Text("Node num: ${mn.nodeNum}, SNR ${mn.snr}, last heard ${MeshUtils.epochSecondsToLongDateTimeString(mn.lastHeardEpochSec)}"),
                    subtitle: Text("Position: ${meshDataModel.getPosition(mn.nodeNum)?.getLatLng().toString()}"),
                    trailing: Icon(Icons.more_vert),
                    isThreeLine: true,
                  )).toList()))));
}
