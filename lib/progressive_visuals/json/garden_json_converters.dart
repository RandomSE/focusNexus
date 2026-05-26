import 'package:json_annotation/json_annotation.dart';

import '../mutation_kind.dart';
import '../visual_theme_id.dart';

/// Serializes [VisualThemeId] as enum [name]; unknown values map to [VisualThemeId.zenGarden].
class VisualThemeIdJsonConverter
    implements JsonConverter<VisualThemeId, String> {
  const VisualThemeIdJsonConverter();

  @override
  VisualThemeId fromJson(String json) {
    return VisualThemeId.values.firstWhere(
      (t) => t.name == json,
      orElse: () => VisualThemeId.zenGarden,
    );
  }

  @override
  String toJson(VisualThemeId object) => object.name;
}

/// Parses decor stash map; skips null and non-numeric values (sanitized later).
class DecorStashJsonConverter
    implements JsonConverter<Map<String, int>, Object?> {
  const DecorStashJsonConverter();

  @override
  Map<String, int> fromJson(Object? json) {
    if (json is! Map) return const {};
    final result = <String, int>{};
    for (final entry in json.entries) {
      final value = entry.value;
      if (value is num) {
        result[entry.key.toString()] = value.toInt();
      }
    }
    return result;
  }

  @override
  Object toJson(Map<String, int> object) => object;
}

/// Serializes [MutationKind] as enum [name]; unknown values map to [MutationKind.invertedColors].
class MutationKindJsonConverter implements JsonConverter<MutationKind, String> {
  const MutationKindJsonConverter();

  @override
  MutationKind fromJson(String json) {
    return MutationKind.values.firstWhere(
      (k) => k.name == json,
      orElse: () => MutationKind.invertedColors,
    );
  }

  @override
  String toJson(MutationKind object) => object.name;
}
