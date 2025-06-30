import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ApprovalCutiScreen extends StatefulWidget {
  const ApprovalCutiScreen({super.key});

  @override
  State<ApprovalCutiScreen> createState() => _ApprovalCutiScreenState();
}

class _ApprovalCutiScreenState extends State<ApprovalCutiScreen> {
  List<dynamic> _data = [];
  bool _loading = true;

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.fetchPengajuanCuti();
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
        title: Text(status == 'Disetujui' ? 'Setujui Cuti' : 'Tolak Cuti'),
        content: Text(
            'Apakah Anda yakin ingin ${status == 'Disetujui' ? 'menyetujui' : 'menolak'} pengajuan cuti ini?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'Disetujui' ? Colors.green : Colors.red,
            ),
            child: Text(status == 'Disetujui' ? 'Setujui' : 'Tolak'),
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
    final success = await ApiService.updateStatusCuti(id, status);
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
        title: const Text('Approval Cuti'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
          ? const Center(child: Text('Tidak ada pengajuan cuti'))
          : ListView.builder(
        itemCount: _data.length,
        itemBuilder: (context, index) {
          final cuti = _data[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(12),
            child: ListTile(
              title: Text(cuti['nama_karyawan']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal: ${cuti['tanggal_mulai']} s/d ${cuti['tanggal_selesai']}',
                  ),
                  Text('Alasan: ${cuti['keterangan']}'),
                  Text('Status: ${cuti['status']}'),
                ],
              ),
              trailing: cuti['status'] == 'Diajukan'
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _confirmUpdateStatus(int.parse(cuti['id'].toString()), 'Disetujui'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _confirmUpdateStatus(int.parse(cuti['id'].toString()), 'Ditolak'),
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
