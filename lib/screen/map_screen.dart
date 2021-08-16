import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:meshtastic_flutter/widget/tab_definition.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/bluetooth/ble_scanner.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  final TabDefinition tabDefinition;

  const MapScreen({Key? key, required this.tabDefinition}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(tabDefinition.title),
          backgroundColor: tabDefinition.color,
        ),
        backgroundColor: tabDefinition.color[50],
        body: Center(
            child: FlutterMap(
          options: MapOptions(
            center: LatLng(59.92765487894794, 10.698831048917087),
            zoom: 13.0,
          ),
          layers: [
            TileLayerOptions(urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", subdomains: ['a', 'b', 'c']),
            MarkerLayerOptions(
              markers: [
                Marker(
                  width: 20.0,
                  height: 20.0,
                  point: LatLng(59.92765487894794, 10.698831048917087),
                  builder: (ctx) => Container(
                    child: FlutterLogo(),
                  ),
                ),
              ],
            ),
          ],
        )));
  }
}
