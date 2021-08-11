import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

// Meshtastic service ID. See: https://meshtastic.org/docs/developers/device/device-api
final Uuid meshtasticServiceId = Uuid.parse('6ba1b218-15a8-461f-9fa8-5dcae273eafd');
final readFromRadioCharacteristicId = Uuid.parse('8ba2bcc2-ee02-4a55-a531-c525c5e454d5'); // read fromradio
final writeToRadioCharacteristicId = Uuid.parse('f75c76d2-129e-4dad-a1dd-7866124401e7'); //write toradio
final readNotifyWriteCharacteristicId = Uuid.parse('ed9da18c-a800-4f66-a670-aa7547e34453'); // read,notify,write fromnum
final Map<int, String> regionCodes = {0: 'Unset', 1: 'US', 2: 'EU433', 3: 'EU865', 4: 'CN', 5: 'JP', 6: 'ANZ', 7: 'KR', 8: 'TW', 9: 'RU'};
