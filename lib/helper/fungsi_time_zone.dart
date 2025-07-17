String getDeviceTimezone() {
  final now = DateTime.now();
  final offset = now.timeZoneOffset;
  final hours = offset.inHours;

  // Mapping timezone berdasarkan offset Indonesia
  if (hours == 7) return 'Asia/Jakarta';    // WIB
  if (hours == 8) return 'Asia/Makassar';   // WITA
  if (hours == 9) return 'Asia/Jayapura';   // WIT

  return 'Asia/Jakarta'; // Default ke WIB
}