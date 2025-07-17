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

  // Data sisa cuti
  int sisaCutiTahunan = 0;
  int sisaCutiSakit = 0;
  int sisaCutiKhusus = 0;
  bool isLoadingSisaCuti = true;

  @override
  void initState() {
    super.initState();
    fetchCuti();
    fetchSisaCuti();
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

  // Fungsi untuk mengambil data sisa cuti
  Future<void> fetchSisaCuti() async {
    setState(() => isLoadingSisaCuti = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      setState(() => isLoadingSisaCuti = false);
      return;
    }

    try {
      // Ganti dengan endpoint API yang sesuai untuk mengambil sisa cuti
      final response = await ApiService().getSisaCuti(token);
      final data = response['data'];
      print('Sisa Cuti: $data');
      if (response['status'] == true && response['data'] != null) {

        setState(() {
          sisaCutiTahunan = data['sisa_cuti_tahunan'] ?? 12;
          // sisaCutiSakit = data['sisa_cuti_sakit'] ?? 12;
          // sisaCutiKhusus = data['sisa_cuti_khusus'] ?? 2;
          isLoadingSisaCuti = false;
        });
      } else {
        // Data default jika API gagal
        setState(() {
          sisaCutiTahunan = 12;
          // sisaCutiSakit = 12;
          // sisaCutiKhusus = 2;
          isLoadingSisaCuti = false;
        });
      }
    } catch (e) {
      // Data default jika terjadi error
      setState(() {
        sisaCutiTahunan = 12;
        // sisaCutiSakit = 12;
        // sisaCutiKhusus = 2;
        isLoadingSisaCuti = false;
      });
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

  // Widget untuk menampilkan sisa cuti
  Widget buildSisaCutiCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Sisa Cuti',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            isLoadingSisaCuti
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
              builder: (context, constraints) {
                // Responsive layout berdasarkan lebar layar
                if (constraints.maxWidth > 600) {
                  // Layout untuk tablet/desktop
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSisaCutiItem('Tahunan', sisaCutiTahunan, Colors.blue),
                      // _buildSisaCutiItem('Sakit', sisaCutiSakit, Colors.green),
                      // _buildSisaCutiItem('Khusus', sisaCutiKhusus, Colors.purple),
                    ],
                  );
                } else {
                  // Layout untuk mobile
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildSisaCutiItem('Tahunan', sisaCutiTahunan, Colors.blue)),
                          // const SizedBox(width: 12),
                          // Expanded(child: _buildSisaCutiItem('Sakit', sisaCutiSakit, Colors.green)),
                        ],
                      ),
                      // const SizedBox(height: 12),
                      // _buildSisaCutiItem('Khusus', sisaCutiKhusus, Colors.purple),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSisaCutiItem(String label, int sisa, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            sisa.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Widget responsive untuk filter
  Widget buildFilterSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          // Layout untuk desktop
          return Row(
            children: [
              Expanded(flex: 2, child: _buildStatusFilter()),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildYearFilter()),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildSortFilter()),
              const SizedBox(width: 12),
              _buildResetButton(),
            ],
          );
        } else if (constraints.maxWidth > 600) {
          // Layout untuk tablet
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatusFilter()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildYearFilter()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSortFilter()),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _buildResetButton(),
              ),
            ],
          );
        } else {
          // Layout untuk mobile
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatusFilter()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildYearFilter()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSortFilter()),
                  const SizedBox(width: 12),
                  _buildResetButton(),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      value: selectedStatus,
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: ['Semua', 'Menunggu', 'Disetujui', 'Ditolak']
          .map((status) => DropdownMenuItem(value: status, child: Text(status)))
          .toList(),
      onChanged: (val) => setState(() => selectedStatus = val!),
    );
  }

  Widget _buildYearFilter() {
    return DropdownButtonFormField<String>(
      value: selectedYear,
      decoration: const InputDecoration(
        labelText: 'Tahun',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: availableYears
          .map((year) => DropdownMenuItem(value: year, child: Text(year)))
          .toList(),
      onChanged: (val) => setState(() => selectedYear = val!),
    );
  }

  Widget _buildSortFilter() {
    return DropdownButtonFormField<String>(
      value: sortOrder,
      decoration: const InputDecoration(
        labelText: 'Urutan',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: ['Terbaru', 'Terlama']
          .map((order) => DropdownMenuItem(value: order, child: Text(order)))
          .toList(),
      onChanged: (val) => setState(() => sortOrder = val!),
    );
  }

  Widget _buildResetButton() {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          selectedStatus = 'Semua';
          selectedYear = 'Semua';
          sortOrder = 'Terbaru';
        });
      },
      icon: const Icon(Icons.refresh),
      label: const Text('Reset'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
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
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([fetchCuti(), fetchSisaCuti()]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width > 600 ? 24 : 16,
            vertical: 16,
          ),
          child: Column(
            children: [
              // Card sisa cuti
              buildSisaCutiCard(),

              // Filter section
              buildFilterSection(),

              const SizedBox(height: 16),

              // List cuti
              SizedBox(
                height: MediaQuery.of(context).size.height - 400,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredCutiList.isEmpty
                    ? const Center(child: Text('Tidak ada data cuti.'))
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredCutiList.length,
                  itemBuilder: (context, index) {
                    final item = filteredCutiList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        onTap: () => showCutiDetail(item),
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          item['jenis_cuti'] ?? 'Jenis tidak diketahui',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${item['tanggal_mulai']} s/d ${item['tanggal_selesai']}'),
                            if (item['keterangan'] != null && item['keterangan'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  item['keterangan'],
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            (item['status'] ?? 'Menunggu').toString().toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CutiForm()),
          );
          if (result == true) {
            fetchCuti();
            fetchSisaCuti(); // Refresh sisa cuti juga
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajukan Cuti'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}