// Cara menggunakan NotificationService untuk set notifikasi jam 7:30

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
class AbsenReminderSetup {

  // Method untuk setup notifikasi absen harian
  static Future<void> setupAbsenReminder() async {
    try {
      // Inisialisasi NotificationService
      await NotificationService.initialize();

      // Setup notifikasi harian untuk absen
      await NotificationService.scheduleDailyAbsenReminders();

      print('Notifikasi absen berhasil diatur!');
      print('Pengingat akan muncul setiap hari jam 7:30');

    } catch (e) {
      print('Error setting up absen reminder: $e');
    }
  }

  // Method untuk setup notifikasi custom jam 7:30
  static Future<void> setupCustomAbsenReminder() async {
    try {
      await NotificationService.initialize();

      // Buat notifikasi khusus jam 7:30
      final notificationService = NotificationService();

      // Hitung waktu next 7:30 AM
      final now = DateTime.now();
      var scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        7, // jam
        30, // menit
      );

      // Jika sudah lewat jam 7:30 hari ini, jadwalkan untuk besok
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      // Schedule notifikasi
      await notificationService.scheduleNotification(
        id: 100,
        title: 'Pengingat Absen',
        body: 'Selamat pagi! Jangan lupa absen masuk hari ini 🌅',
        scheduledDate: scheduledTime,
        payload: 'absen_masuk',
      );

      print('Notifikasi custom jam 7:30 berhasil diatur!');
      print('Notifikasi akan muncul pada: ${scheduledTime.toString()}');

    } catch (e) {
      print('Error setting up custom reminder: $e');
    }
  }

  // Method untuk setup notifikasi berulang setiap hari jam 7:30
  static Future<void> setupDailyAbsenReminder() async {
    try {
      await NotificationService.initialize();

      final notificationService = NotificationService();

      // Setup notifikasi berulang harian
      await notificationService.showRepeatingNotification(
        id: 200,
        title: 'Pengingat Absen Harian',
        body: 'Waktu absen masuk! Semangat bekerja hari ini 💪',
        repeatInterval: RepeatInterval.daily,
        payload: 'absen_masuk',
      );

      print('Notifikasi harian berhasil diatur!');

    } catch (e) {
      print('Error setting up daily reminder: $e');
    }
  }

  // Method untuk cek status permission dan request jika diperlukan
  static Future<bool> checkAndRequestPermission() async {
    try {
      final hasPermission = await NotificationService.hasNotificationPermission();

      if (!hasPermission) {
        print('Meminta izin notifikasi...');
        final granted = await NotificationService.requestNotificationPermission();

        if (granted) {
          print('Izin notifikasi diberikan');
          return true;
        } else {
          print('Izin notifikasi ditolak');
          return false;
        }
      }

      print('Izin notifikasi sudah ada');
      return true;

    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }

  // Method untuk test notifikasi langsung
  static Future<void> testNotification() async {
    try {
      await NotificationService.initialize();

      final notificationService = NotificationService();

      await notificationService.showSimpleNotification(
        title: 'Test Notifikasi',
        body: 'Ini adalah test notifikasi absen. Notifikasi berfungsi dengan baik! ✅',
        payload: 'test',
      );

      print('Test notifikasi berhasil dikirim!');

    } catch (e) {
      print('Error sending test notification: $e');
    }
  }
}

// Widget untuk UI setup notifikasi
class AbsenReminderScreen extends StatefulWidget {
  @override
  _AbsenReminderScreenState createState() => _AbsenReminderScreenState();
}

class _AbsenReminderScreenState extends State<AbsenReminderScreen> {
  bool _isPermissionGranted = false;
  String _currentTimezone = '';

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _getCurrentTimezone();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await AbsenReminderSetup.checkAndRequestPermission();
    setState(() {
      _isPermissionGranted = hasPermission;
    });
  }

  Future<void> _getCurrentTimezone() async {
    try {
      tz.initializeTimeZones(); // ini tidak perlu di-assign
      final String localTimezone = DateTime.now().timeZoneName;
     tz.setLocalLocation(tz.getLocation(localTimezone));

      setState(() {
        _currentTimezone = localTimezone;
      });
    } catch (e) {
      print('Error getting timezone: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Pengingat Absen'),
        backgroundColor: Color(0xFF009688),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _isPermissionGranted ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Notifikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isPermissionGranted ? Icons.check_circle : Icons.cancel,
                          color: _isPermissionGranted ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _isPermissionGranted
                              ? 'Izin notifikasi aktif'
                              : 'Izin notifikasi belum aktif',
                        ),
                      ],
                    ),
                    if (_currentTimezone.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Timezone: $_currentTimezone',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Buttons
            ElevatedButton.icon(
              onPressed: _isPermissionGranted ? () async {
                await AbsenReminderSetup.setupAbsenReminder();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pengingat absen berhasil diatur! 🎉'),
                    backgroundColor: Colors.green,
                  ),
                );
              } : null,
              icon: Icon(Icons.schedule),
              label: Text('Setup Pengingat Absen Harian'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF009688),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isPermissionGranted ? () async {
                await AbsenReminderSetup.setupCustomAbsenReminder();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pengingat jam 7:30 berhasil diatur! ⏰'),
                    backgroundColor: Colors.green,
                  ),
                );
              } : null,
              icon: Icon(Icons.access_time),
              label: Text('Setup Pengingat Jam 7:30'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF009688),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () async {
                await AbsenReminderSetup.testNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Test notifikasi dikirim! 📱'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              icon: Icon(Icons.send),
              label: Text('Test Notifikasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () async {
                await NotificationService.cancelAllNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Semua notifikasi dibatalkan'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              icon: Icon(Icons.cancel),
              label: Text('Batalkan Semua Notifikasi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            if (!_isPermissionGranted) ...[
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _checkPermission,
                icon: Icon(Icons.refresh),
                label: Text('Cek Ulang Izin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],

            SizedBox(height: 20),

            // Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Notifikasi akan muncul setiap hari jam 7:30\n'
                          '• Pastikan izin notifikasi sudah diaktifkan\n'
                          '• Notifikasi akan tetap berjalan meski app ditutup\n'
                          '• Untuk hari kerja (Senin-Jumat) saja',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}