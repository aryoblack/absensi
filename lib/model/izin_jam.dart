class IzinJam {
  final DateTime tanggal;
  final String jamMulai;
  final String jamSelesai;
  final String jenisIzin;
  final String keterangan;

  IzinJam({
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.jenisIzin,
    required this.keterangan,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_karyawan': 1,
      'tanggal': tanggal.toIso8601String().split('T')[0], // YYYY-MM-DD
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'jenis_izin': jenisIzin,
      'keterangan': keterangan,
    };
  }
}
