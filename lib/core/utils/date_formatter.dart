class DateUtilsHelper {
  static String nowUtcIso() {
    return DateTime.now().toUtc().toIso8601String();
  }

  static String formatDisplay(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(isoString).toLocal();
      final year = date.year.toString().padLeft(4, '0');
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$year-$month-$day $hour:$minute';
    } catch (_) {
      return isoString;
    }
  }
}
