class KunjunganDinas {
  final String id;
  final String tujuan;
  final String lokasi;
  final String kepentingan;
  final String tanggalMulai;
  final String tanggalSelesai;
  final String? jamMulai;
  final String? jamSelesai;
  final String? keterangan;
  final String status;
  final String? catatan;
  final String createdAt;
  final String updatedAt;

  KunjunganDinas({
    required this.id,
    required this.tujuan,
    required this.lokasi,
    required this.kepentingan,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.jamMulai,
    this.jamSelesai,
    this.keterangan,
    required this.status,
    this.catatan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KunjunganDinas.fromJson(Map<String, dynamic> json) {
    return KunjunganDinas(
      id: json['id'].toString(),
      tujuan: json['tujuan'],
      lokasi: json['lokasi'],
      kepentingan: json['kepentingan'],
      tanggalMulai: json['tanggal_mulai'],
      tanggalSelesai: json['tanggal_selesai'],
      jamMulai: json['jam_mulai'],
      jamSelesai: json['jam_selesai'],
      keterangan: json['keterangan'],
      status: json['status'],
      catatan: json['catatan'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tujuan': tujuan,
      'lokasi': lokasi,
      'kepentingan': kepentingan,
      'tanggal_mulai': tanggalMulai,
      'tanggal_selesai': tanggalSelesai,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'keterangan': keterangan,
      'status': status,
      'catatan': catatan,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}