# meshtastic_flutter
Should it be named "Mutter" - Meshtastic flUTTER? "Mutter" being "to talk in a quiet voice that 
is difficult to hear, especially because you are annoyed or embarrassed, or are talking to yourself".

Routes and keeping the app bar/bottom nav bar:
https://stackoverflow.com/questions/66755344/flutter-navigation-push-while-keeping-the-same-appbar

MAP popup
https://medium.com/zipper-studios/flutter-map-custom-and-dynamic-popup-over-the-marker-732d26ef9bc7

# Data model
There are different data models. 
1. MeshDataModel - related to connection to a radio. The radio itself, other nodes, other users, positions. Things we get after sending 'want_config' to a node. It's all tied to a bluetooth ID. 
2. MeshDataPacketQueue - any MeshPacket (see protobuf definition) sent/received. These include encrypted messages and plain text messages. Tied to BT ID - reloaded on change. 
3. SettingsModel - settings for the app itself. 

# TODO 
- stop doing the endless BT scan. Just jump straight to connection what that's required. Only scan when looking for new devices from Settings.  
- how do we get an ACK from the radio when a packet has been sent? 

TODO list:
- Chat screen.
  Icon per message showing status - each message might get an icon similar to the one in the main status bar? Needs some research. Look at Android app. 
  Add the sender/recipient in the message. Small font.
  Not quite sure how it would work with multiple channels active? Should it be possible to chose channel name on top-left, where it just says 'Chat' right now?
- Improve the "People" screen. 
  Needs an icon for status of other nodes. 
  Battery of every node.
  Distance in meters?
  Time since last visible
- Settings screen
  Setting Region and writing it to the device
  Select channel options (long-slow, etc.). Set channel name.
- Channel setup screen. With QR code. How does this work?  
- Mesh status icon in the application title-bar. How will this work? Need to do some research on how the Android app does it.   

- Bluetooth
  There's a lot to do. 
  Avoid scanning all the time.
  Buffer more commands
  Can app know roughly when device will be awake the next time and only try to connect then? 
  Check all the stuff related to the BT notification channel (unread count and reading until done)
  Currently we only read packets until no packets are returned (empty). I don't think that's right. 

Larger questions: 
- Handling channels. Encryption. There's nothing on this.
  Allow sharing of channel settings
  Display the QR code with channel/encryption settings.
  Allow sharing of channel settings
  Interpret channel settings

## Channel settings QR code
https://meshtastic.org/docs/developers/protobufs/api#channel

Full settings (center freq, spread factor, pre-shared secret key etc...) needed to configure a radio for speaking on 
a particular channel This information can be encoded as a QRcode/url so that other users can configure their radio 
to join the same channel. A note about how channel names are shown to users: channelname-Xy poundsymbol is a 
prefix used to indicate this is a channel name (idea from @professr). Where X is a letter from A-Z (base 26) representing 
a hash of the PSK for this channel - so that if the user changes anything about the channel (which does force a new PSK) 
this letter will also change. Thus preventing user confusion if two friends try to type in a channel name of "BobsChan" 
and then can't talk because their PSKs will be different. The PSK is hashed into this letter by 
"0x41 + [xor all bytes of the psk ] modulo 26" This also allows the option of someday if people have the PSK off (zero), 
the users COULD type in a channel name and be able to talk. Y is a lower case letter from a-z that represents the channel 
'speed' settings (for some future definition of speed)

FIXME: Add description of multi-channel support and how primary vs secondary channels are used. FIXME: explain how apps use channels for security. explain how remote settings and remote gpio are managed as an example

Code: 
https://github.com/meshtastic/Meshtastic-Android/blob/041a04afc15710f2963621a2344376f1b444a0ff/app/src/main/java/com/geeksville/mesh/model/ChannelSet.kt
https://github.com/meshtastic/Meshtastic-Android/blob/479f242e066a77c1a789b2ae0265f1743f662b43/app/src/test/java/com/geeksville/mesh/model/ChannelSetTest.kt


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
