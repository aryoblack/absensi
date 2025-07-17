import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/location_checker.dart';
import '../widgets/success_istirahat_dialog.dart';
import 'absen_reminder_setup.dart';
import 'cuti_screen.dart';
import 'izin_jam_screen.dart';
import 'izin_harian_screen.dart';
import 'AbsenHistoryScreen.dart';
import 'absen_screen.dart';
import 'gaji_screen.dart';
import 'profile_screen.dart';
import 'kunjungan_dinas_screen.dart';
import 'upload_dokumen_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _checking = false;
  String? _status;
  String? token;
  String? name;
  String? role;
  String? waktuMasuk;
  String? waktuKeluar;
  String? waktuIstirahat;
  bool sudahMasuk = false;
  bool sudahKeluar = false;
  bool sudahIstirahat = false;
  bool loading = true;
  double? latkantor;
  double? lngkantor;
  double? maxradius;
  bool _showFAB = true;
  String? profileImageUrl;
  // Tambahan untuk countdown istirahat
  bool sedangIstirahat = false;
  DateTime? waktuMulaiIstirahat;
  Timer? istirahatTimer;
  Duration sisaWaktuIstirahat = Duration.zero;
  static const Duration durasiIstirahat = Duration(hours: 1);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int sisaCutiTahunan = 0;
  String? grade;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _loadUserData();
    fetchLastAbsen();
    _checkIstirahatStatus();
    _animationController.forward();

    // Initialize notification service
    _initializeNotifications();

    // Start daily check timer
    NotificationService.startDailyCheckTimer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    istirahatTimer?.cancel();
    // Stop notification timer
    NotificationService.stopDailyCheckTimer();
    super.dispose();
  }

  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final _token = prefs.getString('token');
    if (_token != null) {
      final response = await ApiService().getSisaCuti(_token);
      sisaCutiTahunan = response['data']['sisa_cuti_tahunan']! ?? 12;
      grade = response['data']['grade']! ?? 'Grade';
      print('Cek sisaCutiTahunan : $sisaCutiTahunan');
    }
    setState(() {
      token = prefs.getString('token');
      name = prefs.getString('nama') ?? 'User';
      role = prefs.getString('role') ?? 'user';
      latkantor = double.parse(prefs.getString('latitude') ?? '0');
      lngkantor = double.parse(prefs.getString('longitude') ?? '0');
      maxradius = double.parse(prefs.getString('radius_meter') ?? '0');
      profileImageUrl = prefs.getString('profile_image')! ??
          "https://app.unchu.id/assets/media/upload/avatar-1.png";

    });



  }

  // Method untuk mengecek status istirahat dari SharedPreferences
  void _checkIstirahatStatus() async {

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? waktuIstirahatStr = prefs.getString('waktu_mulai_istirahat');

      final response = await ApiService.getIstirahat(token!);
      if (response['status'] == true) {
        waktuIstirahatStr = response['data']['waktu'];
      }

    if (waktuIstirahatStr != null) {
      DateTime waktuMulai = DateTime.parse(waktuIstirahatStr);
      DateTime sekarang = DateTime.now();
      Duration selisih = sekarang.difference(waktuMulai);

      // Cek apakah masih dalam periode istirahat (1 jam)
      if (selisih < durasiIstirahat) {
        setState(() {
          sedangIstirahat = true;
          waktuMulaiIstirahat = waktuMulai;
          sisaWaktuIstirahat = durasiIstirahat - selisih;
        });
        _startIstirahatTimer();
      } else {
        // Hapus data istirahat jika sudah lewat 1 jam
        await prefs.remove('waktu_mulai_istirahat');
      }
    }
  }
  void _initializeNotifications() async {
    await NotificationService.initialize();

    // Check if user has notification permission
    final hasPermission = await NotificationService.hasNotificationPermission();
    if (!hasPermission) {
      _showNotificationPermissionDialog();
    } else {
      // Schedule daily reminders
      await NotificationService.scheduleDailyAbsenReminders();
    }
  }

  void _showNotificationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izin Notifikasi'),
        content: const Text(
            'Aplikasi membutuhkan izin notifikasi untuk mengingatkan Anda tentang waktu absen. Apakah Anda ingin mengaktifkan notifikasi?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final granted = await NotificationService.requestNotificationPermission();
              if (granted) {
                await NotificationService.scheduleDailyAbsenReminders();
                _showSuccessSnackBar('Notifikasi pengingat telah diaktifkan');
              }
            },
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
  }
  // Method untuk memulai timer countdown istirahat
  void _startIstirahatTimer() {
    istirahatTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (waktuMulaiIstirahat != null) {
        DateTime sekarang = DateTime.now();
        Duration berlalu = sekarang.difference(waktuMulaiIstirahat!);
        Duration sisa = durasiIstirahat - berlalu;

        if (sisa.isNegative || sisa == Duration.zero) {
          // Istirahat selesai
          setState(() {
            sedangIstirahat = false;
            waktuMulaiIstirahat = null;
            sisaWaktuIstirahat = Duration.zero;
          });
          timer.cancel();
          _removeIstirahatFromStorage();
          _showIstirahatSelesaiSnackBar();
        } else {
          setState(() {
            sisaWaktuIstirahat = sisa;
          });
        }
      }
    });
  }

  // Method untuk menghapus data istirahat dari storage
  void _removeIstirahatFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('waktu_mulai_istirahat');
  }

  // Method untuk menampilkan notifikasi istirahat selesai
  void _showIstirahatSelesaiSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(child: Text('Waktu istirahat Anda telah selesai!')),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  DateTime? _parseDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return null;
    }

    try {
      // Format dari API: "2025-07-01 16:34:13"
      // Coba parse langsung terlebih dahulu
      DateTime parsedDate = DateTime.parse(dateTimeString);
      return parsedDate;
    } catch (e) {
      try {
        // Jika gagal, coba dengan mengganti spasi dengan T
        String isoFormat = dateTimeString.replaceFirst(' ', 'T');
        DateTime parsedDate = DateTime.parse(isoFormat);
        return parsedDate;
      } catch (e2) {
        try {
          // Jika masih gagal, coba dengan DateFormat
          DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
          DateTime parsedDate = formatter.parse(dateTimeString);
          return parsedDate;
        } catch (e3) {
          print('Error parsing datetime: $dateTimeString, Errors: $e, $e2, $e3');
          return null;
        }
      }
    }
  }


  Future<void> fetchLastAbsen() async {
    setState(() {
      _status = null;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    final response = await ApiService.getLastAbsen(token!);

    if (response['status'] == true && response['data'] != null) {
      final data = response['data'] as List<dynamic>;
      for (var absen in data) {
        final status = absen['status'];
        final waktu = absen['waktu'];
        DateTime? absenDate = _parseDateTime(waktu.toString());
        final now = DateTime.now();
        final sameDay = absenDate?.year == now.year && absenDate?.month == now.month && absenDate?.day == now.day;

        if (sameDay) {
          if (status == 'Masuk') {
            sudahMasuk = true;
            waktuMasuk = waktu;
          } else if (status == 'Pulang') {
            sudahKeluar = true;
            waktuKeluar = waktu;
          } else if (status == 'Istirahat') {
            sudahIstirahat = true;
            waktuIstirahat = waktu;
          }
        }
      }
      // await NotificationService.updateAbsenStatus(
      //   sudahMasuk: sudahMasuk,
      //   sudahKeluar: sudahKeluar,
      // );
    }
    setState(() {});
  }

  void _absen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AbsenSelfieScreen()),
    );

    if (result == 'success') {
      fetchLastAbsen();

      if (!sudahMasuk) {
        _showSuccessSnackBar('Absen masuk berhasil! Selamat bekerja 💪');
      } else if (!sudahKeluar) {
        _showSuccessSnackBar('Absen keluar berhasil! Selamat beristirahat 🌙');
      }
    }
  }

  void _istirahat() {
    if (!sudahMasuk) {
      _showErrorSnackBar('Anda harus absen masuk terlebih dahulu');
      return;
    }

    if (sudahIstirahat) {
      _showWarningSnackBar('Anda sudah melakukan istirahat hari ini');
      return;
    }

    if (sedangIstirahat) {
      _showWarningSnackBar('Anda sedang dalam periode istirahat');
      return;
    }
    if (sudahMasuk && sudahKeluar) {
      _showErrorSnackBar('Anda sudah melakukan absen masuk dan pulang');
      return;
    }
    _confirmIstirahat();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  void _confirmIstirahat() {
    showDialog(
      context: context,
      builder: (_) => LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20)
            ),
            insetPadding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.1,
            ),
            contentPadding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            titlePadding: EdgeInsets.fromLTRB(
              isSmallScreen ? 16.0 : 24.0,
              isSmallScreen ? 16.0 : 24.0,
              isSmallScreen ? 16.0 : 24.0,
              8.0,
            ),
            actionsPadding: EdgeInsets.fromLTRB(
              isSmallScreen ? 16.0 : 24.0,
              8.0,
              isSmallScreen ? 16.0 : 24.0,
              isSmallScreen ? 16.0 : 24.0,
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  ),
                  child: Icon(
                    Icons.local_cafe,
                    color: Colors.orange.shade700,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Text(
                    'Konfirmasi Istirahat',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? double.infinity : 400,
              ),
              child: Text(
                'Apakah Anda yakin ingin mulai istirahat?\n\nWaktu istirahat adalah 1 jam.',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  height: 1.4,
                ),
              ),
            ),
            actions: [
              if (isSmallScreen)
              // Stack buttons vertically on small screens
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _submitIstirahat();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Ya, Istirahat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              else
              // Keep buttons horizontal on larger screens
                ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _submitIstirahat();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Ya, Istirahat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
            ],
          );
        },
      ),
    );
  }

  void _submitIstirahat() async {
    setState(() {
      _checking = true;
    });

    try {
      // Simpan waktu mulai istirahat ke SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      DateTime sekarang = DateTime.now();
      await prefs.setString('waktu_mulai_istirahat', sekarang.toIso8601String());

      final String? token = prefs.getString('token');

      final response = await ApiService.submitIstirahat(
        token: '$token',
      );
      print('Cek Response : $response');
      if (response['status'] == true) {
      setState(() {
        _checking = false;
        sedangIstirahat = true;
        waktuMulaiIstirahat = sekarang;
        sisaWaktuIstirahat = durasiIstirahat;
      });

      _startIstirahatTimer();
      SuccessIstirahatDialog.show(context);
      } else {
        setState(() {
          _checking = false;
        });
        _showErrorSnackBar('Terjadi kesalahan saat mencatat istirahat');
      }

    } catch (e) {
      setState(() {
        _checking = false;
      });
      _showErrorSnackBar('Terjadi kesalahan saat mencatat istirahat');
    }
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
          (Route<dynamic> route) => false,
    );
  }
