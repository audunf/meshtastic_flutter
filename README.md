# meshtastic_flutter
Routes and keeping the app bar/bottom nav bar:
https://stackoverflow.com/questions/66755344/flutter-navigation-push-while-keeping-the-same-appbar

# TODO 

TODO list:

1. Store SettingsModel data in 'shared_preferences'. Subscribe to changes.
2. Populate SettingsModel data from 'shared_preferences' on app startup   
2. If there's already a selected BT device ID - then try to connect, unless BT is off. This should make 'waiting for device <BT name> <BT ID>' dialog appear.
3. If there isn't a selected BT device ID, then open settings. Flash "Please select BT device"

Put the read/write operations in a separate controlled outside of the BleDataStreams provider.
- should re-structure BleDataStreams. Where should it


Chat:
  Not quite sure how it works with multiple channels active?
  Displays message, cloud icon, date/time, text
People:
  Display name, battery, time since node last visible, GPS coordinates
Map:
  Display map with name and distance. Can probably use a marker here? For the actual position?
Channel config:
  Select channel options (long-slow, etc.)
  Set channel name.
  Display the QR code with channel/encryption settings.
  Allow sharing of channel settings
  Interpret channel settings
Settings tab:
  Set "Your name" - DONE
  Region - DONE

- handle disconnects too
- make a proper state machine?
- do something more sensible than "ChangeNotifier" with the state...

Sequence will be:
1. application scans for available devices
2. User selects a device
3. Download the NodeDB database

## Future ideas
* While not connected: Scan in 'opportunistic' mode. Connect if there is a scan result which matches the selected BT device ID 


# State handling
Overview of options: https://flutter.dev/docs/development/data-and-backend/state-mgmt/options

The recommended way these days: is "Provider":
Example: https://github.com/flutter/samples/blob/master/provider_counter/lib/main.dart

https://pub.dev/documentation/provider/latest/provider/ValueListenableProvider-class.html


# Protobuf
* Flutter protobufs: https://xinyitao.tech/2019/01/12/Using-Protobuf-In-Flutter/ - https://www.andrew.cmu.edu/user/xinyit/2019/01/12/Using-Protobuf-In-Flutter/

