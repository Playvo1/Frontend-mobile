import '../l10n/l10n.dart';

/// Formats the last-sync timestamp the way the design shows it:
/// "اليوم، 10:35 ص".
class SyncTimeFormat {
  SyncTimeFormat._();

  static String label(DateTime time, AppLocalizations l10n) {
    final DateTime now = DateTime.now();
    final bool isToday = time.year == now.year &&
        time.month == now.month &&
        time.day == now.day;

    final int hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final String minute = time.minute.toString().padLeft(2, '0');
    final String suffix =
        time.hour < 12 ? l10n.morningShort : l10n.eveningShort;
    final String clock = '$hour12:$minute $suffix';

    if (isToday) {
      return '${l10n.today}، $clock';
    }
    return '${time.day}/${time.month}، $clock';
  }
}
