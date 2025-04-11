import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mais_2025_iot/service/api_service.dart';
import 'package:mais_2025_iot/screens/chartwidget/raw_line_chart.dart';
// import 'package:mais_2025_iot/screens/chartwidget/app_colors.dart';

class RawChartScreen extends StatefulWidget {
  final int deviceId;

  const RawChartScreen({super.key, required this.deviceId});

  @override
  State<RawChartScreen> createState() => _RawChartScreenState();
}

class _RawChartScreenState extends State<RawChartScreen> {
  late Future<List<LineChartBarData>> _futureLines;

  @override
  void initState() {
    super.initState();
    _futureLines = _fetchAndProcessData();
  }

  Future<List<LineChartBarData>> _fetchAndProcessData() async {
    final apiService = ApiService();
    final rawData = await apiService.getRawData(widget.deviceId, limit: 200);

    // Maps to store the hourly sum and count of each sensor reading
    Map<DateTime, Map<String, double>> hourlySum = {};
    Map<DateTime, int> hourlyCount = {};

    for (var item in rawData) {
      // Extract the timestamp string
      String? timestampStr = item['timestamp'];
      if (timestampStr == null) continue; // Skip if timestamp is null

      DateTime? timestamp;
      try {
        // Parse the timestamp string to a local DateTime object
        timestamp = DateTime.parse(timestampStr).toLocal();
        // Create a DateTime object representing the start of the hour
        DateTime hourlyTimestamp = DateTime(
            timestamp.year, timestamp.month, timestamp.day, timestamp.hour);

        // Initialize the hourly sum map for the current hour if it doesn't exist
        hourlySum.putIfAbsent(
            hourlyTimestamp,
            () => {
                  'temperature': 0.0,
                  'humidity': 0.0,
                  'soil_moisture_raw': 0.0,
                  'soil_moisture_percentage': 0.0,
                  'soil_temperature': 0.0,
                  'soil_ph': 0.0
                });
        // Initialize the hourly count map for the current hour if it doesn't exist
        hourlyCount.putIfAbsent(hourlyTimestamp, () => 0);

        // Add the current reading to the hourly sum for each sensor
        hourlySum[hourlyTimestamp]!['temperature'] =
            (hourlySum[hourlyTimestamp]!['temperature']! +
                _parseDouble(item['temperature']));
        hourlySum[hourlyTimestamp]!['humidity'] =
            (hourlySum[hourlyTimestamp]!['humidity']! +
                _parseDouble(item['humidity']));
        hourlySum[hourlyTimestamp]!['soil_moisture_raw'] =
            (hourlySum[hourlyTimestamp]!['soil_moisture_raw']! +
                _parseDouble(item['soil_moisture_raw']));
        hourlySum[hourlyTimestamp]!['soil_moisture_percentage'] =
            (hourlySum[hourlyTimestamp]!['soil_moisture_percentage']! +
                _parseDouble(item['soil_moisture_percentage']));
        hourlySum[hourlyTimestamp]!['soil_temperature'] =
            (hourlySum[hourlyTimestamp]!['soil_temperature']! +
                _parseDouble(item['soil_temperature']));
        hourlySum[hourlyTimestamp]!['soil_ph'] =
            (hourlySum[hourlyTimestamp]!['soil_ph']! +
                _parseDouble(item['soil_ph']));

        // Increment the count for the current hour
        hourlyCount[hourlyTimestamp] = hourlyCount[hourlyTimestamp]! + 1;
      } catch (e) {
        // Ignore if timestamp parsing fails
        continue;
      }
    }

    List<FlSpot> tempSpots = [];
    List<FlSpot> humSpots = [];
    List<FlSpot> smRawSpots = [];
    List<FlSpot> smPercSpots = [];
    List<FlSpot> soilTempSpots = [];
    List<FlSpot> phSpots = [];

    DateTime now = DateTime.now().toLocal();
    DateTime currentHourDateTime =
        DateTime(now.year, now.month, now.day, now.hour);
    // Generate a list of the last 10 hours
    List<DateTime> lastTenHours = List.generate(
            10, (index) => currentHourDateTime.subtract(Duration(hours: index)))
        .reversed
        .toList();

    // Iterate through the last 10 hours to calculate the average sensor readings
    for (var hourlyTimestamp in lastTenHours) {
      if (hourlySum.containsKey(hourlyTimestamp) &&
          hourlyCount.containsKey(hourlyTimestamp) &&
          hourlyCount[hourlyTimestamp]! > 0) {
        final count = hourlyCount[hourlyTimestamp]!;
        // Calculate the average for each sensor and add it as a FlSpot
        tempSpots.add(FlSpot(hourlyTimestamp.millisecondsSinceEpoch.toDouble(),
            hourlySum[hourlyTimestamp]!['temperature']! / count));
        humSpots.add(FlSpot(hourlyTimestamp.millisecondsSinceEpoch.toDouble(),
            hourlySum[hourlyTimestamp]!['humidity']! / count));
        smRawSpots.add(FlSpot(hourlyTimestamp.millisecondsSinceEpoch.toDouble(),
            hourlySum[hourlyTimestamp]!['soil_moisture_raw']! / count));
        smPercSpots.add(FlSpot(
            hourlyTimestamp.millisecondsSinceEpoch.toDouble(),
            hourlySum[hourlyTimestamp]!['soil_moisture_percentage']! / count));
        soilTempSpots.add(FlSpot(
            hourlyTimestamp.millisecondsSinceEpoch.toDouble(),
            hourlySum[hourlyTimestamp]!['soil_temperature']! / count));
        phSpots.add(FlSpot(hourlyTimestamp.millisecondsSinceEpoch.toDouble(),
            hourlySum[hourlyTimestamp]!['soil_ph']! / count));
      } else {
        // If no data for the hour, add a FlSpot with a value of 0
        tempSpots
            .add(FlSpot(hourlyTimestamp.millisecondsSinceEpoch.toDouble(), 0));
        humSpots
            .add(FlSpot(hourlyTimestamp.millisecondsSinceEpoch.toDouble(), 0));
        smRawSpots
            .add(FlSpot(hourlyTimestamp.millisecondsSinceEpoch.toDouble(), 0));
        smPercSpots
            .add(FlSpot(hourlyTimestamp.millisecondsSinceEpoch.toDouble(), 0));
        soilTempSpots
            .add(FlSpot(hourlyTimestamp.millisecondsSinceEpoch.toDouble(), 0));
        phSpots
            .add(FlSpot(hourlyTimestamp.millisecondsSinceEpoch.toDouble(), 0));
      }
    }

    return [
      // TEMPERATURE line
      LineChartBarData(
          spots: tempSpots,
          isCurved: true,
          color: Colors.red,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false)),
      // HUMIDITY line
      LineChartBarData(
          spots: humSpots,
          isCurved: true,
          color: Colors.blue,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false)),
      // SOIL MOISTURE RAW line
      LineChartBarData(
          spots: smRawSpots,
          isCurved: true,
          color: Colors.brown,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false)),
      // SOIL MOISTURE PERCENTAGE line
      LineChartBarData(
          spots: smPercSpots,
          isCurved: true,
          color: Colors.green,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false)),
      // SOIL TEMPERATURE line
      LineChartBarData(
          spots: soilTempSpots,
          isCurved: true,
          color: Colors.orange,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false)),
      // SOIL PH line
      LineChartBarData(
          spots: phSpots,
          isCurved: true,
          color: Colors.purple,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false)),
    ];
  }

  // Helper function to safely parse a dynamic value to a double
  double _parseDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    if (value is double) {
      return value;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now().toLocal();
    DateTime currentHourDateTime =
        DateTime(now.year, now.month, now.day, now.hour);
    // Calculate the maximum X-axis value (current hour in milliseconds)
    double maxX = currentHourDateTime.millisecondsSinceEpoch.toDouble();
    // Calculate the minimum X-axis value (10 hours ago in milliseconds)
    double minX = currentHourDateTime
        .subtract(Duration(hours: 9))
        .millisecondsSinceEpoch
        .toDouble();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: FutureBuilder<List<LineChartBarData>>(
          future: _futureLines,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return Center(child: Text('Error: ${snapshot.error}'));

            final lines = snapshot.data!;
            final colors =
                lines.map((line) => line.color ?? Colors.black).toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: RawLineChart(
                lines: lines,
                maxX: maxX,
                minX: minX,
                colors: colors,
              ),
            );
          },
        ),
      ),
    );
  }
}
