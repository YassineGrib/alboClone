import 'package:later/domain/models/save.dart';

class SaveDayGroup {
  const SaveDayGroup({required this.label, required this.items});

  final String label;
  final List<SaveItem> items;
}

class SaveTimeline {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static DateTime dayOf(DateTime value) {
    final local = value.isUtc ? value.toLocal() : value;
    return DateTime(local.year, local.month, local.day);
  }

  static String labelFor(DateTime day, {required DateTime now}) {
    final today = dayOf(now);
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == today) {
      return 'Today';
    }
    if (day == yesterday) {
      return 'Yesterday';
    }
    final gap = today.difference(day).inDays;
    if (gap > 0 && gap < 7) {
      return _weekday(day.weekday);
    }
    return '${day.day} ${_months[day.month - 1]} ${day.year}';
  }

  static List<SaveDayGroup> group(List<SaveItem> saves, {required DateTime now}) {
    final buckets = <DateTime, List<SaveItem>>{};
    final order = <DateTime>[];
    for (final item in saves) {
      final day = dayOf(item.createdAt);
      if (!buckets.containsKey(day)) {
        buckets[day] = [];
        order.add(day);
      }
      buckets[day]!.add(item);
    }
    return [
      for (final day in order)
        SaveDayGroup(label: labelFor(day, now: now), items: buckets[day]!),
    ];
  }

  static String _weekday(int weekday) {
    return const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][weekday - 1];
  }
}
