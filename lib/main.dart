import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/ApprovalCutiScreen.dart';
import 'screens/KelolaKaryawanScreen.dart';
import 'screens/ApprovalIzinHarianScreen.dart';
import 'screens/ApprovalIzinJamScreen.dart';
import 'screens/splash_screen.dart';
import 'package:intl/intl.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi NotificationService
  await NotificationService.initialize();

  // Jadwalkan notifikasi harian
  await NotificationService.scheduleDailyAbsenReminders();

  // Mulai timer untuk pengecekan status absen
  NotificationService.startDailyCheckTimer();

  // Mulai background service
  await BackgroundService.startBackgroundService();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modern Login App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/approval-cuti': (context) => const ApprovalCutiScreen(),
        '/kelola-karyawan': (context) => const KelolaKaryawanScreen(),
        '/approval-izin-harian': (context) => const ApprovalIzinHarianScreen(),
        '/approval-izin-jam': (context) => const ApprovalIzinJamScreen(),
      },
    );
  }
}

class NotificationDemoScreen extends StatefulWidget {
  @override
  _NotificationDemoScreenState createState() => _NotificationDemoScreenState();
}

class _NotificationDemoScreenState extends State<NotificationDemoScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await NotificationService.hasNotificationPermission();
    if (!hasPermission) {
      await NotificationService.requestNotificationPermission();
    }
  }

  Future<void> _testAbsenMasuk() async {
    await NotificationService.updateAbsenStatus(
      sudahMasuk: true,
      sudahKeluar: false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status absen masuk diperbarui!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _testAbsenKeluar() async {
    await NotificationService.updateAbsenStatus(
      sudahMasuk: true,
      sudahKeluar: true,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status absen keluar diperbarui!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _resetAbsenStatus() async {
    await NotificationService.updateAbsenStatus(
      sudahMasuk: false,
      sudahKeluar: false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status absen direset!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Notifications Demo'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notifikasi Sederhana
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Notifikasi Sederhana',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        _notificationService.showSimpleNotification(
                          title: 'Notifikasi Sederhana',
                          body: 'Ini adalah notifikasi sederhana yang muncul di latar belakang!',
                          payload: 'simple_notification',
                        );
                      },
                      child: Text('Tampilkan Notifikasi Sederhana'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Notifikasi dengan Aksi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Notifikasi dengan Aksi',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        _notificationService.showActionNotification(
                          title: 'Notifikasi dengan Aksi',
                          body: 'Notifikasi ini memiliki tombol aksi',
                          payload: 'action_notification',
                        );
                      },
                      child: Text('Notifikasi dengan Tombol Aksi'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Notifikasi Terjadwal
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Notifikasi Terjadwal',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        final scheduledDate = DateTime.now().add(Duration(seconds: 5));
                        _notificationService.scheduleNotification(
                          id: 100,
                          title: 'Notifikasi Terjadwal',
                          body: 'Notifikasi ini dijadwalkan 5 detik dari sekarang',
                          scheduledDate: scheduledDate,
                          payload: 'scheduled_notification',
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Notifikasi dijadwalkan dalam 5 detik'),
                          ),
                        );
                      },
                      child: Text('Jadwalkan Notifikasi (5 detik)'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Notifikasi Berulang
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Notifikasi Berulang',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        _notificationService.showRepeatingNotification(
                          id: 200,
                          title: 'Notifikasi Berulang',
                          body: 'Notifikasi ini akan muncul setiap menit',
                          repeatInterval: RepeatInterval.everyMinute,
                          payload: 'repeating_notification',
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Notifikasi berulang dimulai'),
                          ),
                        );
                      },
                      child: Text('Mulai Notifikasi Berulang'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Test Absen Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Test Absen Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _testAbsenMasuk,
                            child: Text('Absen Masuk'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _testAbsenKeluar,
                            child: Text('Absen Keluar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _resetAbsenStatus,
                      child: Text('Reset Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Cancel Notifications
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Batalkan Notifikasi',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await NotificationService.cancelAllNotifications();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Semua notifikasi dibatalkan'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                      child: Text('Batalkan Semua Notifikasi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Status Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Status Aplikasi',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    FutureBuilder<bool>(
                      future: NotificationService.hasNotificationPermission(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        return Row(
                          children: [
                            Icon(
                              snapshot.data == true
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: snapshot.data == true
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              snapshot.data == true
                                  ? 'Izin Notifikasi: Diizinkan'
                                  : 'Izin Notifikasi: Tidak Diizinkan',
                              style: TextStyle(
                                color: snapshot.data == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Waktu Sekarang: ${DateFormat('HH:mm:ss - dd/MM/yyyy').format(DateTime.now())}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),

            // Back to Home Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              icon: Icon(Icons.home),
              label: Text('Kembali ke Beranda'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}