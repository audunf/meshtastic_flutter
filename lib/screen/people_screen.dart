import 'package:flutter/material.dart';
import 'package:meshtastic_flutter/model/mesh_data_model.dart';
import 'package:meshtastic_flutter/model/tab_definition.dart';
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
          ),
          backgroundColor: tabDefinition.backgroundColor,
          body: Center(
              child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: meshDataModel
                      .getNodeInfoIterable()
                      .map((nodeInfo) => ListTile(
                        dense: true,
                        tileColor: Colors.white60,
                        leading: FlutterLogo(size: 72.0),
                        title: Text("Node num: ${nodeInfo.num}, SNR ${nodeInfo.snr}, last heard ${MeshUtils.epochSecondsToLongDateTimeString(nodeInfo.lastHeard)}"),
                    subtitle: Text("Position: ${MeshUtils.convertPositionToLatLng(nodeInfo.position).toString()}, MAC: ${nodeInfo.user.macaddr}"),
                    trailing: Icon(Icons.more_vert),
                    isThreeLine: true,
                  )).toList()))));
}
