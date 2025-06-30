class SlipGajiData {
  final String karyawan;
  final String jabatan;
  final String nip;
  final String divisi;
  final DateTime tanggal;
  final Map<String, double> pendapatan;
  final Map<String, double> potongan;

  SlipGajiData({
    required this.karyawan,
    required this.jabatan,
    required this.nip,
    required this.divisi,
    required this.tanggal,
    required this.pendapatan,
    required this.potongan,
  });

  double get totalPendapatan => pendapatan.values.fold(0, (sum, value) => sum + value);
  double get totalPotongan => potongan.values.fold(0, (sum, value) => sum + value);
  double get thp => totalPendapatan - totalPotongan;

  // Factory constructor untuk parsing dari JSON API
  factory SlipGajiData.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    return SlipGajiData(
      karyawan: data['employee_name'] ?? '',
      jabatan: data['jabatan'] ?? '',
      nip: data['employee_nip'] ?? '',
      divisi: data['departemen'] ?? '',
      tanggal: DateTime.parse(data['tanggal_dibayar']),
      pendapatan: {
        'Gaji Pokok': (data['gaji_pokok'] ?? 0).toDouble(),
        'Tunjangan Makan & Transport': (data['tunjangan']['tunj_makan_transport'] ?? 0).toDouble(),
        'Tunjangan Kinerja': (data['tunjangan']['tunj_kinerja'] ?? 0).toDouble(),
        'Tunjangan Komunikasi': (data['tunjangan']['tunj_komunikasi'] ?? 0).toDouble(),
        'Tunjangan Jabatan': (data['tunjangan']['tunj_jabatan'] ?? 0).toDouble(),
      },
      potongan: {
        'Denda Terlambat': (data['potongan']['denda_terlambat'] ?? 0).toDouble(),
        'Jam Kerja': (data['potongan']['potongan_jam_kerja'] ?? 0).toDouble(),
        'BPJS Kesehatan': (data['potongan']['potongan_bpjs_kesehatan'] ?? 0).toDouble(),
        'BPJS Ketenagakerjaan': (data['potongan']['potongan_bpjs_ketenagakerjaan'] ?? 0).toDouble(),
        'lain-lain': (data['potongan']['potongan_lain_lain'] ?? 0).toDouble(),
        'TBK': (data['potongan']['tbk'] ?? 0).toDouble(),
      },
    );
  }


  // Method untuk convert ke JSON (jika diperlukan)
  Map<String, dynamic> toJson() {
    return {
      'karyawan': karyawan,
      'jabatan': jabatan,
      'nip': nip,
      'divisi': divisi,
      'tanggal': tanggal.toIso8601String(),
      'total_pendapatan': pendapatan,
      'total_potongan': potongan,
    };
  }
}