class GraphDataPoint {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double soilMoisturePercentage;
  final double soilPh;

  GraphDataPoint({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.soilMoisturePercentage,
    required this.soilPh,
  });

  factory GraphDataPoint.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to double
    double? parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value);
      }
      return null;
    }

    return GraphDataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      temperature: parseDouble(json['temperature']) ?? 0.0,
      humidity: parseDouble(json['humidity']) ?? 0.0,
      soilMoisturePercentage:
          parseDouble(json['soil_moisture_percentage']) ?? 0.0,
      soilPh: parseDouble(json['soil_ph']) ?? 0.0,
    );
  }
}
