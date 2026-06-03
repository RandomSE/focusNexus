import 'dart:convert';

import 'package:focusNexus/models/classes/goal_set.dart';

/// Encode/decode [GoalSet] lists persisted in secure storage.
class GoalsCodec {
  GoalsCodec._();

  static List<GoalSet> decodeList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return [];
      return [
        for (final e in decoded)
          if (e is Map) GoalSet.fromMap(Map<String, dynamic>.from(e)),
      ];
    } catch (_) {
      return [];
    }
  }

  static String encodeList(List<GoalSet> goals) {
    return jsonEncode([
      for (final g in goals) g.toMap(),
    ]);
  }
}
