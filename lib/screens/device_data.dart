import 'package:flutter/material.dart';
import 'package:mais_2025_iot/screens/chartwidget/chart_legend.dart';
import 'package:mais_2025_iot/screens/chartwidget/raw_chart_screen.dart';
import 'package:mais_2025_iot/screens/graphchart/graph_chart_screen.dart';

class DeviceData extends StatefulWidget {
  final int deviceId;
  final Map<String, dynamic> data;
  const DeviceData({super.key, required this.deviceId, required this.data});

  @override
  State<DeviceData> createState() => _DeviceDataState();
}

class _DeviceDataState extends State<DeviceData> {
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
      appBar: AppBar(title: Text("Device ${widget.deviceId} Data")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Wrap the Column
          child: Column(
            children: [
              Container(
                height: 300, // Adjust to a more reasonable height
                // child: RawChartScreen(
                //   deviceId: widget.deviceId, // Use the correct deviceId
                // ),
                child: GraphChartScreen(
                  deviceId: widget.deviceId, // Use the correct deviceId
                ),
              ),
              const SizedBox(height: 16),
              // Add the ChartLegend here
              ChartLegend(
                items: [
                  LegendItemData(
                      icon: Icons.thermostat,
                      color: Colors.red,
                      label: "Temperature"),
                  LegendItemData(
                      icon: Icons.water_drop_rounded,
                      color: Colors.blue,
                      label: "Humidity"),
                  LegendItemData(
                      icon: Icons.opacity_rounded,
                      color: Colors.brown,
                      label: "Soil Moisture Raw"),
                  LegendItemData(
                      icon: Icons.eco,
                      color: Colors.green,
                      label: "Soil Moisture %"),
                  LegendItemData(
                      icon: Icons.thermostat_auto,
                      color: Colors.orange,
                      label: "Soil Temperature"),
                  LegendItemData(
                      icon: Icons.science,
                      color: Colors.purple,
                      label: "Soil pH"),
                ],
              ),
              const SizedBox(height: 16), // Add some spacing
              ListView(
                shrinkWrap: true, // Important for ListView inside a Column
                physics:
                    const NeverScrollableScrollPhysics(), // Disable ListView's scrolling
                children: widget.data.entries
                    .where((entry) => entry.key != "soilMoistureRaw")
                    .map((entry) {
                  return Card(
                    child: ListTile(
                      title: Text(formatTitle(entry.key)),
                      subtitle: Text(formatValue(entry.key, entry.value)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
