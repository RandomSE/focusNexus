import 'dart:convert';

/// Pure encode/decode for goal lists persisted in secure storage.
class GoalsCodec {
  GoalsCodec._();

  static List<Map<String, dynamic>> decodeList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return [];
      return [
        for (final e in decoded)
          if (e is Map) Map<String, dynamic>.from(e),
      ];
    } catch (_) {
      return [];
    }
  }

  static String encodeList(List<Map<String, dynamic>> goals) {
    return jsonEncode(goals);
  }
}
