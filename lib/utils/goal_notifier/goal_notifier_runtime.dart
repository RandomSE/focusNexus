import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:focusNexus/services/storage/key_value_storage.dart';

import '../notification_schedule_utils.dart';

class GoalNotifierRuntime {
  GoalNotifierRuntime._();

  static final GoalNotifierRuntime I = GoalNotifierRuntime._();

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  bool initialized = false;
  static const platform = MethodChannel('flutter_native_timezone');
  KeyValueStorage? boundStorage;

  final encouragementThreshold = 6;
  static const aiEncouragementSlotOffsets = [4, 50, 51, 52];
  final Map<String, List<Timer>> activeTimers = {};
  final DateFormat formatter = DateFormat('dd MMMM yyyy HH:mm');
  tz.TZDateTime? _now;
  tz.TZDateTime get now {
    _now ??= tz.TZDateTime.now(tz.local);
    return _now!;
  }

  set now(tz.TZDateTime value) => _now = value;
  final goalGroupId = 1;
  final goalRepeatingGroupId = 2;
  final aiEncouragementGroupId = 3;
  final dailyAffirmationsGroupId = 4;

  /// Legacy repeating id; kept for cancel compatibility.
  static const dailyAffirmationsScheduleBaseId = 500000;
  int get dailyAffirmationsHorizonDays =>
      NotificationScheduleUtils.affirmationHorizonDays;
  bool aiEncouragement = false;
  bool dailyAffirmations = false;
  Future<void> Function(String time)? dailyAffirmationsSchedulerForTesting;
  AndroidScheduleMode scheduleMode =
      AndroidScheduleMode.inexactAllowWhileIdle; // Fallback

  void resetForTesting() {
    boundStorage = null;
    initialized = false;
    aiEncouragement = false;
    dailyAffirmations = false;
    dailyAffirmationsSchedulerForTesting = null;
    activeTimers.clear();
    _now = null;
  }
}
