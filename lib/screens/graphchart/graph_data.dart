import 'package:fl_chart/fl_chart.dart';

class GraphData {
  final List<LineChartBarData> lines;
  final double latestHour;

  GraphData({required this.lines, required this.latestHour});
}
