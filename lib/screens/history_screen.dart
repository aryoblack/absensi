import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HistoryPage extends StatefulWidget {
  final String token;
  const HistoryPage({Key? key, required this.token}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    final response = await http.get(
      Uri.parse('http://your-api-url/api/history'),
      headers: {'Authorization': widget.token},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status']) {
        setState(() {
          history = data['data'];
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          title: const Text('Riwayat Absensi')
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: item['foto'] != null
                  ? Image.network(
                item['foto'].toString().startsWith('http')
                    ? item['foto']
                    : 'http://your-api-url/' + item['foto'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
                  : const Icon(Icons.image_not_supported),
              title: Text(item['status'] ?? ''),
              subtitle: Text(item['waktu'] ?? ''),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Lat: ${item['lat']}'),
                  Text('Lng: ${item['lng']}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
