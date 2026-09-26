import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request Android 13+ notification permissions
    final androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyAlarms({List<dynamic>? goals}) async {
    // 1. Sync Goal Notifications based on completion status
    if (goals != null) {
      await syncGoalNotifications(goals);
    } else {
      await scheduleGoalNotifications();
    }

    // 2. NIGHT OVERALL TARGETS ACHIEVED & MASTERY GREETING (09:30 PM)
    await _scheduleDailyNotification(
      id: 104,
      hour: 21,
      minute: 30,
      title: '🌙 Nightly Mastery & Overall Targets Report',
      body: 'Review your overall targets achieved today! Check your daily routine, workout, calories & study mastery.',
      channelId: 'daily_entry_channel',
      channelName: 'Nightly Mastery & Target Reminders',
      channelDesc: 'Summary notifications of daily target completion and discipline greetings',
    );
  }

  Future<void> scheduleGoalNotifications() async {
    // 1. MORNING GOALS CHECK-IN (08:00 AM)
    await _scheduleDailyNotification(
      id: 101,
      hour: 8,
      minute: 0,
      title: '🎯 Morning Strict Goals Check-In',
      body: 'Start strong! Review your active strict targets, stay disciplined, and conquer today\'s goals.',
      channelId: 'goals_routine_channel',
      channelName: 'Strict Goals Reminders',
      channelDesc: 'Notifications for morning, afternoon, and evening strict goals tracking',
    );

    // 2. AFTERNOON GOALS PULSE (01:30 PM)
    await _scheduleDailyNotification(
      id: 102,
      hour: 13,
      minute: 30,
      title: '⚡ Midday Goal & Focus Pulse',
      body: 'Halfway through the day! Incomplete goals need your focus. Maintain your winning streak!',
      channelId: 'goals_routine_channel',
      channelName: 'Strict Goals Reminders',
      channelDesc: 'Notifications for morning, afternoon, and evening strict goals tracking',
    );

    // 3. EVENING GOALS SPRINT (06:30 PM)
    await _scheduleDailyNotification(
      id: 103,
      hour: 18,
      minute: 30,
      title: '🔥 Evening Goal Sprint',
      body: 'Finish what you started! Lock in your remaining strict goal targets before the night begins.',
      channelId: 'goals_routine_channel',
      channelName: 'Strict Goals Reminders',
      channelDesc: 'Notifications for morning, afternoon, and evening strict goals tracking',
    );
  }

  Future<void> cancelGoalNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(101);
      await _flutterLocalNotificationsPlugin.cancel(102);
      await _flutterLocalNotificationsPlugin.cancel(103);
    } catch (_) {}
  }

  Future<void> syncGoalNotifications(List<dynamic> goals) async {
    // Check if any goal with notifications enabled is incomplete today
    bool hasIncompleteNotifiableGoal = false;
    for (var g in goals) {
      try {
        final notify = (g.notifyUser as bool?) ?? true;
        final completed = (g.isCompletedToday as bool?) ?? false;
        if (notify && !completed) {
          hasIncompleteNotifiableGoal = true;
          break;
        }
      } catch (_) {}
    }

    if (hasIncompleteNotifiableGoal) {
      await scheduleGoalNotifications();
    } else {
      // Goal is finished or notifications disabled -> no need to notify
      await cancelGoalNotifications();
    }
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDesc,
  }) async {
    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDesc,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Fallback if local notifications scheduling is not supported in test environment
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}