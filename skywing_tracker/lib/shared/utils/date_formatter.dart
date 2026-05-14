import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy').format(date);
}

String formatDateTime(DateTime date) {
  return DateFormat('dd MMM yyyy, HH:mm').format(date);
}

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  return '${minutes}m';
}

String timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}
