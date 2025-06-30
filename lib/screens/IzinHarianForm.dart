import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class IzinHarianForm extends StatefulWidget {
  const IzinHarianForm({super.key});

  @override
  State<IzinHarianForm> createState() => _IzinHarianFormState();
}

class _IzinHarianFormState extends State<IzinHarianForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  String? _selectedJenisIzin;
  final List<String> _jenisIzinList = ['Sakit', 'Izin Pribadi', 'Keperluan Keluarga'];

  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedJenisIzin == null) return;

    setState(() => _isSubmitting = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token tidak ditemukan. Silakan login ulang.')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final izinData = {
      'tanggal': _tanggalController.text,
      'keterangan': _keteranganController.text,
      'jenis_izin': _selectedJenisIzin,
    };

    try {
      final success = await ApiService.tambahIzinHarian(token, izinData);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan izin berhasil dikirim.')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Gagal');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim pengajuan izin.')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Izin Harian'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedJenisIzin,
                decoration: const InputDecoration(
                  labelText: 'Jenis Izin',
                  border: OutlineInputBorder(),
                ),
                items: _jenisIzinList.map((jenis) {
                  return DropdownMenuItem(
                    value: jenis,
                    child: Text(jenis),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedJenisIzin = value),
                validator: (value) =>
                value == null ? 'Pilih jenis izin' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tanggalController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Izin',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _pickDate,
                validator: (value) => value == null || value.isEmpty ? 'Pilih tanggal' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _keteranganController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Isi keterangan' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _isSubmitting
                    ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim Pengajuan'),
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
