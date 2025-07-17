import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class UploadDokumenScreen extends StatefulWidget {
  const UploadDokumenScreen({super.key});

  @override
  State<UploadDokumenScreen> createState() => _UploadDokumenScreenState();
}

class _UploadDokumenScreenState extends State<UploadDokumenScreen> {
  final ImagePicker _picker = ImagePicker();

  // File variables for each document type
  File? ktpFile;
  File? npwpFile;
  File? kkFile;
  File? ijazahFile;

  // Loading states
  bool isUploading = false;
  Map<String, bool> uploadingStates = {
    'ktp': false,
    'npwp': false,
    'kk': false,
    'ijazah': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Upload Dokumen',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal[700],
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: Colors.teal[700],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upload Dokumen Persyaratan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Silakan upload dokumen sesuai dengan persyaratan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Document Upload Cards
              _buildDocumentCard(
                title: 'KTP (Kartu Tanda Penduduk)',
                subtitle: 'Upload foto KTP yang masih berlaku',
                icon: Icons.credit_card,
                file: ktpFile,
                onTap: () => _pickDocument('ktp'),
                isUploading: uploadingStates['ktp']!,
              ),

              const SizedBox(height: 16),

              _buildDocumentCard(
                title: 'NPWP (Nomor Pokok Wajib Pajak)',
                subtitle: 'Upload foto NPWP atau dokumen pajak',
                icon: Icons.receipt_long,
                file: npwpFile,
                onTap: () => _pickDocument('npwp'),
                isUploading: uploadingStates['npwp']!,
              ),

              const SizedBox(height: 16),

              _buildDocumentCard(
                title: 'KK (Kartu Keluarga)',
                subtitle: 'Upload foto Kartu Keluarga',
                icon: Icons.family_restroom,
                file: kkFile,
                onTap: () => _pickDocument('kk'),
                isUploading: uploadingStates['kk']!,
              ),

              const SizedBox(height: 16),

              _buildDocumentCard(
                title: 'Ijazah',
                subtitle: 'Upload foto ijazah terakhir',
                icon: Icons.school,
                file: ijazahFile,
                onTap: () => _pickDocument('ijazah'),
                isUploading: uploadingStates['ijazah']!,
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canSubmit() && !isUploading ? _submitDocuments : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: isUploading
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Mengirim...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                      : const Text(
                    'Kirim Dokumen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Progress indicator
              if (_getUploadedCount() > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_getUploadedCount()}/4 dokumen telah diupload',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? file,
    required VoidCallback onTap,
    required bool isUploading,
  }) {
    final isUploaded = file != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUploaded ? Colors.green[300]! : Colors.grey[300]!,
          width: isUploaded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: isUploading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isUploaded ? Colors.green[100] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isUploaded ? Icons.check_circle : icon,
                  color: isUploaded ? Colors.green[700] : Colors.blue[700],
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUploaded ? 'Dokumen berhasil diupload' : subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUploaded ? Colors.green[700] : Colors.grey[600],
                      ),
                    ),
                    if (isUploaded && file != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        file!.path.split('/').last,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Status/Action
              if (isUploading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else if (isUploaded)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _viewDocument(file!),
                      icon: Icon(
                        Icons.visibility,
                        color: Colors.teal[700],
                      ),
                      tooltip: 'Lihat dokumen',
                    ),
                    IconButton(
                      onPressed: onTap,
                      icon: Icon(
                        Icons.edit,
                        color: Colors.orange[700],
                      ),
                      tooltip: 'Ganti dokumen',
                    ),
                  ],
                )
              else
                Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.grey[400],
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDocument(String type) async {
    setState(() {
      uploadingStates[type] = true;
    });

    try {
      final result = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => _buildPickerBottomSheet(),
      );

      if (result != null) {
        File? pickedFile;

        if (result == 'camera') {
          final XFile? image = await _picker.pickImage(
            source: ImageSource.camera,
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
          );
          if (image != null) {
            pickedFile = File(image.path);
          }
        } else if (result == 'gallery') {
          final XFile? image = await _picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
          );
          if (image != null) {
            pickedFile = File(image.path);
          }
        } else if (result == 'file') {
          final FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
          );
          if (result != null) {
            pickedFile = File(result.files.single.path!);
          }
        }

        if (pickedFile != null) {
          setState(() {
            switch (type) {
              case 'ktp':
                ktpFile = pickedFile;
                break;
              case 'npwp':
                npwpFile = pickedFile;
                break;
              case 'kk':
                kkFile = pickedFile;
                break;
              case 'ijazah':
                ijazahFile = pickedFile;
                break;
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Dokumen ${type.toUpperCase()} berhasil dipilih'),
                backgroundColor: Colors.green[600],
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        uploadingStates[type] = false;
      });
    }
  }

  Widget _buildPickerBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pilih Sumber Dokumen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Kamera'),
            subtitle: const Text('Ambil foto menggunakan kamera'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galeri'),
            subtitle: const Text('Pilih dari galeri foto'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('File'),
            subtitle: const Text('Pilih file PDF atau gambar'),
            onTap: () => Navigator.pop(context, 'file'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _viewDocument(File file) {
    // Implement document viewing logic
    // You can use packages like flutter_pdfview for PDF or photo_view for images
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Melihat dokumen: ${file.path.split('/').last}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _canSubmit() {
    return ktpFile != null && npwpFile != null && kkFile != null && ijazahFile != null;
  }

  int _getUploadedCount() {
    int count = 0;
    if (ktpFile != null) count++;
    if (npwpFile != null) count++;
    if (kkFile != null) count++;
    if (ijazahFile != null) count++;
    return count;
  }

  Future<void> _submitDocuments() async {
    if (!_canSubmit()) return;

    setState(() {
      isUploading = true;
    });

    try {
      // Simulate API call
      // await Future.delayed(const Duration(seconds: 2));
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      // Replace with actual API call
      // Here you would typically upload files to your server
      // Example:
      final response = await ApiService.uploadDocument(token!,ktpFile!, npwpFile!,kkFile!,ijazahFile!);
      if (response['status']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Semua dokumen berhasil diupload!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate back or to next screen
          Navigator.pop(context);
        }
      }else{
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Error uploading documents: ${response['message']}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading documents: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }
}