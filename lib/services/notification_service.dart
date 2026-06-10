import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _channelId = 'standup_reminder';
  static const _channelName = '起身提醒';
  static const _channelDesc = '久坐定时提醒你站起来活动';
  static const _notificationId = 100;
  static void Function(String? payload)? onNotificationTap;
  static bool _tzInitialized = false;

  static Future<void> init() async {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true);
    await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: (r) =>
            onNotificationTap?.call(r.payload));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelId, _channelName,
            description: _channelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true));
  }

  static Future<void> scheduleNextReminder(int intervalMinutes) async {
    await _plugin.cancel(_notificationId);
    final now = DateTime.now();
    final nextReminder = now.add(Duration(minutes: intervalMinutes));
    final scheduled = tz.TZDateTime.from(nextReminder, tz.local);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('next_reminder_at', nextReminder.toIso8601String());
    final hints = ['颈部拉伸', '肩部放松', '深蹲几个', '深呼吸', '活动手腕', '站起来走走'];
    await _plugin.zonedSchedule(
        _notificationId,
        '⏰ 该起身活动一下了！',
        '已经坐了 $intervalMinutes 分钟，来做个 ${hints[DateTime.now().millisecond % hints.length]} 吧',
        scheduled,
        const NotificationDetails(
            android: AndroidNotificationDetails('standup_reminder', '起身提醒',
                channelDescription: '久坐定时提醒',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher'),
            iOS: DarwinNotificationDetails(
                presentAlert: true, presentBadge: true, presentSound: true)),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'reminder');
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('next_reminder_at');
  }

  static Future<DateTime?> getNextReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('next_reminder_at');
    return t == null ? null : DateTime.tryParse(t)?.toLocal();
  }

  static Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('reminder_enabled') ?? false;
  }

  static Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', enabled);
  }

  /// Request Android 13+ notification permission. Safe to call on any version.
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true; // not Android
    return (await android.requestNotificationsPermission()) ?? false;
  }
}
