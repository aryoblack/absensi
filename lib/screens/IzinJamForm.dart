import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class IzinJamForm extends StatefulWidget {
  const IzinJamForm({super.key});

  @override
  State<IzinJamForm> createState() => _IzinJamFormState();
}

class _IzinJamFormState extends State<IzinJamForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _tanggal;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;
  String _jenisIzin = '';
  String _keterangan = '';
  int id_karyawan = 1;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  void _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      id_karyawan = prefs.getInt('id_karyawan') ?? 1;
    });
  }

  String formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('HH:mm:ss').format(dt);
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_tanggal == null || _jamMulai == null || _jamSelesai == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lengkapi tanggal dan jam')),
        );
        return;
      }

      setState(() => _loading = true);
      print('ID Karyawan: $id_karyawan');
      final izin = {
        'id_karyawan': id_karyawan,
        'tanggal': DateFormat('yyyy-MM-dd').format(_tanggal!),
        'jam_mulai': formatTimeOfDay(_jamMulai!),
        'jam_selesai': formatTimeOfDay(_jamSelesai!),
        'jenis_izin': _jenisIzin,
        'keterangan': _keterangan,
      };

      final response = await ApiService.postIzinJam(izin);
      setState(() => _loading = false);

      if (response['status']) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal mengirim data')),
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isMulai) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 08, minute: 00),
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _jamMulai = picked;
        } else {
          _jamSelesai = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Izin Jam'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Petunjuk'),
                  content: const Text('Isi form ini untuk mengajukan izin berdasarkan jam.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                title: Text(_tanggal == null
                    ? 'Pilih Tanggal'
                    : DateFormat('yyyy-MM-dd').format(_tanggal!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _tanggal = picked;
                    });
                  }
                },
              ),
              ListTile(
                title: Text(_jamMulai == null
                    ? 'Pilih Jam Mulai'
                    : 'Jam Mulai: ${_jamMulai!.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, true),
              ),
              ListTile(
                title: Text(_jamSelesai == null
                    ? 'Pilih Jam Selesai'
                    : 'Jam Selesai: ${_jamSelesai!.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, false),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Jenis Izin'),
                value: _jenisIzin.isNotEmpty ? _jenisIzin : null,
                items: const [
                  DropdownMenuItem(value: 'Pulang Awal', child: Text('Izin Pulang Awal')),
                  DropdownMenuItem(value: 'Datang Terlambat', child: Text('Izin Datang Terlambat')),
                  DropdownMenuItem(value: 'Keluar Kantor Sementara', child: Text('Keluar Kantor Sementara')),
                  DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                ],
                onChanged: (value) {
                  setState(() {
                    _jenisIzin = value!;
                  });
                },
                validator: (value) =>
                value == null || value.isEmpty ? 'Wajib dipilih' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Keterangan'),
                maxLines: 3,
                onChanged: (val) => _keterangan = val,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: _loading ? null : _submitForm,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Kirim Izin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
