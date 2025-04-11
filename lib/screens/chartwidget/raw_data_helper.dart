import 'package:fl_chart/fl_chart.dart';
import 'raw_data_point.dart'; // wherever your RawDataPoint class is defined

Future<Map<String, List<FlSpot>>> processChartData(
    List<dynamic> rawJson) async {
  List<RawDataPoint> dataPoints =
      rawJson.map((e) => RawDataPoint.fromJson(e)).toList();

  Map<int, RawDataPoint> groupedByHour = {};
  for (var point in dataPoints) {
    final hour = point.timestamp.hour;
    groupedByHour[hour] = point;
  }

  List<int> sortedHours = groupedByHour.keys.toList()..sort();
  if (sortedHours.length > 10) {
    sortedHours = sortedHours.sublist(sortedHours.length - 10);
  }

  List<FlSpot> temperature = [];
  List<FlSpot> humidity = [];
  List<FlSpot> soilMoistureRaw = [];
  List<FlSpot> soilMoisturePercentage = [];
  List<FlSpot> soilTemperature = [];
  List<FlSpot> soilPh = [];

  for (int i = 0; i < sortedHours.length; i++) {
    var hour = sortedHours[i];
    var point = groupedByHour[hour]!;
    temperature.add(FlSpot(i.toDouble(), point.temperature));
    humidity.add(FlSpot(i.toDouble(), point.humidity));
    soilMoistureRaw.add(FlSpot(i.toDouble(), point.soilMoistureRaw));
    soilMoisturePercentage
        .add(FlSpot(i.toDouble(), point.soilMoisturePercentage));
    soilTemperature.add(FlSpot(i.toDouble(), point.soilTemperature));
    soilPh.add(FlSpot(i.toDouble(), point.soilPh));
  }

  return {
    'temperature': temperature,
    'humidity': humidity,
    'soil_moisture_raw': soilMoistureRaw,
    'soil_moisture_percentage': soilMoisturePercentage,
    'soil_temperature': soilTemperature,
    'soil_ph': soilPh,
  };
}
