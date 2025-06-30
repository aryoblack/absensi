import 'package:Absensi/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/slip_gaji.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slip Gaji',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
      ),
      home: SlipGajiScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SlipGajiModel {
  final String karyawan;
  final String posisi;
  final String divisi;
  final String jabatan;
  final String periode;
  final Map<String, double> pendapatan;
  final Map<String, double> potongan;
  final double totalPendapatan;
  final double totalPotongan;
  final double thp;

  SlipGajiModel({
    required this.karyawan,
    required this.posisi,
    required this.divisi,
    required this.jabatan,
    required this.periode,
    required this.pendapatan,
    required this.potongan,
    required this.totalPendapatan,
    required this.totalPotongan,
    required this.thp,
  });

  factory SlipGajiModel.fromJson(Map<String, dynamic> json) {
    return SlipGajiModel(
      karyawan: json['employee_name'] ?? '',
      posisi: json['posisi'] ?? '',
      divisi: json['divisi'] ?? '',
      jabatan: json['jabatan'] ?? '',
      periode: json['periode'] ?? '',
      pendapatan: Map<String, double>.from(json['pendapatan'] ?? {}),
      potongan: Map<String, double>.from(json['potongan'] ?? {}),
      totalPendapatan: (json['total_pendapatan'] ?? 0).toDouble(),
      totalPotongan: (json['total_potongan'] ?? 0).toDouble(),
      thp: (json['thp'] ?? 0).toDouble(),
    );
  }
}

class SlipGajiScreen extends StatefulWidget {
  @override
  _SlipGajiScreenState createState() => _SlipGajiScreenState();
}

class _SlipGajiScreenState extends State<SlipGajiScreen> {
  SlipGajiModel? slipGaji;
  bool isLoading = false;
  bool isDownloading = false;
  String selectedMonth = '';
  String selectedYear = '';

  final List<String> months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  final int currentYear = DateTime.now().year;

  List<String> get years => List.generate(
    currentYear - 2023 + 1,
        (index) => (2023 + index).toString(),
  );

  @override
  void initState() {
    super.initState();
    // Set default values
    selectedMonth = 'Mei';
    selectedYear = '2025';
    loadSlipGaji();
  }
  int convertMonthNameToInt(String monthName) {
    const monthMap = {
      'Januari': 1,
      'Februari': 2,
      'Maret': 3,
      'April': 4,
      'Mei': 5,
      'Juni': 6,
      'Juli': 7,
      'Agustus': 8,
      'September': 9,
      'Oktober': 10,
      'November': 11,
      'Desember': 12,
    };

    return monthMap[monthName] ?? 1; // Default ke Januari jika tidak ketemu
  }

  Future<void> loadSlipGaji() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Ganti dengan URL API Anda
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final int employeeId = prefs.getInt('id_karyawan') ?? 0;


