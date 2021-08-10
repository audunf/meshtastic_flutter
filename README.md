# meshtastic_flutter

# components
AppBar - top bar
BottomNavigationBar 

# TODO 
 TODO list:
 Create a very rudimentary main UI. Tabs: Chat, People, Map, Channels, Settings
 Main header: Cloud status icon.
 Settings tab:
   Combo-box showing BT devices
     When BT device has been selected, display device details:
       * Set "Your name"
       * Region
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

I/flutter (29823): ** myInfo myNodeNum: 4064590600
I/flutter (29823): hasGps: true
I/flutter (29823): numBands: 10
I/flutter (29823): firmwareVersion: 1.2.43.bf0b598
I/flutter (29823): rebootCount: 19
I/flutter (29823): messageTimeoutMsec: 300000
I/flutter (29823): minAppVersion: 20200
I/flutter (29823): maxChannels: 8
I/flutter (29823): ** nodeInfo num: 4064590600
I/flutter (29823): user: {
I/flutter (29823):   id: !f244bb08
I/flutter (29823):   longName: Audun
I/flutter (29823):   shortName: Adn
I/flutter (29823):   macaddr: [8, 58, 242, 68, 187, 8]
I/flutter (29823):   hwModel: TBEAM
I/flutter (29823): }
I/flutter (29823): position: {
I/flutter (29823):   latitudeI: 599664661
I/flutter (29823):   longitudeI: 106454410
I/flutter (29823):   altitude: 283
I/flutter (29823):   batteryLevel: 100
I/flutter (29823):   time: 1627944623
I/flutter (29823): }
I/flutter (29823): lastHeard: 1627944623
I/flutter (29823): ** nodeInfo num: 4064590588
I/flutter (29823): position: {
I/flutter (29823):   time: 1627489580
I/flutter (29823): }
I/flutter (29823): lastHeard: 1627489662
I/flutter (29823): snr: -16.25
I/flutter (29823): ** configCompleteId 1627944623
I/flutter (29823): ** handleMeshPacket
I/flutter (29823): *** handleNodeInfoPortNum: id: !f244bb08
I/flutter (29823): longName: Audun
I/flutter (29823): shortName: Adn
I/flutter (29823): macaddr: [8, 58, 242, 68, 187, 8]
I/flutter (29823): hwModel: TBEAM
I/flutter (29823): ** handleMeshPacket
I/flutter (29823): *** handlePositionPortNum: latitudeI: 599660653
I/flutter (29823): longitudeI: 106457018
I/flutter (29823): altitude: 219
I/flutter (29823): batteryLevel: 100
I/flutter (29823): time: 1627944380
I/flutter (29823): end of data