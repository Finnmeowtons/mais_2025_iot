import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:mais_2025_iot/services/api_service.dart';

class FertilizerDay extends StatefulWidget {
  final int month;
  const FertilizerDay({super.key, required this.month});

  @override
  State<FertilizerDay> createState() => _FertilizerDayState();
}

class _FertilizerDayState extends State<FertilizerDay> {
  final apiService = ApiService();
  List<Map<String, dynamic>> filteredRecommendations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDailyRecommendations();
  }

  void loadDailyRecommendations() async {
    // Your static data for Jan-April
    final List<Map<String, dynamic>> staticData = [
      // January
      {'date': '2025-01-01', 'recommendation': '20-20'},
      {'date': '2025-01-02', 'recommendation': '20-20'},
      {'date': '2025-01-03', 'recommendation': 'DAP'},
      {'date': '2025-01-04', 'recommendation': '20-20'},
      {'date': '2025-01-05', 'recommendation': 'Urea'},
      {'date': '2025-01-06', 'recommendation': '20-20'},
      {'date': '2025-01-07', 'recommendation': '20-20'},
      {'date': '2025-01-08', 'recommendation': '20-20'},
      {'date': '2025-01-09', 'recommendation': 'DAP'},
      {'date': '2025-01-10', 'recommendation': 'Urea'},
      {'date': '2025-01-11', 'recommendation': '20-20'},
      {'date': '2025-01-12', 'recommendation': 'DAP'},
      {'date': '2025-01-13', 'recommendation': '20-20'},
      {'date': '2025-01-14', 'recommendation': 'Urea'},
      {'date': '2025-01-15', 'recommendation': '20-20'},
      {'date': '2025-01-16', 'recommendation': '20-20'},
      {'date': '2025-01-17', 'recommendation': 'DAP'},
      {'date': '2025-01-18', 'recommendation': '20-20'},
      {'date': '2025-01-19', 'recommendation': '20-20'},
      {'date': '2025-01-20', 'recommendation': '20-20'},
      {'date': '2025-01-21', 'recommendation': 'Urea'},
      {'date': '2025-01-22', 'recommendation': '20-20'},
      {'date': '2025-01-23', 'recommendation': 'DAP'},
      {'date': '2025-01-24', 'recommendation': '20-20'},
      {'date': '2025-01-25', 'recommendation': '20-20'},
      {'date': '2025-01-26', 'recommendation': '20-20'},
      {'date': '2025-01-27', 'recommendation': 'Urea'},
      {'date': '2025-01-28', 'recommendation': '20-20'},
      {'date': '2025-01-29', 'recommendation': '20-20'},
      {'date': '2025-01-30', 'recommendation': '20-20'},
      {'date': '2025-01-31', 'recommendation': 'DAP'},

      // February
      {'date': '2025-02-01', 'recommendation': 'Urea'},
      {'date': '2025-02-02', 'recommendation': 'DAP'},
      {'date': '2025-02-03', 'recommendation': 'Urea'},
      {'date': '2025-02-04', 'recommendation': 'Urea'},
      {'date': '2025-02-05', 'recommendation': 'Urea'},
      {'date': '2025-02-06', 'recommendation': '20-20'},
      {'date': '2025-02-07', 'recommendation': 'Urea'},
      {'date': '2025-02-08', 'recommendation': 'DAP'},
      {'date': '2025-02-09', 'recommendation': 'Urea'},
      {'date': '2025-02-10', 'recommendation': 'Urea'},
      {'date': '2025-02-11', 'recommendation': 'Urea'},
      {'date': '2025-02-12', 'recommendation': 'DAP'},
      {'date': '2025-02-13', 'recommendation': 'Urea'},
      {'date': '2025-02-14', 'recommendation': 'Urea'},
      {'date': '2025-02-15', 'recommendation': 'Urea'},
      {'date': '2025-02-16', 'recommendation': 'DAP'},
      {'date': '2025-02-17', 'recommendation': 'Urea'},
      {'date': '2025-02-18', 'recommendation': 'Urea'},
      {'date': '2025-02-19', 'recommendation': '20-20'},
      {'date': '2025-02-20', 'recommendation': 'Urea'},
      {'date': '2025-02-21', 'recommendation': 'Urea'},
      {'date': '2025-02-22', 'recommendation': 'Urea'},
      {'date': '2025-02-23', 'recommendation': 'DAP'},
      {'date': '2025-02-24', 'recommendation': 'Urea'},
      {'date': '2025-02-25', 'recommendation': 'Urea'},
      {'date': '2025-02-26', 'recommendation': '20-20'},
      {'date': '2025-02-27', 'recommendation': 'Urea'},
      {'date': '2025-02-28', 'recommendation': 'Urea'},

      // March
      {'date': '2025-03-01', 'recommendation': 'Urea'},
      {'date': '2025-03-02', 'recommendation': 'Urea'},
      {'date': '2025-03-03', 'recommendation': 'Urea'},
      {'date': '2025-03-04', 'recommendation': 'DAP'},
      {'date': '2025-03-05', 'recommendation': 'Urea'},
      {'date': '2025-03-06', 'recommendation': '20-20'},
      {'date': '2025-03-07', 'recommendation': 'Urea'},
      {'date': '2025-03-08', 'recommendation': 'Urea'},
      {'date': '2025-03-09', 'recommendation': 'DAP'},
      {'date': '2025-03-10', 'recommendation': 'Urea'},
      {'date': '2025-03-11', 'recommendation': 'Urea'},
      {'date': '2025-03-12', 'recommendation': 'Urea'},
      {'date': '2025-03-13', 'recommendation': 'DAP'},
      {'date': '2025-03-14', 'recommendation': 'Urea'},
      {'date': '2025-03-15', 'recommendation': 'Urea'},
      {'date': '2025-03-16', 'recommendation': '20-20'},
      {'date': '2025-03-17', 'recommendation': 'Urea'},
      {'date': '2025-03-18', 'recommendation': 'Urea'},
      {'date': '2025-03-19', 'recommendation': 'Urea'},
      {'date': '2025-03-20', 'recommendation': 'DAP'},
      {'date': '2025-03-21', 'recommendation': 'Urea'},
      {'date': '2025-03-22', 'recommendation': 'Urea'},
      {'date': '2025-03-23', 'recommendation': 'Urea'},
      {'date': '2025-03-24', 'recommendation': 'Urea'},
      {'date': '2025-03-25', 'recommendation': 'Urea'},
      {'date': '2025-03-26', 'recommendation': 'DAP'},
      {'date': '2025-03-27', 'recommendation': 'Urea'},
      {'date': '2025-03-28', 'recommendation': '20-20'},
      {'date': '2025-03-29', 'recommendation': 'Urea'},
      {'date': '2025-03-30', 'recommendation': 'Urea'},
      {'date': '2025-03-31', 'recommendation': 'Urea'},

      // April (1–6)
      {'date': '2025-04-01', 'recommendation': 'Phosphorus'},
      {'date': '2025-04-02', 'recommendation': 'DAP'},
      {'date': '2025-04-03', 'recommendation': '20-20'},
      {'date': '2025-04-04', 'recommendation': 'Urea'},
      {'date': '2025-04-05', 'recommendation': 'Phosphorus'},
      {'date': '2025-04-06', 'recommendation': 'DAP'},
    ];


    try {
      final apiData = await apiService.getDayFertilizerRecommendations();

      // Combine static data with API data
      final combined = [...staticData, ...apiData];

      // Filter by the selected month
      final filtered = combined.where((item) {
        final dateStr = item['date'] as String? ?? '';
        final date = DateTime.tryParse(dateStr);
        if (date == null) return false;
        return date.month == widget.month;
      }).toList();

      setState(() {
        filteredRecommendations = List<Map<String, dynamic>>.from(filtered);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading daily recs: $e');
      setState(() {
        isLoading = false;
      });
    }
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
        title: Text('${getMonthName(widget.month)} Daily Recommendations'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          columns: const [
            DataColumn2(
              label: Text('Date'),
              size: ColumnSize.S,
            ),
            DataColumn(
              label: Text('Recommendation'),
            ),
          ],
          rows: filteredRecommendations.map((item) {
            return DataRow(cells: [
              DataCell(Text(item['date'] ?? '-')),
              DataCell(Text(item['recommendation'] ?? '-')),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
