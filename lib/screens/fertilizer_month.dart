import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:mais_2025_iot/screens/fertilizer_day.dart';
import 'package:mais_2025_iot/services/api_service.dart';

class FertilizerMonth extends StatefulWidget {
  const FertilizerMonth({super.key});

  @override
  State<FertilizerMonth> createState() => _FertilizerMonthState();
}

class _FertilizerMonthState extends State<FertilizerMonth> {
  final apiService = ApiService();

  final List<Map<String, String>> fertilizerData = [
    {'month': 'January', 'fertilizer': '20-20'},
    {'month': 'February', 'fertilizer': 'Urea'},
    {'month': 'March', 'fertilizer': 'Urea'},
    {'month': 'April', 'fertilizer': 'Compost'},
    {'month': 'May', 'fertilizer': 'Ammonium Sulfate'}
  ];

  final List<String> monthNames = [
    '', // to align index 1 with January
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    loadMostRecommendedFertilizer();
  }

  void loadMostRecommendedFertilizer() async {
    try {
      final recommendations = await apiService.getMostRecommendedFertilizerMonthly();

      for (var entry in recommendations) {
        String monthStr = entry['month']; // e.g., '2025-04'
        int monthNumber = int.parse(monthStr.split('-')[1]); // '04' => 4
        String monthName = monthNames[monthNumber];
        String recommended = entry['recommendation'];

        final index = fertilizerData.indexWhere((element) => element['month'] == monthName);
        if (index != -1) {
          fertilizerData[index]['fertilizer'] = recommended;
        }
      }

      // Wait 3 seconds before showing the table
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        isLoaded = true;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  bool isLoaded = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Fertilizer')),
      body: isLoaded
          ? DataTable2(
        showCheckboxColumn: false, // ✅ Hides the checkbox
        columnSpacing: 16,
        horizontalMargin: 16,
        minWidth: 300,
        columns: const [
          DataColumn2(label: Text('Month'), size: ColumnSize.L),
          DataColumn2(label: Text('Fertilizer'), size: ColumnSize.L),
        ],
        rows: fertilizerData.map((row) {
          return DataRow(
            // ✅ Now uses onTap instead of onSelectChanged
            cells: [
              DataCell(
                Text(row['month']!),
                onTap: () {
                  int selectedMonth = monthNames.indexOf(row['month']!);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FertilizerDay(month: selectedMonth),
                    ),
                  );
                },
              ),
              DataCell(Text(row['fertilizer']!)),
            ],
          );
        }).toList(),
      )
          : const Center(child: CircularProgressIndicator()),

    );
  }

}
