/// Result of pruning deleted templates from saved multi-template groups.
class TemplateGroupCleanupResult {
  const TemplateGroupCleanupResult({
    required this.updatedGroups,
    this.removedGroupNames = const [],
    this.rebuiltGroups = const {},
  });

  final Map<String, List<String>> updatedGroups;
  final List<String> removedGroupNames;
  final Map<String, List<String>> rebuiltGroups;

  bool get hasChanges =>
      removedGroupNames.isNotEmpty || rebuiltGroups.isNotEmpty;
}

/// Keeps only templates that still exist (built-in + user-defined).
TemplateGroupCleanupResult cleanupTemplateGroups({
  required Map<String, List<String>> groups,
  required Set<String> validTemplateNames,
}) {
  final updatedGroups = <String, List<String>>{};
  final removedGroupNames = <String>[];
  final rebuiltGroups = <String, List<String>>{};

  for (final entry in groups.entries) {
    final groupName = entry.key;
    final templates = entry.value;
    final validTemplates =
        templates.where((t) => validTemplateNames.contains(t)).toList();

    if (validTemplates.isEmpty) {
      removedGroupNames.add(groupName);
      continue;
    }

    if (validTemplates.length < templates.length) {
      final removed =
          templates.where((t) => !validTemplateNames.contains(t)).toList();
      rebuiltGroups[groupName] = removed;
    }

    updatedGroups[groupName] = validTemplates;
  }

  return TemplateGroupCleanupResult(
    updatedGroups: updatedGroups,
    removedGroupNames: removedGroupNames,
    rebuiltGroups: rebuiltGroups,
  );
}

String templateGroupCleanupMessage(TemplateGroupCleanupResult result) {
  final lines = <String>[];
  for (final name in result.removedGroupNames) {
    lines.add('Removed group "$name" (only deleted templates).');
  }
  for (final entry in result.rebuiltGroups.entries) {
    lines.add(
      'Group "${entry.key}" updated (removed: ${entry.value.join(', ')}).',
    );
  }
  return lines.join('\n');
}
