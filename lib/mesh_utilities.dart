
import 'package:intl/intl.dart';  //for date format
import 'package:intl/date_symbol_data_local.dart';
import 'package:archive/archive_io.dart' as archive;

import 'package:latlong2/latlong.dart';
import 'package:meshtastic_flutter/proto-autogen/mesh.pb.dart';
import 'package:protobuf/protobuf.dart';

/// check if a string is a valid Bluetooth MAC address (only the format)
/// Matches string like: 09:3F:F2:44:BA:F7
bool isValidBluetoothMac(String s) {
  final RegExp r = new RegExp(
    r"([0-9A-F]{2}(\:|$)){6}",
    caseSensitive: false,
    multiLine: false,
  );
  return r.hasMatch(s);
}


/// Take a protobuf Position object, return a LatLng
LatLng convertPositionToLatLng(Position p) {
  final double e7 = 10000000.0;
  return LatLng (p.latitudeI / e7, p.longitudeI / e7);
}


/// Epoch seconds to DateTime
DateTime epochSecondsToDateTime(int tsEpochSeconds) {
  return DateTime.fromMillisecondsSinceEpoch(tsEpochSeconds * 1000);
}

///
String epochSecondsToLongDateTimeString(int tsEpochSeconds) {
  // TODO: Use local format - needs someone to think about i18n
  DateTime ld = epochSecondsToDateTime(tsEpochSeconds).toLocal();
  DateFormat d = DateFormat("yyyy-MM-dd hh:mm:ss");
  return d.format(ld);
}

/// short
String epochSecondsToShortDateTimeString(int tsEpochSeconds) {
  // TODO: Use local format - needs someone to think about i18n
  DateTime ld = epochSecondsToDateTime(tsEpochSeconds).toLocal();
  DateFormat d = DateFormat();
  return d.format(ld);
}

///
String epochSecondsToDateString(int tsEpochSeconds) {
  // TODO: Use local format - needs someone to think about i18n
  DateTime ld = epochSecondsToDateTime(tsEpochSeconds).toLocal();
  DateFormat d = DateFormat("yyyy-MM-dd");
  return d.format(ld);
}

String epochSecondsToTimeString(int tsEpochSeconds) {
  // TODO: Use local format - needs someone to think about i18n
  DateTime ld = epochSecondsToDateTime(tsEpochSeconds).toLocal();
  DateFormat d = DateFormat("hh:mm:ss");
  return d.format(ld);
}

/// Make a CRC32 on FromRadio or ToRadio (both inherit from GeneratedMessage)
int makePackageChecksum(GeneratedMessage msg) {
  return archive.getCrc32(msg.writeToBuffer());
}

/// bluetooth ID: 08:3A:F2:44:BB:0A -> int (6*8 = 48 bit)
int convertBluetoothAddressToInt(String hex) {
  // remove all the ':'
  return int.parse(hex.replaceAll(RegExp(r':'), ''), radix: 16);
}