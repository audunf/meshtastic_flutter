# meshtastic_flutter

Use:
* flutter_blue: https://pub.dev/packages/flutter_blue (Android minSdkVersion:19)

From others:
* This is a demo application for reading the NodeDB from a Meshtastic device using the flutter_blue library, which will allow operation on both iOS and Android devices.
* Currently I only have the Bluetooth search list written. I still need to write the actual connecting and interaction with the device.

* Flutter BLE lib https://github.com/Polidea/FlutterBleLib
* Flutter protobufs: https://xinyitao.tech/2019/01/12/Using-Protobuf-In-Flutter/

* Flutter BLE is dead: https://github.com/pauldemarco/flutter_blue/issues/510
* See also: https://github.com/flutter/flutter/issues/53493
** Mentions that: https://github.com/PhilipsHue/flutter_reactive_ble - is maintained by the team doing PhilipsHue - which might mean it's actively maintained


Meshtastic Bluetooth API: https://meshtastic.org/docs/developers/device/device-api
* UUID for the service: 6ba1b218-15a8-461f-9fa8-5dcae273eafd
* Each characteristic is listed as follows - UUID Properties Description (including human readable name)
** 8ba2bcc2-ee02-4a55-a531-c525c5e454d5 read fromradio - contains a newly received FromRadio packet destined towards the phone (up to MAXPACKET bytes per packet). After reading the esp32 will put the next packet in this mailbox. If the FIFO is empty it will put an empty packet in this mailbox.
** f75c76d2-129e-4dad-a1dd-7866124401e7 write toradio - write ToRadio protobufs to this characteristic to send them (up to MAXPACKET len)
** ed9da18c-a800-4f66-a670-aa7547e34453 read,notify,write fromnum - the current packet # in the message waiting inside fromradio, if the phone sees this notify it should read messages until it catches up with this number.