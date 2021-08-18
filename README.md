# meshtastic_flutter
Routes and keeping the app bar/bottom nav bar:
https://stackoverflow.com/questions/66755344/flutter-navigation-push-while-keeping-the-same-appbar

# TODO 
Seach for: flutter WillPopscope navigator
back button should pop local navigator stack only - not exit app. See this: 
https://stackoverflow.com/questions/56890424/use-nested-navigator-with-willpopscope-in-flutter

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

