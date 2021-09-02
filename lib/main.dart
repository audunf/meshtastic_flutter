import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:logger/logger.dart';
import 'package:meshtastic_flutter/model/mesh_data_model.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';
import 'package:meshtastic_flutter/protocol/app_from_radio_handler.dart';
import 'package:meshtastic_flutter/model/tab_definition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:tuple/tuple.dart';

import 'bluetooth/ble_connection_logic.dart';
import 'bluetooth/ble_data_streams.dart';
import 'bluetooth/ble_device_connector.dart';
import 'bluetooth/ble_device_interactor.dart';
import 'bluetooth/ble_scanner.dart';
import 'bluetooth/ble_status_monitor.dart';

import 'model/radio_cmd_queue.dart';
import 'model/settings_model.dart';
import 'screen/channel_screen.dart';
import 'screen/chat_screen.dart';
import 'screen/map_screen.dart';
import 'screen/people_screen.dart';
import 'screen/settings_screen.dart';

/// Definition of tabs, their main screen, and sub-screens within each tab (and the navigator path of each)
/// Note that the main tab screen should be the first one, and should have the route '/'
List<TabDefinition> allTabDefinitions = <TabDefinition>[
  TabDefinition(0, 'Chat', Icons.chat, Colors.teal, Colors.grey, [
    Tuple2('/', (tabDef) {
      return ChatScreen(tabDefinition: tabDef);
    }),
  ]),
  TabDefinition(1, 'People', Icons.people, Colors.cyan, Colors.grey, [
    Tuple2('/', (tabDef) {
      return PeopleScreen(tabDefinition: tabDef);
    })
  ]),
  TabDefinition(2, 'Map', Icons.map, Colors.deepPurple, Colors.grey, [
    Tuple2('/', (tabDef) {
      return MapScreen(tabDefinition: tabDef);
    })
  ]),
  TabDefinition(3, 'Channel', Icons.contactless_outlined, Colors.orange, Colors.grey, [
    Tuple2('/', (tabDef) {
      return ChannelScreen(tabDefinition: tabDef);
    })
  ]),
  TabDefinition(4, 'Settings', Icons.settings, Colors.blue, Colors.black87, [
    Tuple2('/', (tabDef) {
      return SettingsScreen(tabDefinition: tabDef);
    }),
    Tuple2('/selectBluetoothDevice', (tabDef) {
      return SelectBluetoothDeviceScreen(tabDefinition: tabDef);
    }),
    Tuple2('/userName', (tabDef) {
      return EditUserNameScreen(tabDefinition: tabDef);
    }),
    Tuple2('/selectRegion', (tabDef) {
      return SelectRegionScreen(tabDefinition: tabDef);
    })
  ])
];

///
/// MAIN
///
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

  final RadioCommandQueue _radioCmdQueue = RadioCommandQueue();
  final _meshDataModel = MeshDataModel();
  final _ble = FlutterReactiveBle();
  final _scanner = BleScanner(ble: _ble, logMessage: _logger.i);
  final _monitor = BleStatusMonitor(_ble);
  final _connector = BleDeviceConnector(
    ble: _ble,
    logMessage: _logger.i,
  );
  final _interactor = BleDeviceInteractor(
    bleDiscoverServices: _ble.discoverServices,
    readCharacteristic: _ble.readCharacteristic,
    writeWithResponse: _ble.writeCharacteristicWithResponse,
    writeWithOutResponse: _ble.writeCharacteristicWithoutResponse,
    subscribeToCharacteristic: _ble.subscribeToCharacteristic,
    logMessage: _logger.i,
  );
  final _settings = SettingsModel();

  final _bleDataStreams =
      BleDataStreams(deviceInteractor: _interactor, bleDeviceConnector: _connector, bleStatusMonitor: _monitor); // raw and FromRadio data streams
  final _fromRadioHandler = AppFromRadioHandler(
      bleDataStreams: _bleDataStreams, settingsModel: _settings, meshDataModel: _meshDataModel); // populates data models based on FromRadio packets

  final _bleConnectionLogic = BleConnectionLogic(
      settingsModel: _settings,
      scanner: _scanner,
      monitor: _monitor,
      connector: _connector,
      interactor: _interactor,
      bleDataStreams: _bleDataStreams,
      radioCommandQueue: _radioCmdQueue);

  await _settings
      .initializeSettingsFromStorage(); // read initial settings from storage (do this after init of _bleConnectionLogic - to allow it to listen for changes)

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: _settings),
      ChangeNotifierProvider.value(value: _meshDataModel),
      ChangeNotifierProvider.value(value: _radioCmdQueue),
      Provider.value(value: _monitor),
      Provider.value(value: _connector),
      Provider.value(value: _interactor),
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

