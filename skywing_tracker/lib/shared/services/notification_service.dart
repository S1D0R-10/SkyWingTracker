import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
  }

  Future<void> showFlightStarted(String flightName) async {
    await _plugin.show(
      _idFromString('flight_started_$flightName'),
      'Flight Started',
      '$flightName has been released',
      _defaultDetails(),
    );
  }

  Future<void> showPigeonOverdue(String pigeonName) async {
    await _plugin.show(
      _idFromString('overdue_$pigeonName'),
      'Pigeon Overdue',
      '$pigeonName has not returned yet',
      _defaultDetails(),
    );
  }

  Future<void> scheduleReturnReminder(String flightName, DateTime time) async {
    await _plugin.zonedSchedule(
      _idFromString('reminder_$flightName'),
      'Return Reminder',
      'Check on $flightName',
      tz.TZDateTime.from(time, tz.local),
      _defaultDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  NotificationDetails _defaultDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'skywing_channel',
        'SkyWing Tracker',
        channelDescription: 'Flight and pigeon notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  int _idFromString(String s) => s.hashCode.abs() % 100000;
}
