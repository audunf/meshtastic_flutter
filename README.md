# meshtastic_flutter
This is a *very* experimental Flutter-based client for Meshtastic radios. Consider it pre-alpha.
Please do not report bugs. 

What can it do? 
* Show text messages between two nodes
* Show info about known nodes (not pretty)
* Connect to different nodes
* Show position on map

# Protobuf
Before attempting to compile the app please generate protobuf source code from definitions. 

The protobuf definitions are a GIT submodule: ```./Meshtastic-protobufs```

To generate all:
```protoc --proto_path=./Meshtastic-protobufs --dart_out=lib/proto-autogen ./Meshtastic-protobufs/*.proto```

See also: 
* Flutter protobufs: https://xinyitao.tech/2019/01/12/Using-Protobuf-In-Flutter/
* https://www.andrew.cmu.edu/user/xinyit/2019/01/12/Using-Protobuf-In-Flutter/
* https://github.com/meshtastic/Meshtastic-Android/blob/479f242e066a77c1a789b2ae0265f1743f662b43/app/src/main/java/com/geeksville/mesh/service/BluetoothInterface.kt

# Future naming
Should it be named "Mutter" - Meshtastic flUTTER? "Mutter" being "to talk in a quiet voice that 
is difficult to hear, especially because you are annoyed or embarrassed, or are talking to yourself".

# Data model
There are different data models. 
1. MeshDataModel - related to connection to a radio. The radio itself, other nodes, other users, positions. Things we get after sending 'want_config' to a node. It's all tied to a bluetooth ID. 
2. MeshDataPacketQueue - any MeshPacket (see protobuf definition) sent/received. These include encrypted messages and plain text messages. Tied to BT ID - reloaded on change. 
3. SettingsModel - settings for the app itself. 

The notification/triggers used to propagate changes are a bit complicated. Perhaps more than they should be. 

# TODO
I/flutter (11225): ** handleMeshPacket
I/flutter (11225): *** handleRoutingPortNum: errorReason: MAX_RETRANSMIT
I/flutter (11225): _addRadioCommandBack - has this package already. Discarding duplicate {bluetooth_id: 9049265715966, direction: 1, payload_variant: 5, checksum: 1140863185, packet_id: 1413827953, from_node_num: 4064590588, to_node_num: 4064590588, channel: 0, rx_time_epoch_sec: 1632781943, rx_snr: 0.0, hop_limit: 0, want_ack: 0, priority: 120, rx_rssi: 0, acknowledged: 0, payload: [90, 35, 13, 252, 186, 68, 242, 21, 252, 186, 68, 242, 34, 11, 8, 5, 18, 2, 24, 5, 53, 19, 0, 0, 0, 53, 113, 77, 69, 84, 61, 119, 70, 82, 97, 96, 120]}

The ack required to mark packages sent is: 
I/flutter (19689): ** handleMeshPacket from: 4064590588
I/flutter (19689): to: 4064590588
I/flutter (19689): decoded: {
I/flutter (19689):   portnum: ROUTING_APP
I/flutter (19689):   payload: [24, 0]
I/flutter (19689):   requestId: 11
I/flutter (19689): }
I/flutter (19689): id: 555109731
I/flutter (19689): rxTime: 1632864178
I/flutter (19689): priority: ACK
I/flutter (19689): *** handleRoutingPortNum: errorReason: NONE
I/flutter (19689):  -> errorReason NONE

- when getting new packet, and already connected, send immediately. 
- check whether displayed time in the messages are from the actual message or reception time
- Getting "duplicate/discard" on sending many msg fast. Same checksum. Why?  
- it might be that we're using seconds epoch to calc checksum on outgoing. Perhaps internal representation should be milliseconds, and convert to seconds on send
  the current packet # in the message waiting inside fromradio, if the phone sees this notify it should read messages until it catches up with this number.
- how do we get an ACK from the radio when a packet has been sent? 
- remember devices connected in the past and show those in the list of available

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
  Everything related to channels. Select channel options (long-slow, etc.). Set channel name.
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

# Various doc
## Meshtastic and Bluetooth
Meshtastic Bluetooth API: https://meshtastic.org/docs/developers/device/device-api
* UUID for the service: 6ba1b218-15a8-461f-9fa8-5dcae273eafd
* Each characteristic is listed as follows - UUID Properties Description (including human readable name)
  ** 8ba2bcc2-ee02-4a55-a531-c525c5e454d5 read fromradio - contains a newly received FromRadio packet destined towards the phone (up to MAXPACKET bytes per packet). After reading the esp32 will put the next packet in this mailbox. If the FIFO is empty it will put an empty packet in this mailbox.
  ** f75c76d2-129e-4dad-a1dd-7866124401e7 write toradio - write ToRadio protobufs to this characteristic to send them (up to MAXPACKET len)
  ** ed9da18c-a800-4f66-a670-aa7547e34453 read,notify,write fromnum - the current packet # in the message waiting inside fromradio, if the phone sees this notify it should read messages until it catches up with this number.

## Channel settings QR code
Various docs and copy of docs for later: 
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

FIXME: Add description of multi-channel support and how primary vs secondary channels are used. 
FIXME: explain how apps use channels for security. explain how remote settings and remote gpio are managed as an example

Code: 
https://github.com/meshtastic/Meshtastic-Android/blob/041a04afc15710f2963621a2344376f1b444a0ff/app/src/main/java/com/geeksville/mesh/model/ChannelSet.kt
https://github.com/meshtastic/Meshtastic-Android/blob/479f242e066a77c1a789b2ae0265f1743f662b43/app/src/test/java/com/geeksville/mesh/model/ChannelSetTest.kt
