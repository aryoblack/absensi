import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class EditKaryawanScreen extends StatefulWidget {
  final Map<String, dynamic> karyawan;

  const EditKaryawanScreen({super.key, required this.karyawan});

  @override
  State<EditKaryawanScreen> createState() => _EditKaryawanScreenState();
}

class _EditKaryawanScreenState extends State<EditKaryawanScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _nikController;
  late TextEditingController _tanggalMasukController;

  String? selectedDivisiId;
  String? selectedJabatanId;
  List<dynamic> divisiList = [];
  List<dynamic> jabatanList = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.karyawan['nama']);
    _nikController = TextEditingController(text: widget.karyawan['nik']);
    _tanggalMasukController = TextEditingController(
      text: widget.karyawan['tgl_masuk'] ?? '',
    );
    selectedDivisiId = widget.karyawan['id_divisi']?.toString();
    selectedJabatanId = widget.karyawan['id_jabatan']?.toString();
    _loadData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nikController.dispose();
    _tanggalMasukController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final divisi = await ApiService.getDivisiList(token);
    final jabatan = await ApiService.getJabatanList(token);

    setState(() {
      divisiList = divisi;
      jabatanList = jabatan;
      isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_tanggalMasukController.text) ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _tanggalMasukController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _simpanPerubahan() async {
    if (!_formKey.currentState!.validate()) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final success = await ApiService.editKaryawan(
      token: token,
      id: widget.karyawan['id'].toString(),
      nama: _namaController.text,
      nik: _nikController.text,
      idDivisi: selectedDivisiId!,
      idJabatan: selectedJabatanId!,
      tanggalMasuk: _tanggalMasukController.text,
    );

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil memperbarui karyawan')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui karyawan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Karyawan'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (value) => value!.isEmpty ? 'Nama wajib diisi' : null,
              ),
              TextFormField(
                controller: _nikController,
                decoration: const InputDecoration(labelText: 'NIK'),
                validator: (value) => value!.isEmpty ? 'NIK wajib diisi' : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedDivisiId,
                hint: const Text('Pilih Divisi'),
                items: divisiList.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item['id'].toString(),
                    child: Text(item['nama_divisi']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedDivisiId = value);
                },
                validator: (value) => value == null ? 'Divisi wajib dipilih' : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedJabatanId,
                hint: const Text('Pilih Jabatan'),
                items: jabatanList.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item['id_jabatan'].toString(),
                    child: Text(item['nama_jabatan'].toString().trim()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedJabatanId = value);
                },
                validator: (value) => value == null ? 'Jabatan wajib dipilih' : null,
              ),
              TextFormField(
                controller: _tanggalMasukController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Masuk',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectDate,
                validator: (value) =>
                value == null || value.isEmpty ? 'Tanggal masuk wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _simpanPerubahan,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal,foregroundColor: Colors.white),
                child: const Text('Simpan'),
              ),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
