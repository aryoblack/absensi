import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:dropdown_search/dropdown_search.dart';

class TambahKaryawanScreen extends StatefulWidget {
  const TambahKaryawanScreen({super.key});

  @override
  State<TambahKaryawanScreen> createState() => _TambahKaryawanScreenState();
}

class _TambahKaryawanScreenState extends State<TambahKaryawanScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _tanggalMasukController = TextEditingController();

  List<dynamic> divisiList = [];
  List<dynamic> jabatanList = [];

  String? selectedDivisiId;
  String? selectedJabatanId;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadDropdownData();
  }

  Future<void> loadDropdownData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final divisi = await ApiService.getDivisiList(token);
    final jabatan = await ApiService.getJabatanList(token);

    setState(() {
      divisiList = divisi;
      jabatanList = jabatan;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final success = await ApiService.tambahKaryawan(
      token: token,
      nama: _namaController.text,
      nik: _nikController.text,
      idDivisi: selectedDivisiId!,
      idJabatan: selectedJabatanId!,
      tanggalMasuk: _tanggalMasukController.text,
    );


    setState(() => loading = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Karyawan berhasil ditambahkan')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menambahkan karyawan')),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _tanggalMasukController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Karyawan'),
        backgroundColor: Colors.teal,
      ),
      body: loading
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
                validator: (value) =>
                value == null || value.isEmpty ? 'Nama wajib diisi' : null,
              ),
              TextFormField(
                controller: _nikController,
                decoration: const InputDecoration(labelText: 'NIK'),
                validator: (value) =>
                value == null || value.isEmpty ? 'NIK wajib diisi' : null,
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
                validator: (value) =>
                value == null ? 'Divisi wajib dipilih' : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedJabatanId,
                hint: const Text('Pilih Jabatan'),
                items: jabatanList.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item['id_jabatan'],
                    child: Text(item['nama_jabatan'].toString().trim()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedJabatanId = value);
                },
                validator: (value) =>
                value == null ? 'Jabatan wajib dipilih' : null,
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
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal,foregroundColor: Colors.white),
                child: const Text('Simpan'),
              ),
              const SizedBox(width: 10),
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
