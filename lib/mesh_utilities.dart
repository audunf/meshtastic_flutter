
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