import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'tambah_karyawan_screen.dart';
import 'edit_karyawan_screen.dart';
import 'detail_karyawan_screen.dart';
class KelolaKaryawanScreen extends StatefulWidget {
  const KelolaKaryawanScreen({super.key});

  @override
  State<KelolaKaryawanScreen> createState() => _KelolaKaryawanScreenState();
}

class _KelolaKaryawanScreenState extends State<KelolaKaryawanScreen> {
  List<dynamic> karyawanList = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final data = await ApiService.getListKaryawan(token);
    setState(() {
      karyawanList = data;
      loading = false;
    });
  }

  void _konfirmasiHapus(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin menghapus karyawan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              SharedPreferences prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token') ?? '';
              final success = await ApiService.hapusKaryawan(token, id);
              if (success) {
                fetchData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Karyawan dihapus')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gagal menghapus')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showKaryawanOptions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['nama'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Lihat Detail'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailKaryawanScreen(karyawan: item),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditKaryawanScreen(karyawan: item),
                  ),
                );
                if (result == true) fetchData();
              },
            ),

            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _konfirmasiHapus(item['id'].toString());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text('Kelola Karyawan'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: karyawanList.length,
        itemBuilder: (_, index) {
          final item = karyawanList[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(item['nama']),
              subtitle: Text(item['nik'] ?? ''),
              trailing: const Icon(Icons.more_vert),
              onTap: () => _showKaryawanOptions(item),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahKaryawanScreen()),
          );
          if (result == true) {
            fetchData(); // Refresh data jika berhasil menambahkan
          }
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),

    );
  }
}
