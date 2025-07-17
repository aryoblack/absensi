// File: lib/services/background_service.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class BackgroundService {
  static const String _isolateName = 'background_isolate';
  static const String _portName = 'background_port';

  static SendPort? _sendPort;
  static Isolate? _isolate;
  static bool _isRunning = false;

  // Memulai background service
  static Future<void> startBackgroundService() async {
    if (_isRunning) return;

    // Registrasi callback untuk background processing
    final receivePort = ReceivePort();

    // Spawn isolate untuk background processing
    _isolate = await Isolate.spawn(
      _backgroundMain,
      receivePort.sendPort,
      debugName: _isolateName,
    );

    // Setup komunikasi dengan isolate
    _sendPort = await receivePort.first;
    _isRunning = true;

    // Registrasi port untuk komunikasi
    IsolateNameServer.registerPortWithName(
      receivePort.sendPort,
      _portName,
    );

    print('Background service started');
  }

  // Menghentikan background service
  static Future<void> stopBackgroundService() async {
    if (!_isRunning) return;

    _isolate?.kill();
    _isolate = null;
    _sendPort = null;
    _isRunning = false;

    IsolateNameServer.removePortNameMapping(_portName);

    print('Background service stopped');
  }

  // Main function untuk background isolate
  static void _backgroundMain(SendPort sendPort) async {
    // Setup timer untuk periodic check
    Timer.periodic(Duration(minutes: 30), (timer) async {
      await _performBackgroundCheck();
    });

    // Send port back to main isolate
    sendPort.send(sendPort);
  }

  // Perform background check
  static Future<void> _performBackgroundCheck() async {
    try {
      // Initialize notification service in background
      await NotificationService.initialize();

      // Check absen status and notify
      await NotificationService.checkAbsenStatusAndNotify();

      print('Background check completed at ${DateTime.now()}');
    } catch (e) {
      print('Background check error: $e');
    }
  }

  // Send message to background isolate
  static void sendMessageToBackground(String message) {
    _sendPort?.send(message);
  }

  // Check if service is running
  static bool get isRunning => _isRunning;
}

// Background task handler untuk native callbacks
class BackgroundTaskHandler {
  static const MethodChannel _channel = MethodChannel('background_task');

  // Setup background task
  static Future<void> setupBackgroundTask() async {
    try {
      await _channel.invokeMethod('setupBackgroundTask');
    } on PlatformException catch (e) {
      print('Failed to setup background task: $e');
    }
  }

  // Handle background execution
  static Future<void> handleBackgroundExecution() async {
    try {
      // Pastikan notification service terinisialisasi
      await NotificationService.initialize();

      // Cek status absen dan kirim notifikasi jika diperlukan
      await NotificationService.checkAbsenStatusAndNotify();

      print('Background execution completed');
    } catch (e) {
      print('Background execution error: $e');
    }
  }
}

// Widget untuk mengelola background service
class BackgroundServiceWidget extends StatefulWidget {
  final Widget child;

  const BackgroundServiceWidget({Key? key, required this.child}) : super(key: key);

  @override
  _BackgroundServiceWidgetState createState() => _BackgroundServiceWidgetState();
}

class _BackgroundServiceWidgetState extends State<BackgroundServiceWidget>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeBackgroundService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeBackgroundService() async {
    await BackgroundService.startBackgroundService();
    await BackgroundTaskHandler.setupBackgroundTask();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
      // App kembali ke foreground
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
      // App masuk ke background
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
      // App ditutup
        _handleAppDetached();
        break;
      default:
        break;
    }
  }

  void _handleAppResumed() {
    print('App resumed - checking absen status');
    // Cek status absen ketika app kembali aktif
    NotificationService.checkAbsenStatusAndNotify();
  }

  void _handleAppPaused() {
    print('App paused - ensuring background service is running');
    // Pastikan background service berjalan
    if (!BackgroundService.isRunning) {
      BackgroundService.startBackgroundService();
    }
  }

  void _handleAppDetached() {
    print('App detached - cleaning up');
    // Cleanup ketika app ditutup
    BackgroundService.stopBackgroundService();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}