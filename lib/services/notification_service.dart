import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../models/task_model.dart';
import 'web_notification_bridge.dart' as web_notification;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  Duration _reminderOffset = const Duration(hours: 24);
  late final Future<void> _ready;
  AndroidScheduleMode _scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
  Future<void> _scheduleQueue = Future.value();
  String? _lastScheduleFingerprint;
  final Map<int, Timer> _webTimers = <int, Timer>{};

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _ready = _initialize();
  }

  // Backward-compatible getter for existing UI code.
  int get reminderHours => _reminderOffset.inHours;

  Duration get reminderOffset => _reminderOffset;

  // Backward-compatible setter.
  Future<void> setReminderHours(int hours) async {
    _reminderOffset = Duration(hours: hours);
    print('📢 Reminder set to $hours hours before due date');
  }

  Future<void> setReminderOffset(Duration offset) async {
    if (offset.inMinutes <= 0) {
      throw ArgumentError('Reminder time must be greater than zero');
    }
    _reminderOffset = offset;
    print('📢 Reminder set to ${offset.inMinutes} minute(s) before due date');
  }

  Future<void> _initialize() async {
    tzdata.initializeTimeZones();
    await _configureLocalTimeZone();

    if (kIsWeb) {
      return;
    }

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await _setupNotifications();
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final String timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
      print('🕒 Local timezone set to $timezoneName');
    } catch (e) {
      // Keep default timezone if lookup fails.
      print('⚠️ Failed to set local timezone, fallback to default: $e');
    }
  }

  Future<void> _setupNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {
        print('iOS Notification: $title - $body');
      },
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        print('Notification clicked: ${details.payload}');
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'task_channel',
      'Task Reminders',
      description: 'Notifications for upcoming task deadlines',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Request iOS permissions
    if (DateTime.now().year >= 2020) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  Future<bool> ensureNotificationPermission() async {
    if (kIsWeb) {
      return web_notification.requestPermission();
    }

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      return true;
    }

    final granted = await androidPlugin.requestNotificationsPermission();
    if (granted == false) {
      return false;
    }

    final exactPermission = await androidPlugin.requestExactAlarmsPermission();
    _scheduleMode = exactPermission == true
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    return true;
  }

  /// Schedule notification for task due date
  Future<void> scheduleTaskReminder(TaskModel task) async {
    await _ready;
    final granted = await ensureNotificationPermission();
    if (!granted) return;
    if (task.isNoDeadline) return; // Skip tasks with no deadline

    final notificationId = _toValidNotificationId(task.id.hashCode);

    try {
      // Schedule notification based on user preference
      final now = DateTime.now();
      if (!task.dueDate.isAfter(now)) {
        // Do not auto-push immediate notifications for overdue tasks here,
        // it can look noisy when task streams update.
        return;
      }

      final reminderDuration = _reminderOffset;
      var reminderTime = task.dueDate.subtract(reminderDuration);

      if (!reminderTime.isAfter(now)) {
        // If user sets a long reminder (e.g. 2 days) but task is due sooner,
        // schedule a near-immediate reminder once instead of firing repeatedly.
        reminderTime = now.add(const Duration(seconds: 10));
      }

      if (kIsWeb) {
        _webTimers[notificationId]?.cancel();
        final delay = reminderTime.difference(now);
        _webTimers[notificationId] = Timer(delay, () {
          web_notification.showNotification(
            title: '🔔 Task reminder: ${task.title}',
            body: 'Due in ${_getDaysUntilDue(task.dueDate)}',
          );
          _webTimers.remove(notificationId);
        });
        return;
      }

      final scheduledAt = tz.TZDateTime.from(reminderTime, tz.local);
      final details = const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel',
          'Task Reminders',
          channelDescription: 'Notifications for upcoming task deadlines',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          '🔔 Task reminder: ${task.title}',
          'Due in ${_getDaysUntilDue(task.dueDate)}',
          scheduledAt,
          details,
          androidScheduleMode: _scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: task.id,
        );
      } catch (_) {
        // Fallback for devices that reject exact alarms.
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          '🔔 Task reminder: ${task.title}',
          'Due in ${_getDaysUntilDue(task.dueDate)}',
          scheduledAt,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: task.id,
        );
      }
      print('📅 Scheduled reminder for ${task.title} at $reminderTime');
    } catch (e) {
      print('❌ Error scheduling reminder: $e');
    }
  }

  /// Show immediate notification (for overdue tasks)
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    await _ready;
    final granted = await ensureNotificationPermission();
    if (!granted) return;

    if (kIsWeb) {
      web_notification.showNotification(title: title, body: body);
      return;
    }

    try {
      final safeId = _toValidNotificationId(id);
      await flutterLocalNotificationsPlugin.show(
        safeId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel',
            'Task Reminders',
            channelDescription: 'Notifications for upcoming task deadlines',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  /// Cancel notification for a task
  Future<void> cancelTaskReminder(String taskId) async {
    await _ready;
    final notificationId = _toValidNotificationId(taskId.hashCode);

    if (kIsWeb) {
      _webTimers[notificationId]?.cancel();
      _webTimers.remove(notificationId);
      return;
    }

    try {
      await flutterLocalNotificationsPlugin.cancel(
        notificationId,
      );
      print('🗑️ Cancelled reminder for $taskId');
    } catch (e) {
      print('❌ Error cancelling reminder: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _ready;

    if (kIsWeb) {
      for (final timer in _webTimers.values) {
        timer.cancel();
      }
      _webTimers.clear();
      return;
    }

    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      print('🗑️ Cancelled all notifications');
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }

  /// Schedule notifications for multiple tasks
  Future<void> scheduleAllReminders(List<TaskModel> tasks) async {
    await _ready;
    _scheduleQueue = _scheduleQueue.then((_) async {
      final now = DateTime.now();
      final upcoming = tasks
          .where((task) =>
              task.status == TaskStatus.pending &&
              !task.isNoDeadline &&
              task.dueDate.isAfter(now))
          .toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

      if (upcoming.isEmpty) {
        if (_lastScheduleFingerprint != null) {
          await cancelAllNotifications();
          _lastScheduleFingerprint = null;
        }
        return;
      }

      final fingerprint = [
        _reminderOffset.inMinutes,
        ...upcoming
            .map((task) => '${task.id}|${task.dueDate.toIso8601String()}')
            .toList(),
      ].join('||');

      // Skip re-scheduling if nothing actually changed.
      if (_lastScheduleFingerprint == fingerprint) {
        return;
      }

      await cancelAllNotifications();
      for (final task in upcoming) {
        await scheduleTaskReminder(task);
      }
      _lastScheduleFingerprint = fingerprint;
    });

    await _scheduleQueue;
  }

  /// Helper: Get remaining days until due date
  String _getDaysUntilDue(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    final days = difference.inDays;

    if (days == 0) {
      return 'today';
    } else if (days == 1) {
      return 'tomorrow';
    } else if (days < 0) {
      return '${days.abs()} day(s) overdue';
    } else {
      return '$days day(s)';
    }
  }

  /// Show task submitted notification
  Future<void> showTaskSubmittedNotification(String taskTitle) async {
    await showImmediateNotification(
      id: DateTime.now().millisecondsSinceEpoch.hashCode,
      title: '✅ Task submitted!',
      body: 'You submitted "$taskTitle" successfully',
      payload: 'submitted',
    );
  }

  /// Show sync notification
  Future<void> showSyncNotification(int count) async {
    await showImmediateNotification(
      id: DateTime.now().millisecondsSinceEpoch.hashCode,
      title: '🔄 Classroom sync complete',
      body: 'Updated $count task(s) from Google Classroom',
      payload: 'sync',
    );
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    await _ready;

    if (kIsWeb) {
      return _webTimers.length;
    }

    final pending =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return pending.length;
  }

  int _toValidNotificationId(int rawId) {
    const maxInt32 = 2147483647;
    final normalized = rawId.abs() % maxInt32;
    return normalized == 0 ? 1 : normalized;
  }
}
