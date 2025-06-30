import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart'; // Buat halaman ini juga
import 'screens/ApprovalCutiScreen.dart';
import 'screens/KelolaKaryawanScreen.dart';
import 'screens/ApprovalIzinHarianScreen.dart';
import 'screens/ApprovalIzinJamScreen.dart';
import 'screens/splash_screen.dart';
import 'package:intl/intl.dart';

void main() {
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
