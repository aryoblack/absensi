import 'package:flutter/material.dart';

class DetailKaryawanScreen extends StatelessWidget {
  final Map<String, dynamic> karyawan;

  const DetailKaryawanScreen({super.key, required this.karyawan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Karyawan'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama: ${karyawan['nama']}', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('NIK: ${karyawan['nik']}', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Divisi: ${karyawan['nama_divisi'] ?? '-'}', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Jabatan: ${karyawan['nama_jabatan'] ?? '-'}', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Tanggal Masuk: ${karyawan['tgl_masuk'] ?? '-'}', style: TextStyle(fontSize: 18)),
            // Tambahkan detail lain sesuai kebutuhan

          ],
        ),
      ),
    );
  }
}
