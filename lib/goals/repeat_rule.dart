import 'dart:convert';

/// Recurrence unit for time-window goal series.
enum RepeatUnit {
  hours,
  days,
  weeks;

  static RepeatUnit parse(String? raw) {
    return RepeatUnit.values.firstWhere(
      (u) => u.name == raw,
      orElse: () => RepeatUnit.days,
    );
  }
}

/// When and how a time-window goal series repeats.
class RepeatRule {
  const RepeatRule({
    this.unit = RepeatUnit.days,
    this.interval = 1,
    this.weekdays = const {},
    this.startOffset = Duration.zero,
    this.enabled = false,
  });

  final RepeatUnit unit;
  final int interval;
  final Set<int> weekdays;
  final Duration startOffset;
  final bool enabled;

  RepeatRule copyWith({
    RepeatUnit? unit,
    int? interval,
    Set<int>? weekdays,
    Duration? startOffset,
    bool? enabled,
  }) {
    return RepeatRule(
      unit: unit ?? this.unit,
      interval: interval ?? this.interval,
      weekdays: weekdays ?? this.weekdays,
      startOffset: startOffset ?? this.startOffset,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap() => {
    'unit': unit.name,
    'interval': interval,
    'weekdays': weekdays.toList()..sort(),
    'startOffsetMinutes': startOffset.inMinutes,
    'enabled': enabled,
  };

  factory RepeatRule.fromMap(Map<String, dynamic> map) {
    final weekdayRaw = map['weekdays'];
    final weekdays = <int>{};
    if (weekdayRaw is List) {
      for (final value in weekdayRaw) {
        final parsed = int.tryParse(value.toString());
        if (parsed != null && parsed >= 1 && parsed <= 7) {
          weekdays.add(parsed);
        }
      }
    }
    return RepeatRule(
      unit: RepeatUnit.parse(map['unit']?.toString()),
      interval: int.tryParse(map['interval']?.toString() ?? '1') ?? 1,
      weekdays: weekdays,
      startOffset: Duration(
        minutes: int.tryParse(map['startOffsetMinutes']?.toString() ?? '0') ?? 0,
      ),
      enabled: map['enabled'] == true ||
          map['enabled']?.toString().toLowerCase() == 'true',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory RepeatRule.fromJson(String json) =>
      RepeatRule.fromMap(jsonDecode(json) as Map<String, dynamic>);

  static const none = RepeatRule();
}