      // Convert int to String for the API call
      final response = await ApiService.getSlipGajiByMonth(
        employeeId.toString(),
        int.parse(selectedYear),
        convertMonthNameToInt(selectedMonth),
      );
print('Respon cek :' +response!.karyawan);
      // if ( response!= null) {
        setState(() {
          slipGaji = SlipGajiModel(
            karyawan: response.karyawan ?? '',
            divisi: response.divisi ?? '',
            jabatan: response.jabatan ?? '',
            pendapatan: Map<String, double>.from(response.pendapatan ?? {}),
            potongan: Map<String, double>.from(response.potongan ?? {}),
            totalPendapatan: response.totalPendapatan?.toDouble() ?? 0.0,
            totalPotongan: response.totalPotongan?.toDouble() ?? 0.0,
            thp: response.thp?.toDouble() ?? 0.0,
            posisi: '',
            periode: '',
          );
        });
      // } else {
      //   // Handle error - for demo, use dummy data
      //   _loadDummyData();
      // }
    } catch (e) {
      // Handle error - for demo, use dummy data
      // _loadDummyData();
    }

    setState(() {
      isLoading = false;
    });
  }





  Future<void> _downloadPDF() async {
    if (slipGaji == null) return;

    setState(() {
      isDownloading = true;
    });

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.teal50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Slip Gaji',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal800,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green,
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Text(
                          '✓',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 16),

                // Period
                pw.Text(
                  slipGaji!.periode,
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
                ),

                pw.SizedBox(height: 16),

                // Employee Info
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Karyawan',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('Nama: ${slipGaji!.karyawan}'),
                      pw.Text('Divisi: ${slipGaji!.divisi}'),
                      pw.Text('Jabatan: ${slipGaji!.jabatan}'),
                    ],
                  ),
                ),

                pw.SizedBox(height: 24),

                // Pendapatan
                pw.Text(
                  'Pendapatan (Rp)',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                ...slipGaji!.pendapatan.entries.map((entry) =>
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(child: pw.Text(entry.key)),
                        pw.Text(formatCurrency(entry.value)),
                      ],
                    ),
                ),

                pw.SizedBox(height: 16),

                // Total Pendapatan
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.green300),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Pendapatan',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.Text(
                        formatCurrency(slipGaji!.totalPendapatan),
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 24),

                // Potongan
                pw.Text(
                  'Potongan (Rp)',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                ...slipGaji!.potongan.entries.map((entry) =>
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              entry.key,
                              style: pw.TextStyle(fontSize: 12),
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              formatCurrency(entry.value),
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ),

                pw.SizedBox(height: 16),

                // Total Potongan
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.red300),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Potongan',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red800,
                        ),
                      ),
                      pw.Text(
                        formatCurrency(slipGaji!.totalPotongan),
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red800,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 24),

                // THP
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.teal600,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'THP',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        formatCurrency(slipGaji!.thp),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Request storage permission (for Android)
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }

      // Get Downloads directory
      Directory? downloadsDirectory;

      if (Platform.isAndroid) {
        // For Android, use external storage Downloads folder
        downloadsDirectory = Directory('/storage/emulated/0/Download');
        // Alternative: Use getExternalStorageDirectory() and append 'Download'
        // final externalDir = await getExternalStorageDirectory();
        // downloadsDirectory = Directory('${externalDir!.path}/Download');
      } else if (Platform.isIOS) {
        // For iOS, use documents directory (iOS doesn't have direct Downloads access)
        downloadsDirectory = await getApplicationDocumentsDirectory();
      }

      if (downloadsDirectory != null) {
        // Create filename
        final fileName = 'Slip_Gaji_${slipGaji!.karyawan}_${selectedMonth}_${selectedYear}.pdf';
        final filePath = '${downloadsDirectory.path}/$fileName';

        // Save PDF file
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF berhasil diunduh ke: $filePath'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('Tidak dapat mengakses folder Download');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh PDF: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }

    setState(() {
      isDownloading = false;
    });
  }

  String formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Slip Gaji', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedMonth,
                        decoration: InputDecoration(
                          labelText: 'Bulan',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: months.map((month) {
                          return DropdownMenuItem(
                            value: month,
                            child: Text(month),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMonth = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: DropdownSearch<String>(
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Cari tahun...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        items: years,
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: 'Tahun',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        selectedItem: selectedYear,
                        onChanged: (value) {
                          setState(() {
                            selectedYear = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loadSlipGaji,
                    child: Text('Filter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : slipGaji == null
                ? Center(child: Text('Tidak ada data'))
                : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Slip Gaji',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[800],
                              ),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Period
                      Text(
                        slipGaji!.periode,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Employee Info
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Karyawan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            _buildInfoRow('Nama', slipGaji!.karyawan),
                            _buildInfoRow('Divisi', slipGaji!.divisi),
                            _buildInfoRow('Jabatan', slipGaji!.jabatan),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Pendapatan
                      _buildSection('Pendapatan (Rp)', slipGaji!.pendapatan, Colors.green),

                      SizedBox(height: 16),

                      // Total Pendapatan
                      _buildTotalRow('Total Pendapatan', slipGaji!.totalPendapatan, Colors.green),

                      SizedBox(height: 24),

                      // Potongan
                      _buildSection('Potongan (Rp)', slipGaji!.potongan, Colors.red),

                      SizedBox(height: 16),

                      // Total Potongan
                      _buildTotalRow('Total Potongan', slipGaji!.totalPotongan, Colors.red),

                      SizedBox(height: 24),
                      _buildTotalRow('THP (Rp) ', slipGaji!.thp, Colors.green),



                      SizedBox(height: 24),

                      // Download Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isDownloading ? null : _downloadPDF,
                          icon: isDownloading
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : Icon(Icons.download),
                          label: Text(
                            isDownloading ? 'Mengunduh...' : 'Download PDF',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Map<String, double> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        ...items.entries.map((entry) => _buildItemRow(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildItemRow(String label, double amount) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              formatCurrency(amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, MaterialColor color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color[800],
              ),
            ),
          ),
          Text(
            formatCurrency(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color[800],
            ),
          ),
        ],
      ),
    );
  }
}