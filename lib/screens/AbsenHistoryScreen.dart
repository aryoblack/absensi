import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AbsenHistoryScreen extends StatefulWidget {
  const AbsenHistoryScreen({super.key});

  @override
  State<AbsenHistoryScreen> createState() => _AbsenHistoryScreenState();
}

class _AbsenHistoryScreenState extends State<AbsenHistoryScreen> {
  List<dynamic> _history = [];
  List<dynamic> _filteredHistory = [];
  bool _loading = true;
  String? token;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    final response = await ApiService().getAbsenHistory(token!);

    if (response['status'] == true) {
      setState(() {
        _history = response['data'];
        _loading = false;
      });
      _applyFilter(); // Apply initial filter
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedDateRange != null) {
        _filteredHistory = _history.where((absen) {
          DateTime waktu = DateTime.parse(absen['waktu']);
          return waktu.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
              waktu.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
        }).toList();
      } else {
        _filteredHistory = _history.where((absen) {
          DateTime waktu = DateTime.parse(absen['waktu']);
          return waktu.month == selectedMonth && waktu.year == selectedYear;
        }).toList();
      }
    });
  }

  List<DropdownMenuItem<int>> _buildYearItems() {
    final currentYear = DateTime.now().year;
    return List.generate(5, (i) {
      int year = currentYear - i;
      return DropdownMenuItem(value: year, child: Text('$year'));
    });
  }

  List<DropdownMenuItem<int>> _buildMonthItems() {
    return List.generate(12, (i) {
      int month = i + 1;
      return DropdownMenuItem(
        value: month,
        child: Text(DateFormat.MMMM().format(DateTime(0, month))),
      );
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _applyFilter();
    }
  }

  void _resetFilter() {
    setState(() {
      _selectedDateRange = null;
    });
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absen'),
        backgroundColor: Colors.teal,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                DropdownButton<int>(
                  value: selectedMonth,
                  items: _buildMonthItems(),
                  onChanged: _selectedDateRange == null
                      ? (value) {
                    setState(() {
                      selectedMonth = value!;
                    });
                    _applyFilter();
                  }
                      : null, // disable if date range is active
                ),
                DropdownButton<int>(
                  value: selectedYear,
                  items: _buildYearItems(),
                  onChanged: _selectedDateRange == null
                      ? (value) {
                    setState(() {
                      selectedYear = value!;
                    });
                    _applyFilter();
                  }
                      : null,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: const Text("Pilih Rentang Tanggal"),
                  onPressed: _selectDateRange,
                ),
                if (_selectedDateRange != null)
                  Text(
                    "${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                TextButton(
                  onPressed: _resetFilter,
                  child: const Text('Reset Filter'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredHistory.isEmpty
                ? const Center(child: Text('Tidak ada data absen.'))
                : ListView.builder(
              itemCount: _filteredHistory.length,
              itemBuilder: (context, index) {
                final absen = _filteredHistory[index];
                final waktu = DateFormat('dd MMM yyyy – HH:mm')
                    .format(DateTime.parse(absen['waktu']));
                final status = absen['status'];
                final lat = absen['lat'];
                final lng = absen['lng'];
                final fotoUrl =
                    'https://app.unchu.id/${absen['foto']}';

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(fotoUrl),
                    ),
                    title: Text('$status • $waktu'),
                    subtitle: Text('Lokasi: ($lat, $lng)'),
                    trailing: Icon(
                      status == 'Masuk'
                          ? Icons.login
                          : Icons.logout,
                      color: status == 'Masuk'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
