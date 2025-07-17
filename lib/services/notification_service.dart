// File: lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../helper/fungsi_time_zone.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static Timer? _dailyCheckTimer;

  // Keep these as static for background service compatibility
  static bool _sudahMasuk = false;
  static bool _sudahKeluar = false;

  // Notification IDs constants for better management
  static const int _morningReminder1Id = 1;
  static const int _morningReminder2Id = 2;
  static const int _eveningReminder1Id = 3;
  static const int _eveningReminder2Id = 4;
  static const int _immediateEarlyReminderId = 10;
  static const int _immediateEveningReminderId = 11;
  static const int _lateReminderId = 12;

  // Initialize notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone data first
      tz.initializeTimeZones();
      String localTimezone = getDeviceTimezone();

      // Set local timezone with better error handling
      await _setTimezone(localTimezone);

      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
    } catch (e) {
      print('Error initializing notification service: $e');
      rethrow;
    }
  }

  // Improved timezone setting with fallback chain
  static Future<void> _setTimezone(String localTimezone) async {
    try {
      tz.setLocalLocation(tz.getLocation(localTimezone));
      print('Timezone set to: $localTimezone');
    } catch (e) {
      print('Error setting timezone $localTimezone: $e');
      try {
        // Try Asia/Jakarta as fallback for Indonesian apps
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
        print('Fallback to Asia/Jakarta timezone');
      } catch (e2) {
        print('Error setting Jakarta timezone: $e2');
        try {
          // Try system timezone
          final String timeZoneName = DateTime.now().timeZoneName;
          tz.setLocalLocation(tz.getLocation(timeZoneName));
          print('Fallback to system timezone: $timeZoneName');
        } catch (e3) {
          print('Error setting system timezone: $e3');
          // Final fallback to UTC
          tz.setLocalLocation(tz.UTC);
          print('Final fallback to UTC timezone');
        }
      }
    }
  }

  // Request notification permissions
  static Future<bool> _requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? grantedNotificationPermission =
        await androidImplementation.requestNotificationsPermission();
        return grantedNotificationPermission ?? false;
      }

      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
      _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        final bool? grantedNotificationPermission =
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return grantedNotificationPermission ?? false;
      }

      return false;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
    switch (response.payload) {
      case 'absen_masuk':
      // Navigate to absen screen for check-in
        break;
      case 'absen_keluar':
      // Navigate to absen screen for check-out
        break;
      case 'action_yes':
      // Handle yes action
        break;
      case 'action_no':
      // Handle no action
        break;
      default:
      // Handle unknown payload
        break;
    }
  }

  // Schedule daily absen reminders
  static Future<void> scheduleDailyAbsenReminders() async {
    if (!_isInitialized) await initialize();

    try {
      // Cancel existing notifications
      await _notifications.cancelAll();

      // Get Jakarta timezone
      final jakarta = tz.getLocation('Asia/Jakarta');

      // Schedule morning reminders
      await _scheduleNotification(
        id: _morningReminder1Id,
        title: 'Pengingat Absen Masuk',
        body: 'Jangan lupa absen masuk hari ini! 🏢',
        scheduledTime: _getNextScheduledTime(7, 30, jakarta),
        payload: 'absen_masuk',
      );

      await _scheduleNotification(
        id: _morningReminder2Id,
        title: 'Pengingat Absen Masuk',
        body: 'Apakah Anda sudah absen masuk? ⏰',
        scheduledTime: _getNextScheduledTime(8, 0, jakarta),
        payload: 'absen_masuk',
      );

      // Schedule evening reminders
      await _scheduleNotification(
        id: _eveningReminder1Id,
        title: 'Pengingat Absen Pulang',
        body: 'Waktunya absen Pulang hari ini! Sampai jumpa besok 👋',
        scheduledTime: _getNextScheduledTime(17, 0, jakarta),
        payload: 'absen_keluar',
      );

      await _scheduleNotification(
        id: _eveningReminder2Id,
        title: 'Pengingat Absen Pulang',
        body: 'Jangan lupa absen keluar sebelum pulang! 🚗',
        scheduledTime: _getNextScheduledTime(17, 30, jakarta),
        payload: 'absen_keluar',
      );

      print('Daily absen reminders scheduled successfully');
    } catch (e) {
      print('Error scheduling daily reminders: $e');
    }
  }

  // Get next scheduled time for notification
  static tz.TZDateTime _getNextScheduledTime(int hour, int minute, tz.Location location) {
    final now = tz.TZDateTime.now(location);
    var scheduledTime = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    print('Current timezone: ${location.name}');
    print('Current time: $now');
    print('Scheduled time: $scheduledTime');

    // If the scheduled time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
      print('Scheduled for tomorrow: $scheduledTime');
    }

    return scheduledTime;
  }

  // Schedule a notification
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
    String? payload,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'absen_reminder_channel',
        'Pengingat Absen',
        channelDescription: 'Notifikasi pengingat untuk absen masuk dan keluar',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF009688),
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      print('Error scheduling notification $id: $e');
    }
  }

  // Improved DateTime parsing with better error handling
  static DateTime? _parseDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return null;
    }

    // List of possible date formats
    final List<String> formats = [
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-ddTHH:mm:ss',
      'yyyy-MM-dd HH:mm:ss.SSS',
      'yyyy-MM-ddTHH:mm:ss.SSS',
      'yyyy-MM-ddTHH:mm:ssZ',
    ];

    for (String format in formats) {
      try {
        if (format.contains('T') && !dateTimeString.contains('T')) {
          continue;
        }

        DateFormat formatter = DateFormat(format);
        return formatter.parse(dateTimeString);
      } catch (e) {
        // Continue to next format
      }
    }

    try {
      // Try direct parsing as last resort
      return DateTime.parse(dateTimeString);
    } catch (e) {
      print('Error parsing datetime: $dateTimeString, Error: $e');
      return null;
    }
  }

  // Check absen status and send immediate reminder if needed
  static Future<void> checkAbsenStatusAndNotify() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final hour = now.hour;

      // Check if it's a weekday (Monday to Friday)
      if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
        return; // Skip notifications on weekends
      }

      // Reset daily flags
      _sudahMasuk = false;
      _sudahKeluar = false;

      // Check absen status from SharedPreferences
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      _sudahMasuk = prefs.getBool('sudah_masuk_$todayStr') ?? false;
      _sudahKeluar = prefs.getBool('sudah_keluar_$todayStr') ?? false;

      // Get fresh data from API
      final token = prefs.getString('token');
      if (token != null) {
        await _updateAbsenStatusFromAPI(token);
      }

      // Send appropriate notifications based on time and status
      await _sendContextualNotifications(hour);
    } catch (e) {
      print('Error checking absen status: $e');
    }
  }

  // Update absen status from API
  static Future<void> _updateAbsenStatusFromAPI(String token) async {
    try {
      final response = await ApiService.getLastAbsen(token);

      if (response['status'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        final now = DateTime.now();

        for (var absen in data) {
          final status = absen['status'];
          final waktu = absen['waktu'];
          DateTime? absenDate = _parseDateTime(waktu.toString());

          if (absenDate != null) {
            final sameDay = absenDate.year == now.year &&
                absenDate.month == now.month &&
                absenDate.day == now.day;

            if (sameDay) {
              if (status == 'Masuk') {
                _sudahMasuk = true;
              } else if (status == 'Pulang') {
                _sudahKeluar = true;
              }
            }
          }
        }

        // Update SharedPreferences
        await updateAbsenStatus(
          sudahMasuk: _sudahMasuk,
          sudahKeluar: _sudahKeluar,
        );
      }
    } catch (e) {
      print('Error updating absen status from API: $e');
    }
  }

  // Send contextual notifications based on time and status
  static Future<void> _sendContextualNotifications(int hour) async {
    try {
      // Morning reminder (05:00 - 08:00)
      if (hour >= 5 && hour <= 8 && !_sudahMasuk) {
        await _showImmediateNotification(
          id: _immediateEarlyReminderId,
          title: 'Pengingat Absen Masuk',
          body: 'Jangan lupa absen masuk! Sudah waktunya bekerja 💪',
          payload: 'absen_masuk',
        );
      }

      // Evening reminder (17:00 - 19:00)
      if (hour >= 17 && hour <= 19 && _sudahMasuk && !_sudahKeluar) {
        await _showImmediateNotification(
          id: _immediateEveningReminderId,
          title: 'Pengingat Absen Keluar',
          body: 'Waktunya absen keluar! Selamat beristirahat 🌙',
          payload: 'absen_keluar',
        );
      }

      // Optional: Late reminder (uncomment if needed)
      if (hour >= 9 && hour <= 12 && !_sudahMasuk) {
        await _showImmediateNotification(
          id: _lateReminderId,
          title: 'Pengingat Absen Masuk - Terlambat',
          body: 'Anda belum absen masuk! Silakan segera absen 🚨',
          payload: 'absen_masuk',
        );
      }
    } catch (e) {
      print('Error sending contextual notifications: $e');
    }
  }

  // Show immediate notification
  static Future<void> _showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'absen_immediate_channel',
        'Pengingat Absen Segera',
        channelDescription: 'Notifikasi pengingat absen yang muncul langsung',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF009688),
        playSound: true,
        enableVibration: true,
        ticker: 'Pengingat Absen',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      print('Error showing immediate notification: $e');
    }
  }

  // ==================== DEMO METHODS ====================

  // Show simple notification
  Future<void> showSimpleNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'simple_channel',
        'Notifikasi Sederhana',
        channelDescription: 'Notifikasi sederhana untuk demo',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF009688),
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      print('Error showing simple notification: $e');
    }
  }

  // Show notification with actions
  Future<void> showActionNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'action_channel',
        'Notifikasi dengan Aksi',
        channelDescription: 'Notifikasi dengan tombol aksi',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF009688),
        playSound: true,
        enableVibration: true,
        actions: [
          AndroidNotificationAction(
            'action_yes',
            'Ya',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          AndroidNotificationAction(
            'action_no',
            'Tidak',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        ],
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      print('Error showing action notification: $e');
    }
  }

  // Schedule notification (for demo)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'scheduled_channel',
        'Notifikasi Terjadwal',
        channelDescription: 'Notifikasi yang dijadwalkan',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF009688),
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTZDate,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // Show repeating notification
  Future<void> showRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required RepeatInterval repeatInterval,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'repeating_channel',
        'Notifikasi Berulang',
        channelDescription: 'Notifikasi yang berulang',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF009688),
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.periodicallyShow(
        id,
        title,
        body,
        repeatInterval,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      print('Error showing repeating notification: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

  // Start daily check timer
  static void startDailyCheckTimer() {
    _dailyCheckTimer?.cancel();
    _dailyCheckTimer = Timer.periodic(
      const Duration(hours: 1), // Check every hour
          (timer) async {
        try {
          await checkAbsenStatusAndNotify();
        } catch (e) {
          print('Error in daily check timer: $e');
        }
      },
    );
  }

  // Stop daily check timer
  static void stopDailyCheckTimer() {
    _dailyCheckTimer?.cancel();
    _dailyCheckTimer = null;
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      print('Error canceling all notifications: $e');
    }
  }

  // Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      print('Error canceling notification $id: $e');
    }
  }

  // Update absen status in SharedPreferences
  static Future<void> updateAbsenStatus({
    required bool sudahMasuk,
    required bool sudahKeluar,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await prefs.setBool('sudah_masuk_$todayStr', sudahMasuk);
      await prefs.setBool('sudah_keluar_$todayStr', sudahKeluar);

      // Cancel relevant notifications if absen is done
      if (sudahMasuk) {
        await cancelNotification(_morningReminder1Id);
        await cancelNotification(_morningReminder2Id);
        await cancelNotification(_immediateEarlyReminderId);
        await cancelNotification(_lateReminderId);
      }

      if (sudahKeluar) {
        await cancelNotification(_eveningReminder1Id);
        await cancelNotification(_eveningReminder2Id);
        await cancelNotification(_immediateEveningReminderId);
      }
    } catch (e) {
      print('Error updating absen status: $e');
    }
  }

  // Get notification permission status
  static Future<bool> hasNotificationPermission() async {
    if (!_isInitialized) await initialize();

    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.areNotificationsEnabled();
        return granted ?? false;
      }

      return true; // Assume granted for iOS
    } catch (e) {
      print('Error checking notification permission: $e');
      return false;
    }
  }

  // Show notification permission dialog
  static Future<bool> requestNotificationPermission() async {
    try {
      final hasPermission = await hasNotificationPermission();
      if (hasPermission) return true;

      return await _requestPermissions();
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }

  // Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }

  // Clear all stored absen status (for testing)
  static Future<void> clearAbsenStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) =>
      key.startsWith('sudah_masuk_') || key.startsWith('sudah_keluar_'));

      for (String key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Error clearing absen status: $e');
    }
  }
}