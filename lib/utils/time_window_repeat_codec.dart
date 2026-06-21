import 'dart:convert';

import 'package:focusNexus/models/classes/goal_repeat_series.dart';

class TimeWindowRepeatCodec {
  TimeWindowRepeatCodec._();

  static List<GoalRepeatSeries> decodeList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return [];
      return [
        for (final e in decoded)
          if (e is Map)
            GoalRepeatSeries.fromMap(Map<String, dynamic>.from(e)),
      ];
    } catch (_) {
      return [];
    }
  }

  static String encodeList(List<GoalRepeatSeries> series) {
    return jsonEncode([for (final s in series) s.toMap()]);
  }
}
