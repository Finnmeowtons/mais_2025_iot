import 'package:flutter/material.dart';
import 'package:mais_2025_iot/screens/camera_view.dart';
import 'package:mais_2025_iot/screens/raw_data_table.dart';
import 'package:mais_2025_iot/services/api_service.dart';

class DeviceData extends StatefulWidget {
  final int deviceId;
  final Map<String, dynamic> data;
  const DeviceData({super.key, required this.deviceId, required this.data});

  @override
  State<DeviceData> createState() => _DeviceDataState();
}

class _DeviceDataState extends State<DeviceData> {
  final apiService = ApiService();
  // Function to format the titles
  String formatTitle(String key) {
    Map<String, String> titleMapping = {
      "temperature": "Temperature",
      "humidity": "Humidity",
      "soilMoisturePercentage": "Soil Moisture Percentage",
      "soilTemperature": "Soil Temperature",
      "soilPh": "Soil pH",
    };

    return titleMapping[key] ?? key; // Default to the key if no mapping found
  }

  // Function to format the values
  String formatValue(String key, dynamic value) {
    if (value is num) {
      switch (key) {
        case "temperature":
        case "soilTemperature":
          return "${value.toStringAsFixed(2)}°C"; // 2 decimal places + °C
        case "soilMoisturePercentage":
          return "${value.toStringAsFixed(2)}%"; // 2 decimal places + %
        default:
          return value.toString(); // Default format
      }
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Device ${widget.deviceId} Data"), actions: [IconButton(onPressed: (){
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RawDataTable(deviceId: widget.deviceId,)),
        );
      }, icon: Icon(Icons.table_chart_rounded)), IconButton(onPressed: () async {
        print("device${widget.deviceId}");
        await apiService.getCameraIpAddress("device${widget.deviceId}").then((value) {
          final ipAddress = value['ip'];
          print(ipAddress);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CameraView(ipAddress: ipAddress,)),
          );
        });

      }, icon: Icon(Icons.camera_alt_rounded))],),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: widget.data.entries
              .where((entry) => entry.key != "soilMoistureRaw") // Exclude "soilMoistureRaw"
              .map((entry) {
            return Card(
              child: ListTile(
                title: Text(formatTitle(entry.key)),
                subtitle: Text(formatValue(entry.key, entry.value)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
