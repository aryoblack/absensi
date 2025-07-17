import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class KunjunganDinasScreen extends StatefulWidget {
  const KunjunganDinasScreen({Key? key}) : super(key: key);

  @override
  State<KunjunganDinasScreen> createState() => _KunjunganDinasScreenState();
}

class _KunjunganDinasScreenState extends State<KunjunganDinasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _tujuanController = TextEditingController();
  final TextEditingController _kepentinganController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  bool _isLoading = true;
  String? _token;
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;

  // Sample data untuk riwayat
  List<Map<String, dynamic>> _riwayatKunjungan = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tujuanController.dispose();
    _kepentinganController.dispose();
    _lokasiController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }
  // Ganti fungsi _loadData():
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null) {
      try {
        final response = await ApiService.getRiwayatKunjungan(token: _token!);
        print('Data riwayat kunjungan: $response');

        if (response['status'] == true && response['data'] != null) {
          List<Map<String, dynamic>> rawData = List<Map<String, dynamic>>.from(response['data']);

          // Mapping data dari API ke format yang digunakan di UI
          _riwayatKunjungan = rawData.map((item) {
            return {
              'id': item['id']?.toString() ?? '',
              'tujuan': item['tujuan'] ?? '',
              'lokasi': item['lokasi'] ?? '',
              'tanggal': item['tanggal_mulai'] ?? item['tanggal_mulai'] ?? '',
              'status': item['status'] ?? '',
              'statusColor': _getStatusColor(item['status'] ?? ''),
              // Tambahan field yang mungkin ada dari API
              'kepentingan': item['kepentingan'] ?? '',
              'tanggal_selesai': item['tanggal_selesai'] ?? '',
              'jam_mulai': item['jam_mulai'] ?? '',
              'jam_selesai': item['jam_selesai'] ?? '',
              'keterangan': item['keterangan'] ?? '',
            };
          }).toList();
        } else {
          _riwayatKunjungan = [];
        }
      } catch (e) {
        print('Error loading riwayat: $e');
        _riwayatKunjungan = [];
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data riwayat.')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
      case 'approved':
        return Colors.green;
      case 'menunggu':
      case 'pending':
        return Colors.orange;
      case 'ditolak':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kunjungan Dinas'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pengajuan Baru'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPengajuanTab(),
          _buildRiwayatTab(),
        ],
      ),
    );
  }

  Widget _buildPengajuanTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(isTablet),
                const SizedBox(height: 20),
                _buildFormFields(isTablet),
                const SizedBox(height: 30),
                _buildSubmitButton(isTablet),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(bool isTablet) {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.teal.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business_center,
                  size: isTablet ? 32 : 24,
                  color: Colors.teal,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pengajuan Kunjungan Dinas',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.teal.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 24 : 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan isi form di bawah untuk mengajukan permohonan kunjungan dinas',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.teal.shade600,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields(bool isTablet) {
    return Column(
      children: [
        if (isTablet)
          Row(
            children: [
              Expanded(child: _buildTujuanField()),
              const SizedBox(width: 16),
              Expanded(child: _buildLokasiField()),
            ],
          )
        else ...[
          _buildTujuanField(),
          const SizedBox(height: 16),
          _buildLokasiField(),
        ],

        const SizedBox(height: 16),
        _buildKepentinganField(),

        const SizedBox(height: 20),
        _buildDateTimeSection(isTablet),

        const SizedBox(height: 16),
        _buildKeteranganField(),
      ],
    );
  }

  Widget _buildTujuanField() {
    return TextFormField(
      controller: _tujuanController,
      decoration: InputDecoration(
        labelText: 'Tujuan Kunjungan',
        hintText: 'Masukkan tujuan kunjungan dinas',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.teal),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Tujuan kunjungan tidak boleh kosong';
        }
        return null;
      },
    );
  }

  Widget _buildLokasiField() {
    return TextFormField(
      controller: _lokasiController,
      decoration: InputDecoration(
        labelText: 'Lokasi',
        hintText: 'Masukkan lokasi tujuan',
        prefixIcon: const Icon(Icons.place),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.teal),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lokasi tidak boleh kosong';
        }
        return null;
      },
    );
  }

  Widget _buildKepentinganField() {
    return TextFormField(
      controller: _kepentinganController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Kepentingan',
        hintText: 'Jelaskan kepentingan kunjungan dinas',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.teal),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Kepentingan tidak boleh kosong';
        }
        return null;
      },
    );
  }

  Widget _buildDateTimeSection(bool isTablet) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Waktu Kunjungan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
            const SizedBox(height: 16),

            if (isTablet)
              Row(
                children: [
                  Expanded(child: _buildDateField('Tanggal Mulai', _tanggalMulai, true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDateField('Tanggal Selesai', _tanggalSelesai, false)),
                ],
              )
            else ...[
              _buildDateField('Tanggal Mulai', _tanggalMulai, true),
              const SizedBox(height: 16),
              _buildDateField('Tanggal Selesai', _tanggalSelesai, false),
            ],

            const SizedBox(height: 16),

            if (isTablet)
              Row(
                children: [
                  Expanded(child: _buildTimeField('Jam Mulai', _jamMulai, true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTimeField('Jam Selesai', _jamSelesai, false)),
                ],
              )
            else ...[
              _buildTimeField('Jam Mulai', _jamMulai, true),
              const SizedBox(height: 16),
              _buildTimeField('Jam Selesai', _jamSelesai, false),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? selectedDate, bool isStart) {
    return InkWell(
      onTap: () => _selectDate(context, isStart),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.teal),
          ),
        ),
        child: Text(
          selectedDate != null
              ? DateFormat('dd/MM/yyyy').format(selectedDate)
              : 'Pilih tanggal',
          style: TextStyle(
            color: selectedDate != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField(String label, TimeOfDay? selectedTime, bool isStart) {
    return InkWell(
      onTap: () => _selectTime(context, isStart),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.teal),
          ),
        ),
        child: Text(
          selectedTime != null
              ? selectedTime.format(context)
              : 'Pilih jam',
          style: TextStyle(
            color: selectedTime != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildKeteranganField() {
    return TextFormField(
      controller: _keteranganController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'Keterangan Tambahan',
        hintText: 'Masukkan keterangan tambahan (opsional)',
        prefixIcon: const Icon(Icons.note),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.teal),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isTablet) {
    return SizedBox(
      width: double.infinity,
      height: isTablet ? 56 : 48,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.send),
            const SizedBox(width: 8),
            Text(
              'Ajukan Kunjungan Dinas',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_riwayatKunjungan.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada riwayat kunjungan dinas',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
            itemCount: _riwayatKunjungan.length,
            itemBuilder: (context, index) {
              final item = _riwayatKunjungan[index];
              return _buildRiwayatCard(item, isTablet);
            },
          ),
        );
      },
    );
  }

  Widget _buildRiwayatCard(Map<String, dynamic> item, bool isTablet) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.business_center,
                    color: Colors.teal,
                    size: isTablet ? 24 : 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['tujuan'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.place,
                            size: isTablet ? 18 : 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['lokasi'],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: isTablet ? 16 : 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: isTablet ? 18 : 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['tanggal'],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: isTablet ? 16 : 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item['statusColor'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item['statusColor'],
                      width: 1,
                    ),
                  ),
                  child: Text(
                    item['status'],
                    style: TextStyle(
                      color: item['statusColor'],
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 14 : 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showDetailDialog(item),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Detail'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.teal,
                  ),
                ),
                const SizedBox(width: 8),
                if (item['status'] == 'Menunggu')
                  TextButton.icon(
                    onPressed: () => _showCancelDialog(item['id']),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Batalkan'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _tanggalMulai = picked;
        } else {
          _tanggalSelesai = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _jamMulai = picked;
        } else {
          _jamSelesai = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_tanggalMulai == null || _tanggalSelesai == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih tanggal mulai dan selesai'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await ApiService.submitKunjungan(
        tujuan: _tujuanController.text,
        lokasi: _lokasiController.text,
        kepentingan: _kepentinganController.text,
        tanggalMulai: DateFormat('yyyy-MM-dd').format(_tanggalMulai!),
        tanggalSelesai: DateFormat('yyyy-MM-dd').format(_tanggalSelesai!),
        jamMulai: _jamMulai?.format(context) ?? '',
        jamSelesai: _jamSelesai?.format(context) ?? '',
        keterangan: _keteranganController.text,
        token: token,
      );

      print('Response Api: $response');

      if (response['success'] == true) {
        // Reset form
        _formKey.currentState!.reset();
        _tujuanController.clear();
        _kepentinganController.clear();
        _lokasiController.clear();
        _keteranganController.clear();
        setState(() {
          _tanggalMulai = null;
          _tanggalSelesai = null;
          _jamMulai = null;
          _jamSelesai = null;
        });

        // Refresh data riwayat
        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan kunjungan dinas berhasil dikirim'),
            backgroundColor: Colors.green,
          ),
        );

        // Pindah ke tab riwayat
        _tabController.animateTo(1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal mengirim pengajuan kunjungan dinas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDetailDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Kunjungan Dinas'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${item['id']}'),
              const SizedBox(height: 8),
              Text('Tujuan: ${item['tujuan']}'),
              const SizedBox(height: 8),
              Text('Lokasi: ${item['lokasi']}'),
              const SizedBox(height: 8),
              Text('Tanggal: ${item['tanggal']}'),
              if (item['tanggal_selesai']?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text('Tanggal Selesai: ${item['tanggal_selesai']}'),
              ],
              if (item['jam_mulai']?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text('Jam: ${item['jam_mulai']} - ${item['jam_selesai']}'),
              ],
              if (item['kepentingan']?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text('Kepentingan: ${item['kepentingan']}'),
              ],
              if (item['keterangan']?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text('Keterangan: ${item['keterangan']}'),
              ],
              const SizedBox(height: 8),
              Text('Status: ${item['status']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pengajuan'),
        content: const Text('Apakah Anda yakin ingin membatalkan pengajuan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              // Simulasi pembatalan
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pengajuan berhasil dibatalkan'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Ya', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}