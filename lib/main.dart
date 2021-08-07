import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meshtastic_flutter/bluetooth.dart';

import 'bluetooth/ble_device_connector.dart';
import 'bluetooth/ble_device_interactor.dart';
import 'bluetooth/ble_scanner.dart';
import 'bluetooth/ble_status_monitor.dart';

const _themeColor = Colors.blue;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final _logger = Logger();

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

  runApp(MultiProvider(
    providers: [
      Provider.value(value: _scanner),
      Provider.value(value: _monitor),
      Provider.value(value: _connector),
      Provider.value(value: _serviceDiscoverer),
      Provider.value(value: _logger),
      StreamProvider<BleScannerState?>(
        create: (_) => _scanner.state,
        initialData: const BleScannerState(
          discoveredDevices: [],
          scanIsInProgress: false,
        ),
      ),
      StreamProvider<BleStatus?>(
        create: (_) => _monitor.state,
        initialData: BleStatus.unknown,
      ),
      StreamProvider<ConnectionStateUpdate>(
        create: (_) => _connector.state,
        initialData: const ConnectionStateUpdate(
          deviceId: 'Unknown device',
          connectionState: DeviceConnectionState.disconnected,
          failure: null,
        ),
      ),
    ],
    child: MeshtasticApp(),
  ));
}

class MeshtasticApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mshtstic',
      color: _themeColor,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MeshtasticHomePage(title: 'Meshtastic Homepage'),
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
  Bluetooth bt = Bluetooth();
  int _selectedIndex = 0;

  _MeshtasticHomePageState();

  static const TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    Text(
      'Index 0: Chat',
      style: optionStyle,
    ),
    Text(
      'Index 1: People',
      style: optionStyle,
    ),
    Text(
      'Index 2: Map',
      style: optionStyle,
    ),
    Text(
      'Index 3: Channel',
      style: optionStyle,
    ),
    Text(
      'Index 4: Settings',
      style: optionStyle,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    //bt.addListener(bluetoothListener);
    //bt.setupBluetooth();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
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
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey[400],
        onTap: _onItemTapped,
      ),
    );
  }
}
