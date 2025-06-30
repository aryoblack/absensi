import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ApprovalIzinHarianScreen extends StatefulWidget {
  const ApprovalIzinHarianScreen({super.key});

  @override
  State<ApprovalIzinHarianScreen> createState() => _ApprovalIzinHarianScreenState();
}

class _ApprovalIzinHarianScreenState extends State<ApprovalIzinHarianScreen> {
  List<dynamic> _data = [];
  bool _loading = true;

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.fetchPengajuanIzinHarian(); // Ganti sesuai endpoint API
      setState(() {
        _data = result;
      });
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _confirmUpdateStatus(int id, String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == 'disetujui' ? 'Setujui Izin' : 'Tolak Izin'),
        content: Text(
            'Apakah Anda yakin ingin ${status == 'disetujui' ? 'menyetujui' : 'menolak'} pengajuan izin ini?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: status == 'disetujui' ? Colors.green : Colors.red,

            ),
            child: Text(status == 'disetujui' ? 'Setujui' : 'Tolak'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateStatus(id, status);
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    final success = await ApiService.updateStatusIzinHarian(id, status); // Ganti sesuai endpoint API
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status berhasil diubah ke $status')),
      );
      _loadData();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text('Approval Izin Harian'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
          ? const Center(child: Text('Tidak ada pengajuan izin harian'))
          : ListView.builder(
        itemCount: _data.length,
        itemBuilder: (context, index) {
          final izin = _data[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(12),
            child: ListTile(
              title: Text(izin['nama_karyawan']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jenis ${izin['jenis_izin']}'),
                  Text('Tanggal: ${izin['tanggal']}'),
                  Text('Keperluan: ${izin['keterangan']}'),
                  Text('Status: ${izin['status']}'),
                ],
              ),
              trailing: izin['status'] == 'pending'
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _confirmUpdateStatus(int.parse(izin['id'].toString()), 'disetujui'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _confirmUpdateStatus(int.parse(izin['id'].toString()), 'ditolak'),
                  ),
                ],
              )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
