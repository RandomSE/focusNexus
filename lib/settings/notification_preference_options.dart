/// Canonical notification frequency/style storage strings for settings and registration.
///
/// Style order is product default priority: Vibrant, then Minimal, then Animated.
abstract final class NotificationPreferenceOptions {
  NotificationPreferenceOptions._();

  static const String frequencyLow = 'Low';
  static const String frequencyMedium = 'Medium';
  static const String frequencyHigh = 'High';
  static const String frequencyDisabled = 'No notifications';

  static const String styleVibrant = 'Vibrant';
  static const String styleMinimal = 'Minimal';
  static const String styleAnimated = 'Animated';

  static const List<String> frequencies = [
    frequencyLow,
    frequencyMedium,
    frequencyHigh,
    frequencyDisabled,
  ];

  /// Registration / product default style order.
  static const List<String> styles = [
    styleVibrant,
    styleMinimal,
    styleAnimated,
  ];

  static const String defaultFrequency = frequencyMedium;
  static const String defaultStyle = styleVibrant;

  static bool isEnabled(String? frequency) {
    final value = (frequency ?? '').trim();
    return value.isNotEmpty &&
        value != frequencyDisabled &&
        (value == frequencyLow ||
            value == frequencyMedium ||
            value == frequencyHigh);
  }

  static bool isDisabled(String? frequency) =>
      (frequency ?? '').trim() == frequencyDisabled;
}
