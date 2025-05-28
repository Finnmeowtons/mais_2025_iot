import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

class IrrigationDay extends StatefulWidget {
  final int month;
  const IrrigationDay({super.key, required this.month});

  @override
  State<IrrigationDay> createState() => _IrrigationDayState();
}

class _IrrigationDayState extends State<IrrigationDay> {
  List<Map<String, String>> filteredIrrigationData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDailyIrrigationData();
  }

  void loadDailyIrrigationData() {
    // Static irrigation status data for Jan–Apr (example)
    final List<Map<String, String>> staticData = [
      {'date': '2025-01-01', 'status': 'Done'},
      {'date': '2025-01-02', 'status': 'Not Done'},
      {'date': '2025-01-03', 'status': 'Done'},
      {'date': '2025-01-04', 'status': 'Done'},
      {'date': '2025-01-05', 'status': 'Not Done'},
      {'date': '2025-02-01', 'status': 'Done'},
      {'date': '2025-02-02', 'status': 'Not Done'},
      {'date': '2025-02-03', 'status': 'Done'},
      {'date': '2025-03-01', 'status': 'Done'},
      {'date': '2025-03-02', 'status': 'Done'},
      {'date': '2025-04-01', 'status': 'Not Done'},
      {'date': '2025-04-02', 'status': 'Done'},
    ];

    // Filter by selected month
    final filtered = staticData.where((item) {
      final dateStr = item['date'] ?? '';
      final date = DateTime.tryParse(dateStr);
      if (date == null) return false;
      return date.month == widget.month;
    }).toList();

    setState(() {
      filteredIrrigationData = filtered;
      isLoading = false;
    });
  }

  String getMonthName(int month) {
    return [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ][month];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${getMonthName(widget.month)} Irrigation Status'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          columns: const [
            DataColumn2(label: Text('Date'), size: ColumnSize.S),
            DataColumn(label: Text('Status')),
          ],
          rows: filteredIrrigationData.map((item) {
            return DataRow(cells: [
              DataCell(Text(item['date'] ?? '-')),
              DataCell(Text(item['status'] ?? '-')),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
