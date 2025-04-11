import 'package:fl_chart/fl_chart.dart';
import 'graph_data_point.dart';
import 'package:intl/intl.dart';

Future<Map<String, dynamic>> processGraphData(List<dynamic> rawJson) async {
  List<GraphDataPoint> dataPoints =
      rawJson.map((e) => GraphDataPoint.fromJson(e)).toList();

  // Calculate the range of the last 10 days
  final now = DateTime.now().toLocal();
  final endDate = now;
  final startDate = endDate.subtract(const Duration(days: 9));

  // Generate a list of all dates within the range
  List<String> allDays = [];
  for (int i = 0; i < 10; i++) {
    allDays
        .add(DateFormat('yyyy-MM-dd').format(startDate.add(Duration(days: i))));
  }

  // Group the raw data by date
  Map<String, List<GraphDataPoint>> groupedByDay = {};
  for (var point in dataPoints) {
    final day = DateFormat('yyyy-MM-dd').format(point.timestamp.toLocal());
    groupedByDay.putIfAbsent(day, () => []).add(point);
  }

  List<FlSpot> temperature = [];
  List<FlSpot> humidity = [];
  List<FlSpot> soilMoisturePercentage = [];
  List<FlSpot> soilPh = [];
  List<String> xLabels = [];

  for (int i = 0; i < allDays.length; i++) {
    final day = allDays[i];
    final pointsForDay = groupedByDay[day];

    double avgTemperature = 0;
    double avgHumidity = 0;
    double avgSoilMoisture = 0;
    double avgSoilPh = 0;

    if (pointsForDay != null && pointsForDay.isNotEmpty) {
      avgTemperature =
          pointsForDay.map((p) => p.temperature).reduce((a, b) => a + b) /
              pointsForDay.length;
      avgHumidity =
          pointsForDay.map((p) => p.humidity).reduce((a, b) => a + b) /
              pointsForDay.length;
      avgSoilMoisture = pointsForDay
              .map((p) => p.soilMoisturePercentage)
              .reduce((a, b) => a + b) /
          pointsForDay.length;
      avgSoilPh = pointsForDay.map((p) => p.soilPh).reduce((a, b) => a + b) /
          pointsForDay.length;
    }

    temperature.add(FlSpot(i.toDouble(), avgTemperature));
    humidity.add(FlSpot(i.toDouble(), avgHumidity));
    soilMoisturePercentage.add(FlSpot(i.toDouble(), avgSoilMoisture));
    soilPh.add(FlSpot(i.toDouble(), avgSoilPh));
    xLabels.add(DateFormat('MMM d').format(DateTime.parse(day)));
  }

  return {
    'temperature': temperature,
    'humidity': humidity,
    'soil_moisture_percentage': soilMoisturePercentage,
    'soil_ph': soilPh,
    'xLabels': xLabels,
  };
}
