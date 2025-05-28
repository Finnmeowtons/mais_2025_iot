import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:mais_2025_iot/screens/irrigation_day.dart';

class IrrigationMonth extends StatefulWidget {
  const IrrigationMonth({super.key});

  @override
  State<IrrigationMonth> createState() => _IrrigationMonthState();
}

class _IrrigationMonthState extends State<IrrigationMonth> {
  final List<Map<String, String>> irrigationData = [
    {'month': 'January', 'status': 'Done'},
    {'month': 'February', 'status': 'Done'},
    {'month': 'March', 'status': 'Done'},
    {'month': 'April', 'status': 'Done'},
    {'month': 'May', 'status': 'Done'},
  ];

  final List<String> monthNames = [
    '', // to align index 1 with January
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    // Simulate a delay to load data (like fetching from API)
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isLoaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Irrigation'), actions: [],),
      body: isLoaded
          ? DataTable2(
        showCheckboxColumn: false,
        columnSpacing: 16,
        horizontalMargin: 16,
        minWidth: 300,
        columns: const [
          DataColumn2(label: Text('Month'), size: ColumnSize.L),
          DataColumn2(label: Text('Status'), size: ColumnSize.L),
        ],
        rows: irrigationData.map((row) {
          return DataRow(
            cells: [
              DataCell(onTap: (){
                int selectedMonth = monthNames.indexOf(row['month']!);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IrrigationDay(month: selectedMonth),
                ));
              },Text(row['month']!)),
              DataCell(Text(row['status']!)),
            ],
          );
        }).toList(),
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
