import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/location_checker.dart';
import '../widgets/success_istirahat_dialog.dart';
import 'cuti_screen.dart';
import 'izin_jam_screen.dart';
import 'izin_harian_screen.dart';
import 'AbsenHistoryScreen.dart';
import 'absen_screen.dart';
import 'gaji_screen.dart';

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

  // Tambahan untuk countdown istirahat
  bool sedangIstirahat = false;
  DateTime? waktuMulaiIstirahat;
  Timer? istirahatTimer;
  Duration sisaWaktuIstirahat = Duration.zero;
  static const Duration durasiIstirahat = Duration(hours: 1);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    istirahatTimer?.cancel();
    super.dispose();
  }

  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
      name = prefs.getString('nama') ?? 'User';
      role = prefs.getString('role') ?? 'user';
      latkantor = double.parse(prefs.getString('latitude') ?? '0');
      lngkantor = double.parse(prefs.getString('longitude') ?? '0');
      maxradius = double.parse(prefs.getString('radius_meter') ?? '0');
    });
  }

  // Method untuk mengecek status istirahat dari SharedPreferences
  void _checkIstirahatStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? waktuIstirahatStr = prefs.getString('waktu_mulai_istirahat');

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
        print('Cek Waktu :${absen['waktu']}');
        final absenDate = DateTime.parse(waktu);
        final now = DateTime.now();
        final sameDay = absenDate.year == now.year && absenDate.month == now.month && absenDate.day == now.day;

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

  void _confirmIstirahat() {
    showDialog(
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
              child: Icon(Icons.local_cafe, color: Colors.orange.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Konfirmasi Istirahat'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin mulai istirahat?\n\nWaktu istirahat adalah 1 jam.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitIstirahat();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ya, Istirahat', style: TextStyle(color: Colors.white)),
          ),
        ],
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

      setState(() {
        _checking = false;
        sedangIstirahat = true;
        waktuMulaiIstirahat = sekarang;
        sisaWaktuIstirahat = durasiIstirahat;
      });

      _startIstirahatTimer();
      SuccessIstirahatDialog.show(context);

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

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout, color: Colors.red.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Konfirmasi Logout'),
          ],
        ),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: status ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: status ? Colors.green.shade300 : Colors.white60,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            status && time != null ? DateFormat('HH:mm').format(DateTime.parse(time)) :
            (sedangIstirahat && label == 'Istirahat' && waktuMulaiIstirahat != null ?
            DateFormat('HH:mm').format(waktuMulaiIstirahat!) : '--:--'),
            style: TextStyle(
              color: status || (sedangIstirahat && label == 'Istirahat') ? Colors.green.shade300 : Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
    String imageUrl = "https://app.unchu.id/assets/media/upload/avatar-1.png";

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
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.teal.shade200, width: 2),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(imageUrl),
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'logout') {
                        _confirmLogout();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 20),
                            SizedBox(width: 8),
                            Text('Profil'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 20),
                            SizedBox(width: 8),
                            Text('Logout'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
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
      ),
    );
  }
}