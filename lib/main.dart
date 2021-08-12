import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'bluetooth/ble_data_streams.dart';
import 'bluetooth/ble_device_connector.dart';
import 'bluetooth/ble_device_interactor.dart';
import 'bluetooth/ble_scanner.dart';
import 'bluetooth/ble_status_monitor.dart';

import 'model/settings_model.dart';
import 'screen/channel_screen.dart';
import 'screen/chat_screen.dart';
import 'screen/map_screen.dart';
import 'screen/people_screen.dart';
import 'screen/settings_screen.dart';

const _themeColor = Colors.blue;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Map<Permission, PermissionStatus> statuses = await [
    Permission.bluetooth,
    Permission.location,
  ].request();
  print("Permission status: " + statuses[Permission.location].toString());

  final _logger = Logger(
    filter: null, // Use the default LogFilter (-> only log in debug mode)
    output: null, // Use the default LogOutput (-> send everything to console);
    printer: PrettyPrinter(
        methodCount: 0, // number of method calls to be displayed
        errorMethodCount: 8, // number of method calls if stacktrace is provided
        lineLength: 120, // width of the output
        colors: true, // Colorful log messages
        printEmojis: true, // Print an emoji for each log message
        printTime: false // Should each log print contain a timestamp
        ),
  );
  final _settings = SettingsModel();
  final _ble = FlutterReactiveBle();
  final _scanner = BleScanner(ble: _ble, logMessage: _logger.i);
  final _monitor = BleStatusMonitor(_ble);
  final _connector = BleDeviceConnector(
    ble: _ble,
    logMessage: _logger.i,
  );
  final _serviceDiscoverer = BleDeviceInteractor(
    bleDiscoverServices: _ble.discoverServices,
    readCharacteristic: _ble.readCharacteristic,
    writeWithResponse: _ble.writeCharacteristicWithResponse,
    writeWithOutResponse: _ble.writeCharacteristicWithoutResponse,
    subscribeToCharacteristic: _ble.subscribeToCharacteristic,
    logMessage: _logger.i,
  );
  final _bleDataStreams = BleDataStreams(deviceInteractor: _serviceDiscoverer, bleDeviceConnector: _connector, bleStatusMonitor: _monitor);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: _settings),
      Provider.value(value: _monitor),
      Provider.value(value: _connector),
      Provider.value(value: _serviceDiscoverer),
      Provider.value(value: _logger),
      Provider.value(value: _scanner),
      Provider.value(value: _bleDataStreams),
      StreamProvider<BleStatus>(
        create: (_) => _monitor.state,
        initialData: BleStatus.unknown,
      ),
      StreamProvider<BleScannerState>(
        create: (_) => _scanner.state,
        initialData: const BleScannerState(
          discoveredDevices: [],
          scanIsInProgress: false,
        ),
      ),
      StreamProvider<ConnectionStateUpdate>(
        create: (_) => _connector.state,
        initialData: const ConnectionStateUpdate(
          deviceId: 'Unknown device',
          connectionState: DeviceConnectionState.disconnected,
          failure: null,
        ),
      ),
      StreamProvider<FromRadio>(create: (_) => _bleDataStreams.fromRadioStream, initialData: FromRadio.getDefault()),
    ],
    child: MeshtasticApp(),
  ));
}


class MeshtasticApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meshtastic',
      color: _themeColor,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        accentColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      home: MeshtasticHomePage(title: 'Meshtastic'),
    );
  }
}


class MeshtasticHomePage extends StatefulWidget {
  MeshtasticHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MeshtasticHomePageState createState() => _MeshtasticHomePageState();
}


class _MeshtasticHomePageState extends State<MeshtasticHomePage> {
  int _currentTabIndex = 4;

  _MeshtasticHomePageState();

  static final TextStyle _optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  final List<Widget> _tabs = <Widget>[
    ChatScreen(),
    PeopleScreen(),
    MapScreen(),
    ChannelScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentTabIndex = index;
    });

    //bt.addListener(bluetoothListener);
    //bt.setupBluetooth();
  }

  /*
  bluetoothListener() {
    var inProgress = false;

    var state = bt.getState();
    print("bluetoothListener: $state");
    if (state == BleStatus.ready) {
      bt.scanForDevices((deviceId) async {
        if (inProgress == false) {
          bt.connect(deviceId);
          inProgress = true;
        }
      });
    }
  }
   */

  @override
  Widget build(BuildContext context) => Consumer<BleDeviceConnector>(
      builder: (ctx, bleDeviceConnector, __) => Scaffold(
            appBar: AppBar(title: Text(widget.title), actions: <Widget>[
              IconButton(
                icon: BluetoothConnectionIcon(),
                onPressed: () {
                  // go to the settings BT screen - if not already connected
                },
              )
            ]),
            body: Center(
              child: _tabs.elementAt(_currentTabIndex),
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat),
                  label: 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'People',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: 'Map',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.contactless_outlined),
                  label: 'Channel',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
              currentIndex: _currentTabIndex,
              selectedItemColor: Colors.amber[800],
              unselectedItemColor: Colors.grey[400],
              onTap: _onItemTapped,
            ),
          ));
}


class BluetoothConnectionIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Consumer3<BleStatus, BleScannerState, ConnectionStateUpdate>(
      builder: (_, status, scannerState, connectionState, __) => IconButton(
            icon: getIcon(status, scannerState, connectionState),
            onPressed: () {},
          ));

  Widget getIcon(BleStatus status, BleScannerState scannerState, ConnectionStateUpdate connectionState) {
    print("BluetoothConnectionIcon bleStatus=" +
        status.toString() +
        ", connectionState=" +
        connectionState.toString() +
        ", scannerState.scanInProgress=" +
        scannerState.scanIsInProgress.toString() +
        ", discoveredDevices=" +
        scannerState.discoveredDevices.toString());
    IconData icon = Icons.bluetooth_disabled;
    if (status != BleStatus.ready) {
      icon = Icons.bluetooth_disabled;
    }
    if (scannerState.scanIsInProgress) {
      icon = Icons.bluetooth_searching;
    }

    if (connectionState.connectionState == DeviceConnectionState.connected) {
      icon = Icons.bluetooth_connected_outlined;
    } else if (connectionState.connectionState == DeviceConnectionState.connected) {
      icon = Icons.bluetooth_connected;
    }

    return Icon(
      icon,
      color: Colors.white,
    );
  }
}
