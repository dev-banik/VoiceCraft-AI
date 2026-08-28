import 'package:intl/intl.dart';

/// Shared formatting helpers for durations, file sizes and dates so every
/// screen (dashboard, editor, playback) renders these identically.
class Formatters {
  Formatters._();

  static String duration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  static String fileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    final i = (bytes.bitLength - 1) ~/ 10;
    final index = i.clamp(0, suffixes.length - 1);
    final value = bytes / (1 << (index * 10));
    return '${value.toStringAsFixed(value < 10 && index > 0 ? 1 : 0)} '
        '${suffixes[index]}';
  }

  static String date(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  static String dateTime(DateTime date) =>
      DateFormat('MMM d, yyyy · h:mm a').format(date);

  static String relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return Formatters.date(date);
  }
}
