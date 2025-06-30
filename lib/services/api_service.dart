import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../model/slip_gaji.dart';

class ApiService {
  static const String _baseUrl = 'https://app.unchu.id/api'; // Ganti dengan URL CI3 kamu

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    final response = await http.post(url, body: {
      'username': username,
      'password': password,
    });
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {'status': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  static Future<Map<String, dynamic>> absen(String token, File image, double lat, double lng) async {
    final url = Uri.parse('$_baseUrl/absen');
    print('Token: $token');
    print('Image Path: ${image.path}');
    print('Latitude: $lat');
    print('Longitude: $lng');

    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = token
      ..fields['lat'] = lat.toString()
      ..fields['lng'] = lng.toString()
      ..files.add(await http.MultipartFile.fromPath('foto', image.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    print('Cek Absen : '+ response.body+'xx');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {'status': false, 'message': 'Gagal mengirim absen'};
    }
  }
  static Future<Map<String, dynamic>> tambahCuti(
      String token,
      DateTime tglMulai,
      DateTime tglSelesai,
      String keterangan,
      String jenisCuti,
      ) async {
    final url = Uri.parse('$_baseUrl/tambah_cuti'); // Ganti sesuai endpoint
    final response = await http.post(
      url,
      headers: {
        'Authorization': token,
      },
      body: {
        'tgl_mulai': DateFormat('yyyy-MM-dd').format(tglMulai),
        'tgl_selesai': DateFormat('yyyy-MM-dd').format(tglSelesai),
        'keterangan': keterangan,
        'jenis_cuti': jenisCuti, // Ganti sesuai kebutuhan
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {'status': false, 'message': 'Gagal menghubungi server'};
    }
  }
  Future<Map<String, dynamic>> getCutiList(String token) async {
    print('Token cuti: $token');
    final response = await http.get(
      Uri.parse('$_baseUrl/get_cuti_user'), // ganti sesuai URL kamu
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {'status': false, 'message': 'Gagal mengambil data cuti'};
    }
  }



  static Future<Map<String, dynamic>> postIzinJam(Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/tambah_izin_jam');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer your_token',
      },
      body: jsonEncode(data),
    );
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'status': false, 'message': 'Gagal mengirim data'};
    }
  }

  static Future<Map<String, dynamic>> getIzinJam(String token) async {
    final uri = Uri.parse('$_baseUrl/izin_jam_list'); // Ganti URL
    final response = await http.get(uri, headers: {
      'Authorization': token,
    });

    return json.decode(response.body);
  }

  static Future<bool> tambahIzinHarian(String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/izin_harian_post'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: json.encode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception('Failed to submit izin harian');
    }
  }


  static Future<Map<String, dynamic>> getIzinHarian(String token) async {
    final uri = Uri.parse('$_baseUrl/get_izin_harian'); // Ganti URL
    final response = await http.get(uri, headers: {
      'Authorization': token,
    });

    return json.decode(response.body);
  }
  static Future<Map<String, dynamic>> getLastAbsen(String token) async {
    final uri = Uri.parse('$_baseUrl/get_last_absen'); // Ganti URL
    final response = await http.get(uri, headers: {
      'Authorization': token,
    });

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getAbsenHistory(String token) async {
    final uri = Uri.parse('$_baseUrl/get_history_absen'); // Ganti URL
    final response = await http.get(uri, headers: {
      'Authorization': token,
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {'status': false, 'message': 'Gagal mengambil data'};
    }
  }

  static Future<List<dynamic>> fetchPengajuanCuti() async {
    final response = await http.get(Uri.parse('$_baseUrl/cuti_pending'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data cuti');
    }
  }

  static Future<bool> updateStatusCuti(int id, String status) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/approval_cuti'),
      body: {'id': id.toString(), 'status': status},
    );
    return response.statusCode == 200;
  }
  static Future<List<dynamic>> getDivisiList(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/get_divisi'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return [];
    }
  }

  static Future<List<dynamic>> getJabatanList(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/get_jabatan'), // Ganti dengan URL-mu
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body); // langsung karena JSON kamu berupa List
    } else {
      return [];
    }
  }

  static Future<List<dynamic>> getListKaryawan(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/karyawan_all'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data karyawan');
    }
  }

  static Future<bool> hapusKaryawan(String token, String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/karyawan_hapus/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }
  static Future<bool> tambahKaryawan({
    required String token,
    required String nama,
    required String nik,
    required String idDivisi,
    required String idJabatan,
    required String tanggalMasuk,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tambah_karyawan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nama': nama,
          'nik': nik,
          'id_divisi': idDivisi,
          'id_jabatan': idJabatan,
          'tanggal_masuk': tanggalMasuk,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Tambah karyawan gagal: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error saat menambahkan karyawan: $e');
      return false;
    }
  }
  static Future<bool> editKaryawan({
    required String token,
    required String id,
    required String nama,
    required String nik,
    required String idDivisi,
    required String idJabatan,
    required String tanggalMasuk,
    // tambahkan parameter lain jika perlu
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/edit_karyawan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id': id,
        'nama': nama,
        'nik': nik,
        'id_divisi': idDivisi,
        'id_jabatan': idJabatan,
        'tanggal_masuk': tanggalMasuk,
      }),
    );

    return response.statusCode == 200;
  }
  static Future<bool> updateKaryawan({
    required String token,
    required String id,
    required String nama,
    required String nik,
    required String idDivisi,
    required String idJabatan,
    required String tanggalMasuk,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/update_karyawan/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nama': nama,
        'nik': nik,
        'id_divisi': idDivisi,
        'id_jabatan': idJabatan,
        'tanggal_masuk': tanggalMasuk,
      }),
    );
    return response.statusCode == 200;
  }

  // Fungsi untuk mengambil data pengajuan izin harian
  static Future<List<dynamic>> fetchPengajuanIzinHarian() async {
    final url = Uri.parse('$_baseUrl/get_pending_hari'); // Ganti endpoint sesuai backend kamu
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData; // Pastikan response kamu ada key 'data'
    } else {
      throw Exception('Gagal memuat data izin harian');
    }
  }

  // Contoh fungsi update status izin harian
  static Future<bool> updateStatusIzinHarian(int id, String status) async {
    print("Cek Status ijin :" + status);
    final url = Uri.parse('$_baseUrl/update_status_izin_harian');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id': id,
        'status': status,
      }),
    );
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result['success'] == true;
    } else {
      return false;
    }
  }


  // Fungsi untuk mengambil data pengajuan izin jam
  static Future<List<dynamic>> fetchPengajuanIzinJam() async {
    final url = Uri.parse('$_baseUrl/get_pending_jam'); // Ganti endpoint sesuai backend kamu
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData; // Pastikan response kamu ada key 'data'
    } else {
      throw Exception('Gagal memuat data izin jam');
    }
  }

  // Contoh fungsi update status izin jam
  static Future<bool> updateStatusIzinJam(int id, String status) async {
    print("Cek Status ijin :" + status);
    final url = Uri.parse('$_baseUrl/update_status_izin_jam');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id': id,
        'status': status,
      }),
    );
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result['success'] == true;
    } else {
      return false;
    }
  }

  static Future<Map<String, dynamic>> submitIstirahat(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/istirahat'), // Sesuaikan dengan endpoint API Anda
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '$token',
        },
        body: jsonEncode({
          'waktu': DateTime.now().toIso8601String(),
          'status': 'Istirahat',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': false,
          'message': 'Gagal mencatat istirahat. Status code: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Error: $e'
      };
    }
  }
  static Future<List<SlipGajiData>> getSlipGaji(String employeeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/slip-gaji/$employeeId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => SlipGajiData.fromJson(json)).toList();
        } else {
          throw Exception('API Error: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }
  static Future<SlipGajiData?> getSlipGajiByMonth(String employeeId, int year, int month) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/get_by_month/$employeeId/$year/$month'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
print('Cek Slip Gaji : '+response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
          return SlipGajiData.fromJson(jsonResponse);
        }
        return null;
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }
}