/// The app
class MeshtasticApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meshtastic',
      color: Colors.blue,
      theme: ThemeData(
        textTheme:
            TextTheme(caption: TextStyle(color: Colors.black38), subtitle2: TextStyle(color: Colors.black54), headline6: TextStyle(color: Colors.black87)),
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        textTheme:
            TextTheme(caption: TextStyle(color: Colors.white38), subtitle2: TextStyle(color: Colors.white54), headline6: TextStyle(color: Colors.white70)),
        primarySwatch: Colors.deepPurple,
        accentColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      home: HomePage(),
    );
  }
}

/// HomePage widget
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

/// State of the HomePage
class _HomePageState extends State<HomePage> with TickerProviderStateMixin<HomePage>, WidgetsBindingObserver {
  int _currentIndex = 0;
  AppLifecycleState _appLifecycleState = AppLifecycleState.detached;
  late AnimationController _hide;
  late List<AnimationController> _faders;
  List<Key> _destinationKeys = List<Key>.generate(allTabDefinitions.length, (int index) => GlobalKey()).toList();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance?.addObserver(this);

    _faders = allTabDefinitions.map<AnimationController>((TabDefinition destination) {
      return AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    }).toList();
    _faders[_currentIndex].value = 1.0;
    _destinationKeys = List<Key>.generate(allTabDefinitions.length, (int index) => GlobalKey()).toList();
    _hide = AnimationController(vsync: this, duration: kThemeAnimationDuration);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);

    for (AnimationController controller in _faders) controller.dispose();
    _hide.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
    switch (state) {
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        break;
    }
    print('AppLifecycleState state:  $state');
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth == 0) {
      if (notification is UserScrollNotification) {
        final UserScrollNotification userScroll = notification;
        switch (userScroll.direction) {
          case ScrollDirection.forward:
            _hide.forward();
            break;
          case ScrollDirection.reverse:
            _hide.reverse();
            break;
          case ScrollDirection.idle:
            break;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Scaffold(
        body: SafeArea(
            top: false,
            child: WillPopScope(
              onWillPop: () async {
                var navState = allTabDefinitions[_currentIndex].navigatorKey.currentState;
                if (navState == null) {
                  return Future<bool>.value(true);
                }
                if (navState.canPop()) {
                  navState.maybePop();
                  return Future<bool>.value(false);
                }
                return Future<bool>.value(true);
              },
              child: Stack(
                fit: StackFit.expand,
                children: allTabDefinitions.map((TabDefinition tabDef) {
                  final Widget view = FadeTransition(
                    opacity: _faders[tabDef.index].drive(CurveTween(curve: Curves.fastOutSlowIn)),
                    child: KeyedSubtree(
                      key: _destinationKeys[tabDef.index],
                      child: TabDefinitionView(
                        tabDefinition: tabDef,
                        onNavigation: () {
                          _hide.forward();
                        },
                      ),
                    ),
                  );
                  if (tabDef.index == _currentIndex) {
                    _faders[tabDef.index].forward();
                    return view;
                  } else {
                    _faders[tabDef.index].reverse();
                    if (_faders[tabDef.index].isAnimating) {
                      return IgnorePointer(child: view);
                    }
                    return Offstage(child: view);
                  }
                }).toList(),
              ),
            )),
        bottomNavigationBar: ClipRect(
          child: SizeTransition(
            sizeFactor: _hide,
            axisAlignment: -1.0,
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (int index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: allTabDefinitions.map((TabDefinition destination) {
                return BottomNavigationBarItem(icon: Icon(destination.icon), backgroundColor: destination.appbarColor, label: destination.title);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

///
class ViewNavigatorObserver extends NavigatorObserver {
  final VoidCallback onNavigation;

  ViewNavigatorObserver(this.onNavigation);

  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onNavigation();
  }

  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onNavigation();
  }
}

///
class TabDefinitionView extends StatefulWidget {
  final TabDefinition tabDefinition;
  final VoidCallback onNavigation;

  const TabDefinitionView({Key? key, required this.tabDefinition, required this.onNavigation}) : super(key: key);

  @override
  _DestinationViewState createState() => _DestinationViewState();
}

///
class _DestinationViewState extends State<TabDefinitionView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: widget.tabDefinition.navigatorKey,
      observers: <NavigatorObserver>[
        ViewNavigatorObserver(widget.onNavigation),
      ],
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (BuildContext context) {
            // This calls either default route ("/"), or other named routes defined under a tab - it should enable navigation with state "inside" a tab
            return widget.tabDefinition.createScreen(settings.name, widget.tabDefinition);
          },
        );
      },
    );
  }
}
