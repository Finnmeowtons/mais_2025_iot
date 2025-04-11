import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:http/http.dart' as http;

class RawDataTable extends StatefulWidget {
  const RawDataTable({super.key});

  @override
  State<RawDataTable> createState() => _RawDataTableState();
}

class _RawDataTableState extends State<RawDataTable> {
  final _dataSource = RawDataSource();
  final _controller = PaginatorController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Raw Sensor Data")),
      body: AsyncPaginatedDataTable2(
        
        minWidth: 1500,
        // autoRowsToHeight: true,
        rowsPerPage: 50,
        availableRowsPerPage: const [25, 50, 100],
        showFirstLastButtons: true,
        wrapInCard: true,
        controller: _controller,
        columns: const [
          DataColumn2(label: Text('ID'), numeric: true, fixedWidth: 65),
          DataColumn2(label: Text('Device ID'), numeric: true, fixedWidth: 115),
          DataColumn2(label: Text('Temp'), numeric: true, fixedWidth: 95),
          DataColumn2(label: Text('Humidity'), numeric: true, fixedWidth: 113),
          DataColumn2(label: Text('Moisture Raw'), numeric: true, fixedWidth: 143),
          DataColumn2(label: Text('Moisture %'), numeric: true, fixedWidth: 128),
          DataColumn2(label: Text('Soil Temp'), numeric: true, fixedWidth: 119),
          DataColumn2(label: Text('Soil pH'), numeric: true, fixedWidth: 113),
          DataColumn2(label: Text('N'), numeric: true, fixedWidth: 100),
          DataColumn2(label: Text('K'), numeric: true, fixedWidth: 100),
          DataColumn2(label: Text('P'), numeric: true, fixedWidth: 100),
          DataColumn2(label: Text('Timestamp')),
        ],
        source: _dataSource,
        errorBuilder: (e) => Center(child: Text("Error: $e")),
        empty: const Center(child: Text("No data found")),
        loading: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class RawDataSource extends AsyncDataTableSource {
  int _lastFetchedPage = 0;
  int _total = 10000;

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
    final page = (startIndex ~/ 50) + 1;
    _lastFetchedPage = page;
    final response = await http.get(Uri.parse(
        'http://192.168.68.104:3000/api/raw-data?page=$page&limit=50'));

    if (response.statusCode != 200) {
      throw Exception("Failed to load data");
    }

    final Map<String, dynamic> json = jsonDecode(response.body);
    final List<dynamic> rawList = json['data'];
    final data = List<Map<String, dynamic>>.from(rawList);

    _total = json['total'] ?? data.length;

    final rows = data.map((row) {
      return DataRow(cells: [
        DataCell(Text(row['id'].toString())),
        DataCell(Text(row['device_id'].toString())),
        DataCell(Text(row['temperature'].toString())),
        DataCell(Text(row['humidity'].toString())),
        DataCell(Text(row['soil_moisture_raw'].toString())),
        DataCell(Text(row['soil_moisture_percentage'].toString())),
        DataCell(Text(row['soil_temperature'].toString())),
        DataCell(Text(row['soil_ph']?.toString() ?? '')),
        DataCell(Text(row['nitrogen']?.toString() ?? '')),
        DataCell(Text(row['phosphorus']?.toString() ?? '')),
        DataCell(Text(row['potassium']?.toString() ?? '')),
        DataCell(Text(row['timestamp'].toString())),
      ]);
    }).toList();

    return AsyncRowsResponse(_total, rows);
  }


  @override
  int get selectedRowCount => 0;
}
