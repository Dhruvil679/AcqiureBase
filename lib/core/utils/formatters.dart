// Small formatting helpers used across profile and admin screens.

// Pulls uppercase initials out of a display name, up to [maxChars] characters.
String getInitials(String name, {int maxChars = 2}) {
  if (name.trim().isEmpty) return '?';
  return name
      .trim()
      .split(' ')
      .where((s) => s.isNotEmpty)
      .map((s) => s[0])
      .take(maxChars)
      .join()
      .toUpperCase();
}

// Formats a date as YYYY-MM-DD. Returns 'Unknown' when [date] is null.
String formatDate(DateTime? date) {
  if (date == null) return 'Unknown';
  final local = date.toLocal();
  final year = local.year;
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

// Formats a timestamp for audit-log cards, e.g. "Aug 1, 14:05".
String formatAuditTimestamp(DateTime timestamp) {
  final local = timestamp.toLocal();
  final month = _monthName(local.month);
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month ${local.day}, $hour:$minute';
}

String _monthName(int month) {
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return names[month - 1];
}