To generate all: 
meshtastic_flutter$ protoc --proto_path=./Meshtastic-protobufs --dart_out=lib/proto-autogen ./Meshtastic-protobufs/*.proto

https://github.com/meshtastic/Meshtastic-Android/blob/479f242e066a77c1a789b2ae0265f1743f662b43/app/src/main/java/com/geeksville/mesh/service/BluetoothInterface.kt


# Bluetooth lib selection
Selected the following Bluetooth lib for Flutter: https://github.com/PhilipsHue/flutter_reactive_ble

* flutter_blue looks dead: https://pub.dev/packages/flutter_blue (Android minSdkVersion:19)
  * Background for saying it looks dead - Flutter BLE : https://github.com/pauldemarco/flutter_blue/issues/510
  * See also: https://github.com/flutter/flutter/issues/53493
    * This issue mentions that: https://github.com/PhilipsHue/flutter_reactive_ble - is maintained by the team doing PhilipsHue - which might mean it's actively maintained
* Flutter BLE lib https://github.com/Polidea/FlutterBleLib
  * Not sure it's maintained
    

# Meshtastic and Bluetooth
Meshtastic Bluetooth API: https://meshtastic.org/docs/developers/device/device-api
* UUID for the service: 6ba1b218-15a8-461f-9fa8-5dcae273eafd
* Each characteristic is listed as follows - UUID Properties Description (including human readable name)
** 8ba2bcc2-ee02-4a55-a531-c525c5e454d5 read fromradio - contains a newly received FromRadio packet destined towards the phone (up to MAXPACKET bytes per packet). After reading the esp32 will put the next packet in this mailbox. If the FIFO is empty it will put an empty packet in this mailbox.
** f75c76d2-129e-4dad-a1dd-7866124401e7 write toradio - write ToRadio protobufs to this characteristic to send them (up to MAXPACKET len)
** ed9da18c-a800-4f66-a670-aa7547e34453 read,notify,write fromnum - the current packet # in the message waiting inside fromradio, if the phone sees this notify it should read messages until it catches up with this number.

I/flutter ( 4119): _initStreams with deviceId=08:3A:F2:44:BB:0A
I/flutter ( 4119): readNodeDB with ID=08:3A:F2:44:BB:0A
D/BluetoothGatt( 4119): discoverServices() - device: 08:3A:F2:44:BB:0A
D/BluetoothGatt( 4119): onSearchComplete() = Device=08:3A:F2:44:BB:0A Status=0
I/flutter ( 4119): ** myNodeInfo myNodeNum: 4064590600
I/flutter ( 4119): hasGps: true
I/flutter ( 4119): numBands: 10
I/flutter ( 4119): firmwareVersion: 1.2.43.bf0b598
I/flutter ( 4119): rebootCount: 28
I/flutter ( 4119): messageTimeoutMsec: 300000
I/flutter ( 4119): minAppVersion: 20200
I/flutter ( 4119): maxChannels: 8

I/flutter ( 4119): ** nodeInfo num: 4064590600
I/flutter ( 4119): user: {
I/flutter ( 4119):   id: !f244bb08
I/flutter ( 4119):   longName: Audun
I/flutter ( 4119):   shortName: Adn
I/flutter ( 4119):   macaddr: [8, 58, 242, 68, 187, 8]
I/flutter ( 4119):   hwModel: TBEAM
I/flutter ( 4119): }
I/flutter ( 4119): position: {
I/flutter ( 4119):   latitudeI: 599667403
I/flutter ( 4119):   longitudeI: 106456274
I/flutter ( 4119):   altitude: 247
I/flutter ( 4119):   batteryLevel: 45
I/flutter ( 4119):   time: 1629230186
I/flutter ( 4119): }
I/flutter ( 4119): lastHeard: 1629230186

I/flutter ( 4119): ** nodeInfo num: 4064590588
I/flutter ( 4119): user: {
I/flutter ( 4119):   id: !f244bafc
I/flutter ( 4119):   longName: Nudua
I/flutter ( 4119):   shortName: Nud
I/flutter ( 4119):   macaddr: [8, 58, 242, 68, 186, 252]
I/flutter ( 4119):   hwModel: TBEAM
I/flutter ( 4119): }
I/flutter ( 4119): position: {
I/flutter ( 4119):   batteryLevel: 100
I/flutter ( 4119):   time: 1629230177
I/flutter ( 4119): }
I/flutter ( 4119): lastHeard: 1629230184
I/flutter ( 4119): snr: 9.25
I/flutter ( 4119): ** configCompleteId 1629230185

I/flutter ( 4119): ** handleMeshPacket
I/flutter ( 4119): *** handleNodeInfoPortNum: id: !f244bb08
I/flutter ( 4119): longName: Audun
I/flutter ( 4119): shortName: Adn
I/flutter ( 4119): macaddr: [8, 58, 242, 68, 187, 8]
I/flutter ( 4119): hwModel: TBEAM

I/flutter ( 4119): ** handleMeshPacket
I/flutter ( 4119): *** handleNodeInfoPortNum: id: !f244bafc
I/flutter ( 4119): longName: Nudua
I/flutter ( 4119): shortName: Nud
I/flutter ( 4119): macaddr: [8, 58, 242, 68, 186, 252]
I/flutter ( 4119): hwModel: TBEAM

I/flutter ( 4119): ** handleMeshPacket
I/flutter ( 4119): *** handleNodeInfoPortNum: id: !f244bafc
I/flutter ( 4119): longName: Nudua
I/flutter ( 4119): shortName: Nud
I/flutter ( 4119): macaddr: [8, 58, 242, 68, 186, 252]
I/flutter ( 4119): hwModel: TBEAM

I/flutter ( 4119): ** handleMeshPacket
I/flutter ( 4119): *** handlePositionPortNum: latitudeI: 599667403
I/flutter ( 4119): longitudeI: 106456274
I/flutter ( 4119): altitude: 247
I/flutter ( 4119): batteryLevel: 46
I/flutter ( 4119): time: 1629230160

I/flutter ( 4119): ** handleMeshPacket
I/flutter ( 4119): *** handlePositionPortNum: batteryLevel: 100
I/flutter ( 4119): time: 1629230171

I/flutter ( 4119): ** handleMeshPacket
I/flutter ( 4119): *** handlePositionPortNum: batteryLevel: 100
I/flutter ( 4119): time: 1629230177
F/JabraSDK(26455): Initializing logger LIBJABRA_TRACE_LEVEL: FATAL

D/BluetoothGatt( 4119): onClientConnectionState() - status=19 clientIf=13 device=08:3A:F2:44:BB:0A
D/BluetoothGatt( 4119): close()
D/BluetoothGatt( 4119): unregisterApp() - mClientIf=13


------------
After adding a custom channel called xyzzy to both, and sending two text messages (they appear as ^local)
I/flutter (12939): ** myNodeInfo myNodeNum: 4064590600
I/flutter (12939): hasGps: true
I/flutter (12939): numBands: 10
I/flutter (12939): firmwareVersion: 1.2.43.bf0b598
I/flutter (12939): rebootCount: 28
I/flutter (12939): messageTimeoutMsec: 300000
I/flutter (12939): minAppVersion: 20200
I/flutter (12939): maxChannels: 8
I/flutter (12939): ** nodeInfo num: 4064590600
I/flutter (12939): user: {
I/flutter (12939):   id: !f244bb08
I/flutter (12939):   longName: Audun
I/flutter (12939):   shortName: Adn
I/flutter (12939):   macaddr: [8, 58, 242, 68, 187, 8]
I/flutter (12939):   hwModel: TBEAM
I/flutter (12939): }
I/flutter (12939): position: {
I/flutter (12939):   latitudeI: 599667403
I/flutter (12939):   longitudeI: 106456274
I/flutter (12939):   altitude: 247
I/flutter (12939):   batteryLevel: 43
I/flutter (12939):   time: 1629231262
I/flutter (12939): }
I/flutter (12939): lastHeard: 1629231262
I/flutter (12939): ** nodeInfo num: 4064590588
I/flutter (12939): user: {
I/flutter (12939):   id: !f244bafc
I/flutter (12939):   longName: Nudua
I/flutter (12939):   shortName: Nud
I/flutter (12939):   macaddr: [8, 58, 242, 68, 186, 252]
I/flutter (12939):   hwModel: TBEAM
I/flutter (12939): }
I/flutter (12939): position: {
I/flutter (12939):   batteryLevel: 99
I/flutter (12939):   time: 1629231174
I/flutter (12939): }
I/flutter (12939): lastHeard: 1629231197
I/flutter (12939): snr: 0.25
I/flutter (12939): ** configCompleteId 1629231261
I/flutter (12939): ** handleMeshPacket
I/flutter (12939): *** handleNodeInfoPortNum: id: !f244bb08
I/flutter (12939): longName: Audun
I/flutter (12939): shortName: Adn
I/flutter (12939): macaddr: [8, 58, 242, 68, 187, 8]
I/flutter (12939): hwModel: TBEAM
I/flutter (12939): ** handleMeshPacket
I/flutter (12939): *** handlePositionPortNum: latitudeI: 599667403
I/flutter (12939): longitudeI: 106456274
I/flutter (12939): altitude: 247
I/flutter (12939): batteryLevel: 46
I/flutter (12939): time: 1629231071
I/flutter (12939): ** handleMeshPacket
I/flutter (12939): *** TEXT MESSAGE: [116, 101, 115, 116, 32, 120, 121, 122, 122, 121]
I/flutter (12939): ** handleMeshPacket
I/flutter (12939): *** handlePositionPortNum: batteryLevel: 99
I/flutter (12939): time: 1629231174
I/flutter (12939): ** handleMeshPacket
I/flutter (12939): *** TEXT MESSAGE: [107, 100, 107, 100, 107, 100, 107, 107, 100, 101]


----------------
With error: 

I/flutter (19414): bleStatusHandler status=BleStatus.unknown
I/flutter (19414): bleStatusHandler status=BleStatus.ready
I/flutter (19414): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (19414): │ 💡 Start connecting to 08:3A:F2:44:BB:0A
I/flutter (19414): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
D/BluetoothAdapter(19414): isLeEnabled(): ON
D/BluetoothLeScanner(19414): onScannerRegistered() - status=0 scannerId=10 mScannerId=0
W/BluetoothAdapter(19414): getBluetoothService(), client: android.bluetooth.BluetoothDevice$1@1dc65b1
I/flutter (19414): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (19414): │ 💡 Start connecting to 08:3A:F2:44:BB:0A
I/flutter (19414): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
D/BluetoothAdapter(19414): isLeEnabled(): ON
D/BluetoothGatt(19414): connect() - device: 08:3A:F2:44:BB:0A, auto: false
D/BluetoothGatt(19414): registerApp()
D/BluetoothGatt(19414): registerApp() - UUID=7d7b71b8-7068-4a9b-9bfc-4803ca1b2c1f
I/flutter (19414): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (19414): │ 💡 ConnectionState for device 08:3A:F2:44:BB:0A : DeviceConnectionState.connecting
I/flutter (19414): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
D/BluetoothGatt(19414): onClientRegistered() - status=0 clientIf=10
I/flutter (19414): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (19414): │ 💡 ConnectionState for device 08:3A:F2:44:BB:0A : DeviceConnectionState.connecting
I/flutter (19414): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
D/BluetoothGatt(19414): onClientConnectionState() - status=0 clientIf=10 device=08:3A:F2:44:BB:0A
I/flutter (19414): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (19414): │ 💡 ConnectionState for device 08:3A:F2:44:BB:0A : DeviceConnectionState.connected
I/flutter (19414): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (19414): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (19414): │ 💡 ConnectionState for device 08:3A:F2:44:BB:0A : DeviceConnectionState.connected
I/flutter (19414): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
D/BluetoothGatt(19414): configureMTU() - device: 08:3A:F2:44:BB:0A mtu: 500
D/BluetoothGatt(19414): onConfigureMTU() - Device=08:3A:F2:44:BB:0A mtu=500 status=0
D/BluetoothGatt(19414): configureMTU() - device: 08:3A:F2:44:BB:0A mtu: 500
I/flutter (19414): connectionStateUpdate=ConnectionStateUpdate(deviceId: 08:3A:F2:44:BB:0A, connectionState: DeviceConnectionState.connected, failure: null)
I/flutter (19414): _initStreams with deviceId=08:3A:F2:44:BB:0A
I/flutter (19414): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (19414): │ 💡 Subscribing to: ed9da18c-a800-4f66-a670-aa7547e34453
I/flutter (19414): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (19414): readNodeDB with deviceId=08:3A:F2:44:BB:0A
D/BluetoothGatt(19414): onConfigureMTU() - Device=08:3A:F2:44:BB:0A mtu=500 status=0
I/flutter (19414): connectionStateUpdate=ConnectionStateUpdate(deviceId: 08:3A:F2:44:BB:0A, connectionState: DeviceConnectionState.connecting, failure: null)
D/BluetoothGatt(19414): configureMTU() - device: 08:3A:F2:44:BB:0A mtu: 500
D/BluetoothGatt(19414): onConfigureMTU() - Device=08:3A:F2:44:BB:0A mtu=500 status=0
I/flutter (19414): connectionStateUpdate=ConnectionStateUpdate(deviceId: 08:3A:F2:44:BB:0A, connectionState: DeviceConnectionState.connecting, failure: null)
D/BluetoothGatt(19414): configureMTU() - device: 08:3A:F2:44:BB:0A mtu: 500
D/BluetoothGatt(19414): onConfigureMTU() - Device=08:3A:F2:44:BB:0A mtu=500 status=0
I/flutter (19414): connectionStateUpdate=ConnectionStateUpdate(deviceId: 08:3A:F2:44:BB:0A, connectionState: DeviceConnectionState.connected, failure: null)
I/flutter (19414): _initStreams with deviceId=08:3A:F2:44:BB:0A
D/BluetoothGatt(19414): discoverServices() - device: 08:3A:F2:44:BB:0A
D/BluetoothGatt(19414): onSearchComplete() = Device=08:3A:F2:44:BB:0A Status=0
E/flutter (19414): [ERROR:flutter/lib/ui/ui_dart_state.cc(199)] Unhandled Exception: Bad state: Cannot add new events while doing an addStream
E/flutter (19414): #0      _BroadcastStreamController.addStream (dart:async/broadcast_stream_controller.dart:276:24)
E/flutter (19414): #1      Stream.pipe (dart:async/stream.dart:698:27)
E/flutter (19414): #2      BleDataStreams._initStreams (package:meshtastic_flutter/bluetooth/ble_data_streams.dart:54:60)
E/flutter (19414): #3      BleDataStreams.connectionStateUpdate (package:meshtastic_flutter/bluetooth/ble_data_streams.dart:38:7)
E/flutter (19414): #4      _rootRunUnary (dart:async/zone.dart:1362:47)
E/flutter (19414): #5      _CustomZone.runUnary (dart:async/zone.dart:1265:19)
E/flutter (19414): #6      _CustomZone.runUnaryGuarded (dart:async/zone.dart:1170:7)
E/flutter (19414): #7      _BufferingStreamSubscription._sendData (dart:async/stream_impl.dart:341:11)
E/flutter (19414): #8      _DelayedData.perform (dart:async/stream_impl.dart:591:14)
E/flutter (19414): #9      _StreamImplEvents.handleNext (dart:async/stream_impl.dart:706:11)
E/flutter (19414): #10     _PendingEvents.schedule.<anonymous closure> (dart:async/stream_impl.dart:663:7)
E/flutter (19414): #11     _rootRun (dart:async/zone.dart:1346:47)
E/flutter (19414): #12     _CustomZone.run (dart:async/zone.dart:1258:19)
E/flutter (19414): #13     _CustomZone.runGuarded (dart:async/zone.dart:1162:7)
E/flutter (19414): #14     _CustomZone.bindCallbackGuarded.<anonymous closure> (dart:async/zone.dart:1202:23)
E/flutter (19414): #15     _rootRun (dart:async/zone.dart:1354:13)
E/flutter (19414): #16     _CustomZone.run (dart:async/zone.dart:1258:19)
E/flutter (19414): #17     _CustomZone.runGuarded (dart:async/zone.dart:1162:7)
E/flutter (19414): #18     _CustomZone.bindCallbackGuarded.<anonymous closure> (dart:async/zone.dart:1202:23)
E/flutter (19414): #19     _microtaskLoop (dart:async/schedule_microtask.dart:40:21)
E/flutter (19414): #20     _startMicrotaskLoop (dart:async/schedule_microtask.dart:49:5)
E/flutter (19414):
D/BluetoothGatt(19414): setCharacteristicNotification() - uuid: ed9da18c-a800-4f66-a670-aa7547e34453 enable: true
I/flutter (19414): ** myNodeInfo myNodeNum: 4064590600
I/flutter (19414): hasGps: true
I/flutter (19414): numBands: 10
I/flutter (19414): firmwareVersion: 1.2.43.bf0b598
I/flutter (19414): rebootCount: 35
I/flutter (19414): messageTimeoutMsec: 300000
I/flutter (19414): minAppVersion: 20200
I/flutter (19414): maxChannels: 8
I/flutter (19414): ** nodeInfo num: 4064590600
I/flutter (19414): user: {
I/flutter (19414):   id: !f244bb08
I/flutter (19414):   longName: Audun
I/flutter (19414):   shortName: Adn
I/flutter (19414):   macaddr: [8, 58, 242, 68, 187, 8]
I/flutter (19414):   hwModel: TBEAM
I/flutter (19414): }
I/flutter (19414): position: {
I/flutter (19414):   latitudeI: 599660992
I/flutter (19414):   longitudeI: 106456240
I/flutter (19414):   altitude: 332
I/flutter (19414):   batteryLevel: 65
I/flutter (19414):   time: 1629373747
I/flutter (19414): }
I/flutter (19414): lastHeard: 1629373747
I/flutter (19414): ** nodeInfo num: 4064590588
I/flutter (19414): user: {
I/flutter (19414):   id: !f244bafc
I/flutter (19414):   longName: Nudua
I/flutter (19414):   shortName: Nud
I/flutter (19414):   macaddr: [8, 58, 242, 68, 186, 252]
I/flutter (19414):   hwModel: TBEAM
I/flutter (19414): }
I/flutter (19414): position: {
I/flutter (19414):   batteryLevel: 100
I/flutter (19414):   time: 1629230863
I/flutter (19414): }
I/flutter (19414): lastHeard: 1629230866
I/flutter (19414): snr: 9.5
I/flutter (19414): ** configCompleteId 1629373736
I/flutter (19414): ** handleMeshPacket
I/flutter (19414): *** handleNodeInfoPortNum: id: !f244bb08
I/flutter (19414): longName: Audun
I/flutter (19414): shortName: Adn
I/flutter (19414): macaddr: [8, 58, 242, 68, 187, 8]
I/flutter (19414): hwModel: TBEAM
I/flutter (19414): ** handleMeshPacket
I/flutter (19414): *** handlePositionPortNum: latitudeI: 599661198
I/flutter (19414): longitudeI: 106457213
I/flutter (19414): altitude: 256
I/flutter (19414): batteryLevel: 69
I/flutter (19414): time: 1629369680
I/flutter (19414): ** handleMeshPacket
I/flutter (19414): *** handleNodeInfoPortNum: id: !f244bb08
I/flutter (19414): longName: Audun
I/flutter (19414): shortName: Adn
I/flutter (19414): macaddr: [8, 58, 242, 68, 187, 8]
I/flutter (19414): hwModel: TBEAM
I/flutter (19414): ** handleMeshPacket
I/flutter (19414): *** handlePositionPortNum: latitudeI: 599661764
I/flutter (19414): longitudeI: 106458742
I/flutter (19414): altitude: 235
I/flutter (19414): batteryLevel: 70
I/flutter (19414): time: 1629370582
I/flutter (19414): ** handleMeshPacket
I/flutter (19414): *** handleNodeInfoPortNum: id: !f244bb08
I/flutter (19414): longName: Audun
I/flutter (19414): shortName: Adn
I/flutter (19414): macaddr: [8, 58, 242, 68, 187, 8]
I/flutter (19414): hwModel: TBEAM
I/flutter (19414): ** handleMeshPacket
I/flutter (19414): *** handlePositionPortNum: latitudeI: 599664380
I/flutter (19414): longitudeI: 106455697
I/flutter (19414): altitude: 231
I/flutter (19414): batteryLevel: 69
I/flutter (19414): time: 1629371484
I/flutter (19414): ** handleMeshPacket
I/flutter (19414): *** handleNodeInfoPortNum: id: !f244bb08
I/flutter (19414): longName: Audun
I/flutter (19414): shortName: Adn
I/flutter (19414): macaddr: [8, 58, 242, 68, 187, 8]
I/flutter (19414): hwModel: TBEAM
I/flutter (19414): ** handleMeshPacket
I/flutter (19414): *** handlePositionPortNum: latitudeI: 599663218
I/flutter (19414): longitudeI: 106457882
I/flutter (19414): altitude: 265
I/flutter (19414): batteryLevel: 68
I/flutter (19414): time: 1629372387
I/flutter (19414): ** handleMeshPacket
I/flutter (19414): *** handleNodeInfoPortNum: id: !f244bb08
I/flutter (19414): longName: Audun
I/flutter (19414): shortName: Adn
I/flutter (19414): macaddr: [8, 58, 242, 68, 187, 8]
I/flutter (19414): hwModel: TBEAM
I/flutter (19414): ** handleMeshPacket
I/flutter (19414): *** handlePositionPortNum: latitudeI: 599661395
I/flutter (19414): longitudeI: 106459123
I/flutter (19414): altitude: 265
I/flutter (19414): batteryLevel: 68
I/flutter (19414): time: 1629373289
I/flutter (19414): radioConfigRequest with deviceId=08:3A:F2:44:BB:0A
F/JabraSDK(28652): Initializing logger LIBJABRA_TRACE_LEVEL: FATAL