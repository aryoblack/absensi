import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

import 'IzinHarianForm.dart';

class IzinHarianList extends StatefulWidget {
  const IzinHarianList({super.key});

  @override
  State<IzinHarianList> createState() => _IzinHarianListState();
}

class _IzinHarianListState extends State<IzinHarianList> {
  List<Map<String, dynamic>> _izinList = [];
  List<Map<String, dynamic>> _filteredIzinList = [];
  bool _isLoading = true;
  String? _token;

  String _selectedStatus = 'Semua';
  String _selectedYear = 'Semua';
  bool _sortNewestFirst = true;

  List<String> _statusList = ['Semua', 'Disetujui', 'Ditolak', 'Pending'];
  List<String> _yearList = ['Semua'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null) {
      try {
        final data = await ApiService.getIzinHarian(_token!);
        List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(data['data'] ?? []);
        _izinList = list;
        _extractAvailableYears();
        _applyFilters();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data izin.')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _extractAvailableYears() {
    final years = _izinList.map((izin) {
      final date = DateTime.tryParse(izin['tanggal'] ?? '') ?? DateTime.now();
      return date.year.toString();
    }).toSet();

    _yearList = ['Semua', ...years.toList()..sort((a, b) => int.parse(b).compareTo(int.parse(a)))];
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = _izinList;

    if (_selectedStatus != 'Semua') {
      result = result.where((item) => (item['status'] ?? '').toLowerCase() == _selectedStatus.toLowerCase()).toList();
    }

    if (_selectedYear != 'Semua') {
      result = result.where((item) {
        final date = DateTime.tryParse(item['tanggal'] ?? '');
        return date != null && date.year.toString() == _selectedYear;
      }).toList();
    }

    result.sort((a, b) {
      final dateA = DateTime.tryParse(a['tanggal'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['tanggal'] ?? '') ?? DateTime(2000);
      return _sortNewestFirst ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });

    setState(() {
      _filteredIzinList = result;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Icons.check_circle;
      case 'ditolak':
        return Icons.cancel;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildIzinCard(Map<String, dynamic> izin) {
    String tanggal = izin['tanggal']?.toString().substring(0, 10) ?? '-';
    String formattedDate = DateFormat('dd MMM yyyy').format(DateTime.parse(tanggal));

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          _getStatusIcon(izin['status']),
          color: _getStatusColor(izin['status']),
          size: 36,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(izin['jenis_izin'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(formattedDate, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(izin['keterangan'] ?? '-', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Text(
          izin['status'] ?? '-',
          style: TextStyle(
            color: _getStatusColor(izin['status']),
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Detail Izin Harian'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Jenis Izin: ${izin['jenis_izin'] ?? '-'}"),
                  const SizedBox(height: 8),
                  Text("Tanggal: $formattedDate"),
                  const SizedBox(height: 8),
                  Text("Keterangan: ${izin['keterangan'] ?? '-'}"),
                  const SizedBox(height: 8),
                  Text("Status: ${izin['status'] ?? '-'}"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      children: [
        DropdownButton<String>(
          value: _selectedStatus,
          onChanged: (value) {
            setState(() {
              _selectedStatus = value!;
              _applyFilters();
            });
          },
          items: _statusList.map((status) {
            return DropdownMenuItem(value: status, child: Text('Status: $status'));
          }).toList(),
        ),
        DropdownButton<String>(
          value: _selectedYear,
          onChanged: (value) {
            setState(() {
              _selectedYear = value!;
              _applyFilters();
            });
          },
          items: _yearList.map((year) {
            return DropdownMenuItem(value: year, child: Text('Tahun: $year'));
          }).toList(),
        ),
        IconButton(
          icon: Icon(_sortNewestFirst ? Icons.arrow_downward : Icons.arrow_upward),
          tooltip: 'Urutkan ${_sortNewestFirst ? "terbaru" : "terlama"}',
          onPressed: () {
            setState(() {
              _sortNewestFirst = !_sortNewestFirst;
              _applyFilters();
            });
          },
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Izin Harian'),
        backgroundColor: Colors.teal,
        centerTitle: true,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _izinList.isEmpty
            ? const Center(child: Text('Belum ada pengajuan izin harian.'))
            : Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildFilters(),
              const SizedBox(height: 12),
              Expanded(
                child: _filteredIzinList.isEmpty
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Data tidak ditemukan berdasarkan filter.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedStatus = 'Semua';
                          _selectedYear = 'Semua';
                          _sortNewestFirst = true;
                          _applyFilters();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset Filter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                )
                    : isTablet
                    ? GridView.builder(
                  itemCount: _filteredIzinList.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) => _buildIzinCard(_filteredIzinList[index]),
                )
                    : ListView.separated(
                  itemCount: _filteredIzinList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _buildIzinCard(_filteredIzinList[index]),
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
            MaterialPageRoute(builder: (_) => const IzinHarianForm()),
          );
          if (result == true) _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajukan Izin Harian'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}
