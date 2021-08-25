import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:meshtastic_flutter/model/mesh_data_model.dart';
import 'package:meshtastic_flutter/model/tab_definition.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:speech_bubble/speech_bubble.dart';
import 'package:geolocator/geolocator.dart';

import 'package:meshtastic_flutter/mesh_utilities.dart' as MeshUtils;


///
class CachedTileProvider extends TileProvider {
  const CachedTileProvider();
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return CachedNetworkImageProvider(
      getTileUrl(coords, options),
      //Now you can set options that determine how the image gets cached via whichever plugin you use.
    );
  }
}


///
class MapScreen extends StatefulWidget {
  final TabDefinition tabDefinition;

  const MapScreen({Key? key, required this.tabDefinition}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState(tabDefinition: tabDefinition);
}


///
class _MapScreenState extends State<MapScreen> {
  final TabDefinition tabDefinition;
  LatLng _handsetPosition = LatLng(59.927654, 10.698831);

  _MapScreenState({required this.tabDefinition}) : super();

  @override
  void initState() {
    _getHandsetPosition().then((LatLng pos) {
      print("handset position $pos");
      _handsetPosition = pos;
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Determine the current position of the device.
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<LatLng> _getHandsetPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue accessing the position and request users of the App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try requesting permissions again (this is also where Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines  your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position p = await Geolocator.getCurrentPosition();

    return LatLng(p.latitude, p.longitude);
  }


  Widget buildSpeechBubble(bubbleText) {
    return SpeechBubble(
      nipLocation: NipLocation.BOTTOM,
      //color: Colors.redAccent,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
            child: Text(
              bubbleText,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16.0,
              ),
            ),
          )
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) => Consumer<MeshDataModel>(
      builder: (ctx, meshDataModel, __) => Scaffold(
          appBar: AppBar(
            title: Text(tabDefinition.title),
            backgroundColor: tabDefinition.appbarColor,
          ),
          backgroundColor: tabDefinition.backgroundColor,
          body: Center(
              child: FlutterMap(
                  options: MapOptions(
                    interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate, // disable map rotation
                    center: _handsetPosition,
                    zoom: 13.0,
                    minZoom: 6,
                    maxZoom: 18,
                  ),
                  layers: [
                TileLayerOptions(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", subdomains: ['a', 'b', 'c'], tileProvider: const CachedTileProvider()),
                MarkerLayerOptions(
                    markers: meshDataModel
                        .getNodeInfoIterable()
                        .map((nodeInfo) => Marker(
                              width: 140, // TODO: how to make width and height dynamic (i.e., based on size of font, length of label)
                              height: 35,
                              point: MeshUtils.convertPositionToLatLng(nodeInfo.position),
                              //builder: (ctx) => Icon(Icons.location_on, color: Colors.red, size: 30),
                              builder: (ctx) => buildSpeechBubble(nodeInfo.user.longName),
                              anchorPos: AnchorPos.align(AnchorAlign.top),
                            ))
                        .toList())
              ]))));
}