// Method untuk mengecek apakah perlu menampilkan FAB
  bool _shouldShowFAB() {
    final now = DateTime.now();
    final hour = now.hour;

    // Tampilkan FAB jika:
    // 1. Jam kerja (08:00 - 17:00)
    // 2. Belum absen masuk DAN bukan sedang istirahat
    // 3. Sudah absen masuk tapi belum pulang DAN bukan sedang istirahat
    if (hour >= 8 && hour <= 17) {
      if (!sudahMasuk && !sedangIstirahat) {
        return true; // Belum absen masuk
      } else if (sudahMasuk && !sudahKeluar && !sedangIstirahat) {
        return true; // Sudah masuk tapi belum pulang
      }
    }
    return true;
  }

// Method untuk mendapatkan teks FAB
  String _getFABText() {
    if (!sudahMasuk) {
      return 'Absen Masuk';
    } else if (sudahMasuk && !sudahKeluar) {
      return 'Absen Pulang';
    }
    return 'Absen';
  }

// Method untuk mendapatkan icon FAB
  IconData _getFABIcon() {
    if (!sudahMasuk) {
      return Icons.login;
    } else if (sudahMasuk && !sudahKeluar) {
      return Icons.logout;
    }
    return Icons.camera_alt;
  }
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20)
            ),
            insetPadding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.1,
            ),
            contentPadding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            titlePadding: EdgeInsets.fromLTRB(
              isSmallScreen ? 16.0 : 24.0,
              isSmallScreen ? 16.0 : 24.0,
              isSmallScreen ? 16.0 : 24.0,
              8.0,
            ),
            actionsPadding: EdgeInsets.fromLTRB(
              isSmallScreen ? 16.0 : 24.0,
              8.0,
              isSmallScreen ? 16.0 : 24.0,
              isSmallScreen ? 16.0 : 24.0,
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  ),
                  child: Icon(
                    Icons.logout,
                    color: Colors.red.shade700,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Text(
                    'Konfirmasi Logout',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? double.infinity : 400,
              ),
              child: Text(
                'Yakin ingin keluar dari aplikasi?',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  height: 1.4,
                ),
              ),
            ),
            actions: [
              if (isSmallScreen)
              // Stack buttons vertically on small screens
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              else
              // Keep buttons horizontal on larger screens
                ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
            ],
          );
        },
      ),
    );
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.exit_to_app, color: Colors.orange.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Keluar Aplikasi'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
              SystemNavigator.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  // Widget untuk menampilkan warning istirahat
  Widget _buildIstirahatWarning() {
    if (!sedangIstirahat) return const SizedBox.shrink();

    int jam = sisaWaktuIstirahat.inHours;
    int menit = sisaWaktuIstirahat.inMinutes.remainder(60);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade400,
            Colors.orange.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_cafe,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sedang Istirahat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '1 Jam',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Selesai Istirahat: ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${jam}j ${menit}m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.shade400,
            Colors.teal.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Company Logo and Name Section
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Company Logo
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/company_logo.png', // Replace with your logo path
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Company Name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PT. UNCHU INDONESIA GROUP', // Replace with your company name
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'TUMBUH BERMANFAAT LUAR BIASA',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // User Greeting Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.waving_hand, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat ${_getGreeting()}!',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        name ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    DateFormat('dd MMM').format(DateTime.now()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Tiles Section
            Row(
              children: [
                Expanded(child: _buildStatusTile(Icons.login, 'Masuk', sudahMasuk, waktuMasuk)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatusTile(Icons.local_cafe, 'Istirahat', sudahIstirahat || sedangIstirahat, waktuIstirahat)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatusTile(Icons.logout, 'Pulang', sudahKeluar, waktuKeluar)),
              ],
            ),
          ],
        ),
      ),
    );
  }


  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Pagi';
    if (hour < 15) return 'Siang';
    if (hour < 18) return 'Sore';
    return 'Malam';
  }

  Widget _buildStatusTile(IconData icon, String label, bool status, String? time) {


    // Calculate display time and active state
    final isActive = status || (sedangIstirahat && label == 'Istirahat');
    final displayTime = _getDisplayTime(status, time, label);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconContainer(icon, isActive),
          const SizedBox(height: 6),
          _buildTimeText(displayTime, isActive),
          const SizedBox(height: 2),
          _buildLabelText(label),
        ],
      ),
    );
  }

  Widget _buildIconContainer(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 18,
        color: isActive ? Colors.green.shade300 : Colors.white60,
      ),
    );
  }

  Widget _buildTimeText(String displayTime, bool isActive) {
    return Text(
      displayTime,
      style: TextStyle(
        color: isActive ? Colors.green.shade300 : Colors.white60,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  Widget _buildLabelText(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 10,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  String _getDisplayTime(bool status, String? time, String label) {
    if (status && time != null && time != 'null' && time.isNotEmpty) {
      try {
        // Parse waktu dari string
        DateTime? parsedTime = _parseDateTime(time);
        if (parsedTime != null) {
          return DateFormat('HH:mm:ss').format(parsedTime);
        } else {
          print('Failed to parse time for display: $time');
          return '--:--';
        }
      } catch (e) {
        print('Error formatting time for display: $e, time: $time');
        return '--:--';
      }
    }

    if (sedangIstirahat && label == 'Istirahat' && waktuMulaiIstirahat != null) {
      return DateFormat('HH:mm:ss').format(waktuMulaiIstirahat!);
    }

    return '--:--';
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap, {Color? iconColor, Color? backgroundColor}) {
    // Cek apakah sedang istirahat dan bukan menu logout
    bool isDisabled = sedangIstirahat && label != 'Logout';

    return Container(
      decoration: BoxDecoration(
        color: isDisabled
            ? Colors.grey.shade200
            : (backgroundColor ?? Colors.white),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDisabled
            ? []
            : [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? () => _showIstirahatActiveWarning() : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? Colors.grey.withOpacity(0.3)
                        : (iconColor ?? Colors.teal).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Icon(
                        icon,
                        size: 24,
                        color: isDisabled
                            ? Colors.grey.shade500
                            : (iconColor ?? Colors.teal),
                      ),
                      if (isDisabled && label != 'Logout')
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.block,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: isDisabled
                          ? Colors.grey.shade500
                          : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _showIstirahatActiveWarning() {
    int jam = sisaWaktuIstirahat.inHours;
    int menit = sisaWaktuIstirahat.inMinutes.remainder(60);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.local_cafe, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sedang dalam periode istirahat',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Menu akan aktif kembali dalam ${jam}j ${menit}m',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  @override
  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    String imageUrl = profileImageUrl!;

    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.camera_alt,
        'label': 'Absen',
        'onTap': _absen,
        'color': Colors.blue,
        'bgColor': Colors.blue.shade50,
      },
      {
        'icon': Icons.local_cafe,
        'label': 'Istirahat',
        'onTap': _istirahat,
        'color': Colors.orange,
        'bgColor': Colors.orange.shade50,
      },
      {
        'icon': Icons.event_busy,
        'label': 'Cuti',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CutiScreen())),
        'color': Colors.purple,
        'bgColor': Colors.purple.shade50,
      },
      {
        'icon': Icons.access_time,
        'label': 'Izin Jam',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IzinJamList())),
        'color': Colors.indigo,
        'bgColor': Colors.indigo.shade50,
      },
      {
        'icon': Icons.assignment,
        'label': 'Izin Hari',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IzinHarianList())),
        'color': Colors.green,
        'bgColor': Colors.green.shade50,
      },
      {
        'icon': Icons.business_center,
        'label': 'Kunjungan Dinas',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KunjunganDinasScreen())),
        'color': Colors.teal,
        'bgColor': Colors.teal.shade50,
      },
      {
        'icon': Icons.upload_file,
        'label': 'Upload Dokumen',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadDokumenScreen())),
        'color': Colors.brown,
        'bgColor': Colors.brown.shade50,
      },
      {
        'icon': Icons.assignment,
        'label': 'Gaji',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => SlipGajiScreen())),
        'color': Colors.cyanAccent,
        'bgColor': Colors.green.shade50,
      },
    ];

    if (role == 'admin') {
      menuItems.addAll([
        {
          'icon': Icons.approval,
          'label': 'Approval Cuti',
          'onTap': () => Navigator.pushNamed(context, '/approval-cuti'),
          'color': Colors.deepPurple,
          'bgColor': Colors.deepPurple.shade50,
        },
        {
          'icon': Icons.approval,
          'label': 'Approval Izin Hari',
          'onTap': () => Navigator.pushNamed(context, '/approval-izin-harian'),
          'color': Colors.pink,
          'bgColor': Colors.pink.shade50,
        },
        {
          'icon': Icons.approval,
          'label': 'Approval Izin Jam',
          'onTap': () => Navigator.pushNamed(context, '/approval-izin-jam'),
          'color': Colors.cyan,
          'bgColor': Colors.cyan.shade50,
        },
        {
          'icon': Icons.supervised_user_circle,
          'label': 'Kelola Karyawan',
          'onTap': () => Navigator.pushNamed(context, '/kelola-karyawan'),
          'color': Colors.brown,
          'bgColor': Colors.brown.shade50,
        },
      ]);
    }

    menuItems.addAll([
      {
        'icon': Icons.history,
        'label': 'Riwayat Absen',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbsenHistoryScreen())),
        'color': Colors.teal,
        'bgColor': Colors.teal.shade50,
      },
      {
        'icon': Icons.logout,
        'label': 'Logout',
        'onTap': _confirmLogout,
        'color': Colors.red,
        'bgColor': Colors.red.shade50,
      }
    ]);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Absensi Karyawan'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile Avatar with PopupMenu
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.teal.shade200, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(imageUrl),
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'logout') {
                            _confirmLogout();
                          } else if (value == 'profile') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          } else if (value == 'notif') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AbsenReminderScreen()),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 20, color: Colors.teal),
                                SizedBox(width: 8),
                                Text('Profil'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'notif',
                            child: Row(
                              children: [
                                Icon(Icons.notifications, size: 20, color: Colors.amber),
                                SizedBox(width: 8),
                                Text('Notifikasi'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Logout'),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.teal.shade200, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.teal,
                                    size: 18,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Info badges in a row, centered below avatar
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.teal.shade200, width: 0.5),
                        ),
                        child: Text(
                          'Kuota Cuti: ${sisaCutiTahunan ?? 0}',
                          style: TextStyle(
                            color: Colors.teal.shade700,
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.teal.shade200, width: 0.5),
                        ),
                        child: Text(
                          '${grade ?? 'Grade'}',
                          style: TextStyle(
                            color: Colors.teal.shade700,
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        body: _checking
            ? Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.teal.shade50, Colors.white],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
                SizedBox(height: 16),
                Text(
                  'Memproses...',
                  style: TextStyle(
                    color: Colors.teal,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        )
            : Stack(
          children: [
            RefreshIndicator(
              onRefresh: fetchLastAbsen,
              color: Colors.teal,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildStatusCard(),
                        _buildIstirahatWarning(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Menu Utama',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (sedangIstirahat) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.orange.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.block, size: 12, color: Colors.orange.shade700),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Menu Dinonaktifkan',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                itemCount: menuItems.length,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isTablet ? 4 : 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: isTablet ? 1.0 : 0.95,
                                ),
                                itemBuilder: (_, index) {
                                  final item = menuItems[index];
                                  return AnimatedContainer(
                                    duration: Duration(milliseconds: 200 + (index * 30)),
                                    child: _buildMenuItem(
                                      item['icon'],
                                      item['label'],
                                      item['onTap'],
                                      iconColor: item['color'],
                                      backgroundColor: item['bgColor'],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton:  _showFAB
            ? Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _absen,
            backgroundColor: sudahMasuk
                ? Colors.green
                : sudahKeluar
                ? Colors.red
                : Colors.teal,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: Icon(_getFABIcon(), size: 20),
            label: Text(
              _getFABText(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );

  }
  // Optional: Method untuk menyembunyikan FAB sementara
  void _hideFABTemporarily() {
    setState(() {
      _showFAB = false;
    });

    // Tampilkan kembali setelah 10 detik
    Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showFAB = true;
        });
      }
    });
  }
}