class DateFormatter {
  static String format(DateTime dateTime) {
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    } else if (diff.inDays == 1 || (now.day != dateTime.day && diff.inHours < 48)) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final yearStr = dateTime.year == now.year ? '' : ', ${dateTime.year}';
      return '${months[dateTime.month - 1]} ${dateTime.day}$yearStr';
    }
  }

  static String formatDateDivider(DateTime dateTime) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    final DateTime msgDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (msgDate == today) {
      return 'Today';
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final yearStr = dateTime.year == now.year ? '' : ' ${dateTime.year}';
      return '${dateTime.day} ${months[dateTime.month - 1]}$yearStr';
    }
  }

  static String formatClockTime(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
