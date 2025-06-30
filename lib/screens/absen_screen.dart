import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AbsenSelfieScreen extends StatefulWidget {
  const AbsenSelfieScreen({super.key});

  @override
  State<AbsenSelfieScreen> createState() => _AbsenSelfieScreenState();
}

class _AbsenSelfieScreenState extends State<AbsenSelfieScreen> {
  File? _imageFile;
  String _location = 'Mengambil lokasi...';
  bool _loading = false;
  double? latkantor;
  double? lngkantor;
  double? maxradius;
  String? token;
  late DateTime _currentTime;

  // Tambahan variabel untuk status dan pengecekan
  String? _status;
  // bool _checking = false;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _loadOfficeCoordinates();
    _getCurrentLocation();
  }

  String get currentDate => DateFormat().format(_currentTime);
  String get currentTimeFormatted => DateFormat('HH:mm:ss').format(_currentTime);

  Future<void> _loadOfficeCoordinates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
      latkantor = double.tryParse(prefs.getString('latitude') ?? '0');
      lngkantor = double.tryParse(prefs.getString('longitude') ?? '0');
      maxradius = double.tryParse(prefs.getString('radius_meter') ?? '0');
    });
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _location = 'Lat: ${position.latitude.toStringAsFixed(5)}, Lon: ${position.longitude.toStringAsFixed(5)}';
    });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _location = 'Layanan lokasi tidak aktif');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() => _location = 'Izin lokasi ditolak');
      return false;
    }
    return true;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submitAbsensi() async {
    if (_imageFile == null || !_imageFile!.existsSync()) {
      _showErrorDialog('Silakan ambil foto terlebih dahulu');
      return;
    }

    if (_location.contains('Mengambil lokasi') || _location.contains('tidak aktif') || _location.contains('ditolak')) {
      _showErrorDialog('Lokasi belum tersedia atau tidak valid');
      return;
    }

    if (latkantor == null || lngkantor == null || maxradius == null) {
      _showErrorDialog('Koordinat kantor tidak ditemukan');
      return;
    }

    setState(() => _loading = true);

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final double lat = position.latitude;
      final double lng = position.longitude;

      double distance = Geolocator.distanceBetween(latkantor!, lngkantor!, lat, lng);
      if (distance > maxradius!) {
        setState(() => _loading = false);
        _showErrorDialog('Kamu berada di luar radius absen. Jarakmu: ${distance.toStringAsFixed(2)} meter');
        return;
      }

      final response = await ApiService.absen(token!, File(_imageFile!.path), lat, lng);
      print('Response server: $response');

      if (response['status']) {
        setState(() {
          _status = response['message'];
          _loading = false;
        });
        _showSuccessDialog(distance);
      } else {
        setState(() => _loading = false);
        _showErrorDialog('Gagal: ${response['message']}');
      }

    } catch (e) {
      setState(() => _loading = false);
      _showErrorDialog('Terjadi kesalahan: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(double distance) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Absensi Berhasil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Foto dan lokasi berhasil dikirim.'),
              const SizedBox(height: 10),
              Text('Jarak ke kantor: ${distance.toStringAsFixed(2)} meter'),
              Text('Waktu: $currentTimeFormatted'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context, 'success'); // Kembali ke halaman sebelumnya dengan hasil
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isTablet = screenWidth > 600;
    final isLandscape = screenWidth > screenHeight;

    // Responsive padding dan sizing
    final padding = EdgeInsets.symmetric(
      horizontal: isTablet ? screenWidth * 0.1 : 20,
      vertical: isTablet ? 32 : 16,
    );

    final imageHeight = isLandscape
        ? screenHeight * 0.4
        : isTablet
        ? screenHeight * 0.3
        : screenHeight * 0.25;

    final maxWidth = isTablet ? 600.0 : double.infinity;

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        title: const Text('Absensi Selfie'),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
        elevation: isTablet ? 0 : 4,
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding,
              child: isLandscape && !isTablet
                  ? _buildLandscapeLayout(imageHeight)
                  : _buildPortraitLayout(imageHeight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(double imageHeight) {
    return Column(
      children: [
        _buildTimeSection(),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        _buildStatusSection(),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        _buildImageSection(imageHeight),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        _buildLocationSection(),
        const Spacer(),
        _buildSubmitButton(),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
      ],
    );
  }

  Widget _buildLandscapeLayout(double imageHeight) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeSection(),
              const SizedBox(height: 16),
              _buildStatusSection(),
              const SizedBox(height: 16),
              _buildLocationSection(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _buildImageSection(imageHeight),
        ),
      ],
    );
  }

  Widget _buildTimeSection() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Column(
      children: [
        Text(
          currentDate,
          style: TextStyle(
            fontSize: isTablet ? 20 : 16,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currentTimeFormatted,
          style: TextStyle(
            fontSize: isTablet ? 36 : 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    if (_status == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Status: $_status',
        style: TextStyle(
          color: Colors.green,
          fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 14,
        ),
      ),
    );
  }

  Widget _buildImageSection(double imageHeight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = imageHeight.clamp(200.0, constraints.maxHeight * 0.8);

        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _imageFile != null
                    ? Image.file(
                  _imageFile!,
                  width: double.infinity,
                  height: cardHeight - 60, // Mengurangi tinggi untuk button
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: double.infinity,
                  height: cardHeight - 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: MediaQuery.of(context).size.width > 600 ? 120 : 80,
                    color: Colors.grey,
                  ),
                ),
              ),
              Container(
                height: 60,
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera),
                  label: Text(
                    'Ambil Foto Selfie',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationSection() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Colors.red,
              size: isTablet ? 28 : 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _location,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.refresh,
                size: isTablet ? 28 : 24,
              ),
              onPressed: _getCurrentLocation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return SizedBox(
      width: double.infinity,
      height: isTablet ? 60 : 50,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _submitAbsensi,
        icon: Icon(
          Icons.fingerprint,
          size: isTablet ? 28 : 24,
        ),
        label: _loading
            ? SizedBox(
          height: isTablet ? 28 : 24,
          width: isTablet ? 28 : 24,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          'Absen Sekarang',
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 8,
        ),
      ),
    );
  }
}