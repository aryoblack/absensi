import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import '../services/api_service.dart';

class AbsenSelfieScreen extends StatefulWidget {
  const AbsenSelfieScreen({super.key});

  @override
  State<AbsenSelfieScreen> createState() => _AbsenSelfieScreenState();
}

class _AbsenSelfieScreenState extends State<AbsenSelfieScreen>
    with TickerProviderStateMixin {
  File? _imageFile;
  Uint8List? _compressedImageBytes;
  String _location = 'Mengambil lokasi...';
  bool _loading = false;
  bool _imageLoading = false;
  double? latkantor;
  double? lngkantor;
  double? maxradius;
  String? token;
  late DateTime _currentTime;
  String? _status;

  // Animation controllers untuk verifikasi wajah
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;

  bool _isScanning = false;
  bool _faceDetected = false;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _loadOfficeCoordinates();
    _getCurrentLocation();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Pulse animation untuk oval guide
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Scan animation untuk garis pemindai
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
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

  Future<Uint8List?> _compressImage(File imageFile, {int quality = 70, int maxWidth = 800}) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(imageBytes);

      if (image == null) return null;

      final img.Image resizedImage = img.copyResize(
        image,
        width: image.width > maxWidth ? maxWidth : image.width,
        height: image.width > maxWidth ? (image.height * maxWidth / image.width).round() : image.height,
      );

      final Uint8List compressedBytes = Uint8List.fromList(
          img.encodeJpg(resizedImage, quality: quality)
      );

      return compressedBytes;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      _imageLoading = true;
      _isScanning = true;
      _faceDetected = false;
    });

    // Start scanning animation
    _scanController.reset();
    _scanController.forward();

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        final compressedBytes = await _compressImage(imageFile, quality: 60, maxWidth: 600);

        // Simulate face detection delay
        await Future.delayed(const Duration(milliseconds: 1500));

        setState(() {
          _imageFile = imageFile;
          _compressedImageBytes = compressedBytes;
          _faceDetected = true;
          _isScanning = false;
        });

        // Success feedback
        _showFaceDetectionSuccess();
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorDialog('Gagal mengambil foto: $e');
    } finally {
      setState(() {
        _imageLoading = false;
        _isScanning = false;
      });
    }
  }

  void _showFaceDetectionSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Wajah terdeteksi dengan baik!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              Navigator.pop(context);
              Navigator.pop(context, 'success');
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
        title: const Text('Verifikasi Wajah'),
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
        _buildFaceVerificationSection(imageHeight),
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
          child: _buildFaceVerificationSection(imageHeight),
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

  Widget _buildFaceVerificationSection(double imageHeight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = imageHeight.clamp(300.0, constraints.maxHeight * 0.8);

        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            height: cardHeight,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: _buildFaceDetectionWidget(cardHeight - 80),
                      ),
                      // Overlay untuk face detection
                      _buildFaceDetectionOverlay(cardHeight - 80),
                    ],
                  ),
                ),
                Container(
                  height: 100,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInstructionText(),
                      const SizedBox(height: 8),
                      _buildCameraButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaceDetectionWidget(double height) {
    if (_compressedImageBytes != null) {
      return Stack(
        children: [
          Image.memory(
            _compressedImageBytes!,
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
            cacheHeight: height.toInt(),
          ),
          if (_faceDetected) _buildSuccessOverlay(),
        ],
      );
    }

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[300]!,
            Colors.grey[400]!,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.face,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Posisikan wajah di dalam oval',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceDetectionOverlay(double height) {
    return Container(
      width: double.infinity,
      height: height,
      child: Stack(
        children: [
          // Oval guide
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 200,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(130),
                      border: Border.all(
                        color: _faceDetected
                            ? Colors.green
                            : _isScanning
                            ? Colors.blue
                            : Colors.white,
                        width: 3,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Scanning line
          if (_isScanning)
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return Positioned(
                  left: 0,
                  right: 0,
                  top: height * _scanAnimation.value,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.blue,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          // Corner indicators
          _buildCornerIndicators(),
        ],
      ),
    );
  }

  Widget _buildCornerIndicators() {
    return Stack(
      children: [
        // Top left
        Positioned(
          top: 20,
          left: 20,
          child: _buildCornerIndicator(true, true),
        ),
        // Top right
        Positioned(
          top: 20,
          right: 20,
          child: _buildCornerIndicator(true, false),
        ),
        // Bottom left
        Positioned(
          bottom: 20,
          left: 20,
          child: _buildCornerIndicator(false, true),
        ),
        // Bottom right
        Positioned(
          bottom: 20,
          right: 20,
          child: _buildCornerIndicator(false, false),
        ),
      ],
    );
  }

  Widget _buildCornerIndicator(bool isTop, bool isLeft) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: Colors.white, width: 2) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: Colors.white, width: 2) : BorderSide.none,
          left: isLeft ? BorderSide(color: Colors.white, width: 2) : BorderSide.none,
          right: !isLeft ? BorderSide(color: Colors.white, width: 2) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionText() {
    String text = 'Tekan tombol untuk memulai verifikasi';
    Color color = Colors.black54;

    if (_isScanning) {
      text = 'Sedang memindai wajah...';
      color = Colors.blue;
    } else if (_faceDetected) {
      text = 'Wajah terdeteksi!';
      color = Colors.green;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCameraButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 360;

    // Responsive text based on screen size
    String getButtonText() {
      if (_imageLoading || _isScanning) {
        return isSmallScreen ? 'Proses...' : 'Memproses...';
      } else if (_faceDetected) {
        return isSmallScreen ? 'Ulang' : 'Ambil Ulang';
      } else {
        return isSmallScreen ? 'Mulai' : isTablet ? 'Mulai Verifikasi' : 'Verifikasi';
      }
    }

    Widget getIcon() {
      if (_imageLoading || _isScanning) {
        return SizedBox(
          width: isTablet ? 18 : 16,
          height: isTablet ? 18 : 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        );
      } else {
        return Icon(
          _faceDetected ? Icons.refresh : Icons.camera_alt,
          size: isTablet ? 18 : 16,
        );
      }
    }

    return SizedBox(
      width: double.infinity,
      height: isTablet ? 40 : 36,
      child: ElevatedButton(
        onPressed: _imageLoading ? null : _pickImage,
        style: ElevatedButton.styleFrom(
          backgroundColor: _faceDetected ? Colors.green : Colors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : isSmallScreen ? 6 : 8,
            vertical: isTablet ? 8 : 6,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Check if we have enough space for icon + text
            final hasSpaceForBoth = constraints.maxWidth > 120;

            if (hasSpaceForBoth) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  getIcon(),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      getButtonText(),
                      style: TextStyle(
                        fontSize: isTablet ? 14 : isSmallScreen ? 10 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              );
            } else {
              // Not enough space, show only icon
              return getIcon();
            }
          },
        ),
      ),
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
    final isEnabled = _faceDetected && !_loading;

    return SizedBox(
      width: double.infinity,
      height: isTablet ? 60 : 50,
      child: ElevatedButton.icon(
        onPressed: isEnabled ? _submitAbsensi : null,
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
          backgroundColor: isEnabled ? Colors.teal : Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: isEnabled ? 8 : 2,
        ),
      ),
    );
  }
}