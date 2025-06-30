import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart'; // Pastikan ada method tambahCuti di sini

class CutiForm extends StatefulWidget {
  const CutiForm({super.key});

  @override
  State<CutiForm> createState() => _CutiFormState();
}

class _CutiFormState extends State<CutiForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  final TextEditingController _keteranganController = TextEditingController();
  String? _jenisCuti;
  bool _submitting = false;
  String? _status;

  final List<String> _jenisCutiOptions = ['Tahunan', 'Sakit'];

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _tanggalMulai == null || _tanggalSelesai == null || _jenisCuti == null) return;

    setState(() {
      _submitting = true;
      _status = null;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await ApiService.tambahCuti(
      token!,
      _tanggalMulai!,
      _tanggalSelesai!,
      _keteranganController.text.trim(),
      _jenisCuti!,
    );

    setState(() {
      _submitting = false;
      _status = response['message'];
    });

    if (response['status'] == true) {
      Navigator.pop(context, true); // Berhasil
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _tanggalMulai = picked.start;
        _tanggalSelesai = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Pengajuan Cuti'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _submitting
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              // Jenis Cuti
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Jenis Cuti',
                  border: OutlineInputBorder(),
                ),
                items: _jenisCutiOptions
                    .map((jenis) => DropdownMenuItem(
                  value: jenis,
                  child: Text(jenis),
                ))
                    .toList(),
                value: _jenisCuti,
                onChanged: (value) {
                  setState(() {
                    _jenisCuti = value;
                  });
                },
                validator: (value) => value == null ? 'Pilih jenis cuti' : null,
              ),
              const SizedBox(height: 16),

              // Tanggal
              InkWell(
                onTap: () => _selectDateRange(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Cuti',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    (_tanggalMulai != null && _tanggalSelesai != null)
                        ? '${dateFormat.format(_tanggalMulai!)} - ${dateFormat.format(_tanggalSelesai!)}'
                        : 'Pilih rentang tanggal',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Keterangan
              TextFormField(
                controller: _keteranganController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Keterangan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.send),
                label: const Text('Ajukan Cuti'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              if (_status != null) ...[
                const SizedBox(height: 12),
                Text(
                  _status!,
                  style: TextStyle(
                    color: _status!.toLowerCase().contains('berhasil')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
