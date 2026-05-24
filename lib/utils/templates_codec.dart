import 'dart:convert';

/// Pure encode/decode for user templates and template groups.
class TemplatesCodec {
  TemplatesCodec._();

  static Map<String, Map<String, dynamic>> decodeUserTemplates(String? json) {
    if (json == null || json.isEmpty) return {};
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return {};
      return decoded.map(
        (key, value) => MapEntry(
          key.toString(),
          value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{},
        ),
      );
    } catch (_) {
      return {};
    }
  }

  static String encodeUserTemplates(Map<String, Map<String, dynamic>> templates) {
    return jsonEncode(templates);
  }

  static Map<String, List<String>> decodeTemplateGroups(String? json) {
    if (json == null || json.isEmpty) return {};
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return {};
      return decoded.map(
        (key, value) => MapEntry(
          key.toString(),
          value is List ? value.map((e) => e.toString()).toList() : <String>[],
        ),
      );
    } catch (_) {
      return {};
    }
  }

  static String encodeTemplateGroups(Map<String, List<String>> groups) {
    return jsonEncode(groups);
  }
}
