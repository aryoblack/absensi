import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'cuti_form.dart';

class CutiScreen extends StatefulWidget {
  const CutiScreen({super.key});

  @override
  State<CutiScreen> createState() => _CutiScreenState();
}

class _CutiScreenState extends State<CutiScreen> {
  List<Map<String, dynamic>> cutiList = [];
  List<String> availableYears = ['Semua'];
  String selectedStatus = 'Semua';
  String selectedYear = 'Semua';
  String sortOrder = 'Terbaru';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCuti();
  }

  Future<void> fetchCuti() async {
    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token tidak ditemukan. Silakan login ulang.')),
      );
      return;
    }

    final response = await ApiService().getCutiList(token);
    if (response['status'] == true && response['data'] != null) {
      final data = List<Map<String, dynamic>>.from(response['data']);

      final years = data.map((item) {
        final tanggal = item['tanggal_mulai'] ?? '';
        if (tanggal.length >= 4) return tanggal.substring(0, 4);
        return '';
      }).toSet()
        ..removeWhere((e) => e.isEmpty);

      setState(() {
        cutiList = data;
        availableYears = ['Semua', ...years.toList()..sort()];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredCutiList {
    final list = cutiList.where((cuti) {
      final status = (cuti['status'] ?? 'Menunggu').toString().toLowerCase();
      final year = (cuti['tanggal_mulai'] ?? '').toString().substring(0, 4);

      final matchStatus = selectedStatus == 'Semua' || status == selectedStatus.toLowerCase();
      final matchYear = selectedYear == 'Semua' || year == selectedYear;

      return matchStatus && matchYear;
    }).toList();

    list.sort((a, b) {
      final aDate = DateTime.tryParse(a['tanggal_mulai'] ?? '') ?? DateTime(2000);
      final bDate = DateTime.tryParse(b['tanggal_mulai'] ?? '') ?? DateTime(2000);
      return sortOrder == 'Terbaru'
          ? bDate.compareTo(aDate)
          : aDate.compareTo(bDate);
    });

    return list;
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void showCutiDetail(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detail Cuti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jenis: ${item['jenis_cuti'] ?? '-'}'),
            Text('Tanggal: ${item['tanggal_mulai'] ?? '-'} s/d ${item['tanggal_selesai'] ?? '-'}'),
            Text('Status: ${item['status'] ?? '-'}'),
            const SizedBox(height: 8),
            const Text('Keterangan:'),
            Text(item['keterangan'] ?? 'Tidak ada keterangan'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Tutup'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Riwayat Cuti'),
          backgroundColor: Colors.teal,
          centerTitle: true,
          foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: ['Semua', 'Menunggu', 'Disetujui', 'Ditolak']
                        .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedStatus = val!),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    value: selectedYear,
                    decoration: const InputDecoration(labelText: 'Tahun'),
                    items: availableYears
                        .map((year) => DropdownMenuItem(value: year, child: Text(year)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedYear = val!),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    value: sortOrder,
                    decoration: const InputDecoration(labelText: 'Urutan'),
                    items: ['Terbaru', 'Terlama']
                        .map((order) => DropdownMenuItem(value: order, child: Text(order)))
                        .toList(),
                    onChanged: (val) => setState(() => sortOrder = val!),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedStatus = 'Semua';
                      selectedYear = 'Semua';
                      sortOrder = 'Terbaru';
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredCutiList.isEmpty
                  ? const Center(child: Text('Tidak ada data cuti.'))
                  : ListView.builder(
                itemCount: filteredCutiList.length,
                itemBuilder: (context, index) {
                  final item = filteredCutiList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => showCutiDetail(item),
                      title: Text(item['jenis_cuti'] ?? 'Jenis tidak diketahui'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item['tanggal_mulai']} s/d ${item['tanggal_selesai']}'),
                          Text(item['keterangan'] ?? '', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          (item['status'] ?? 'Menunggu').toString().toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: getStatusColor(item['status'] ?? ''),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CutiForm()),
          );
          if (result == true) fetchCuti();
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajukan Cuti'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}
