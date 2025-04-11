import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mais_2025_iot/screens/graphchart/graph_data_helper.dart';
import 'package:mais_2025_iot/screens/graphchart/graph_line_chart.dart';
import 'package:mais_2025_iot/service/api_service.dart';
import 'package:intl/intl.dart';

class GraphChartScreen extends StatefulWidget {
  final int deviceId;

  const GraphChartScreen({super.key, required this.deviceId});

  @override
  State<GraphChartScreen> createState() => _LineChartScreenState();
}

class _LineChartScreenState extends State<GraphChartScreen> {
  late Future<Map<String, dynamic>> _futureGraphData;

  @override
  void initState() {
    super.initState();
    _futureGraphData = _fetchAndProcessData();
  }

  Future<Map<String, dynamic>> _fetchAndProcessData() async {
    final apiService = ApiService();
    final now = DateTime.now().toLocal(); // Use local time
    final endDate = now;
    final startDate = endDate
        .subtract(const Duration(days: 9)); // Fetch 10 days including today
    final formattedEnd = endDate.toIso8601String();
    final formattedStart = startDate.toIso8601String();

    final rawData = await apiService.getGraphData(
      widget.deviceId,
      formattedStart,
      formattedEnd,
    );

    final processedData = await processGraphData(rawData);
    final List<String> xLabels =
        (processedData['xLabels'] as List<String>? ?? []);

    // If we have fewer than 10 days of data, ensure the last label is the current date
    if (xLabels.isNotEmpty) {
      xLabels[xLabels.length - 1] = DateFormat('MMM d').format(now);
    } else {
      xLabels.add(DateFormat('MMM d').format(now));
    }
    processedData['xLabels'] = xLabels;

    return processedData;
  }

  LineChartBarData _buildLine(List<FlSpot>? spots, Color color) {
    return LineChartBarData(
      spots: spots ?? [],
      isCurved: true,
      color: color, // The color is set here
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _futureGraphData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final graphData = snapshot.data!;
            final temperatureData = graphData['temperature'] as List<FlSpot>?;
            final humidityData = graphData['humidity'] as List<FlSpot>?;
            final soilMoistureData =
                graphData['soil_moisture_percentage'] as List<FlSpot>?;
            final soilPhData = graphData['soil_ph'] as List<FlSpot>?;
            final xLabels = graphData['xLabels'] as List<String>? ?? [];

            final lines = [
              _buildLine(temperatureData, Colors.red),
              _buildLine(humidityData, Colors.blue),
              _buildLine(soilMoistureData, Colors.green),
              _buildLine(soilPhData, Colors.purple),
            ];
            final colors = [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.purple
            ];

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: GraphLineChart(
                lines: lines,
                xLabels: xLabels,
                colors: colors,
              ),
            );
          },
        ),
      ),
    );
  }
}
