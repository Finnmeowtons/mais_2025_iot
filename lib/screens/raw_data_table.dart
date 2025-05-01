import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:mais_2025_iot/services/api_service.dart';

class RawDataTable extends StatefulWidget {
  final int deviceId; // Device ID to filter data for a specific device
  const RawDataTable({super.key, this.deviceId = 0});

  @override
  State<RawDataTable> createState() => _RawDataTableState();
}

class _RawDataTableState extends State<RawDataTable> {
  late RawDataSource _dataSource;
  final _controller = PaginatorController();

  @override
  void initState() {
    super.initState();
    _dataSource = RawDataSource(deviceId: widget.deviceId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (widget.deviceId == 0) ? Text("Sensor Raw Data") : Text("Device ${widget.deviceId} Sensor Raw Data"),
      ),
      body: AsyncPaginatedDataTable2(
        minWidth: 1500,
        // autoRowsToHeight: true,
        rowsPerPage: 50,
        availableRowsPerPage: const [25, 50, 100],
        showFirstLastButtons: true,
        wrapInCard: true,
        controller: _controller,
        columns: const [
          DataColumn2(label: Text('ID'), numeric: true, fixedWidth: 80),
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
  final int deviceId;

  RawDataSource({required this.deviceId});

  int _lastFetchedPage = 0;
  int _total = 10000;

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
    final page = (startIndex ~/ 50) + 1;
    _lastFetchedPage = page;

    ApiService apiService = ApiService();

    final response = await apiService.getRawData(page, 50, deviceId);
    final List<dynamic> rawList = response['data'];
    final data = List<Map<String, dynamic>>.from(rawList);

    _total = response['total'] ?? data.length;

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
