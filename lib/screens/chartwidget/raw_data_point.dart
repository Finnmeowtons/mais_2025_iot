class RawDataPoint {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double soilMoistureRaw;
  final double soilMoisturePercentage;
  final double soilTemperature;
  final double soilPh;

  RawDataPoint({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.soilMoistureRaw,
    required this.soilMoisturePercentage,
    required this.soilTemperature,
    required this.soilPh,
  });

  factory RawDataPoint.fromJson(Map<String, dynamic> json) {
    return RawDataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      temperature: json['temperature']?.toDouble() ?? 0.0,
      humidity: json['humidity']?.toDouble() ?? 0.0,
      soilMoistureRaw: json['soil_moisture_raw']?.toDouble() ?? 0.0,
      soilMoisturePercentage:
          json['soil_moisture_percentage']?.toDouble() ?? 0.0,
      soilTemperature: json['soil_temperature']?.toDouble() ?? 0.0,
      soilPh: json['soil_ph']?.toDouble() ?? 0.0,
    );
  }
}
