import 'package:fl_chart/fl_chart.dart';

class RawData {
  final List<LineChartBarData> lines;
  final double latestHour;

  RawData({required this.lines, required this.latestHour});
}
