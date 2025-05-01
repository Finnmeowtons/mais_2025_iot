import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mais_2025_iot/screens/device_data.dart';
import 'package:mais_2025_iot/screens/home_page.dart';
import 'package:mais_2025_iot/services/mqtt_manager.dart';
import 'package:mqtt5_client/mqtt5_client.dart';

class AllDevicesList extends StatefulWidget {
  final Map<int, Map<String, dynamic>> devices;
  const AllDevicesList({super.key, required this.devices});

  @override
  State<AllDevicesList> createState() => _AllDevicesListState();
}

class _AllDevicesListState extends State<AllDevicesList> {
  late Map<int, Map<String, dynamic>> devices;

  final MqttManager mqttManager = MqttManager();

  @override
  void initState() {
    devices = widget.devices;
    _setupMqttSubscriptions();
    super.initState();
  }

  void _setupMqttSubscriptions() {
    mqttManager.client?.updates.listen((dynamic c) {
      if (c == null || c.isEmpty) return;

      final MqttPublishMessage recMess = c![0].payload;
      String newMessage = MqttUtilities.bytesToStringAsString(recMess.payload.message!);
      if (newMessage.isNotEmpty && newMessage.trim().startsWith("{")) {
        try {
          Map<String, dynamic> fullState = json.decode(newMessage);

          if (fullState.containsKey("device_id")) {
            // Sensor Data
            int deviceId = fullState["device_id"];

            if (mounted) {
              setState(() {
                devices[deviceId] = {
                  "temperature": fullState["temperature"] ?? 0,
                  "humidity": fullState["humidity"] ?? 0,
                  "soilMoistureRaw": fullState["soil_moisture_raw"] ?? 0,
                  "soilMoisturePercentage": fullState["soil_moisture_percentage"] ?? 0,
                  "soilTemperature": fullState["soil_temperature"] ?? 0,
                  "soilPh": fullState["soil_ph"] ?? 0,
                  "nitrogen": fullState["nitrogen"] ?? 0,
                  "phosphorus": fullState["phosphorus"] ?? 0,
                  "potassium": fullState["potassium"] ?? 0
                };
              });
            }
          }
        } catch (e) {
          print("JSON Parsing Error: $e\nReceived message: $newMessage");
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Devices")),
      body: ListView.builder(
        itemCount: widget.devices.length,
        itemBuilder: (context, index) {
          int deviceId = widget.devices.keys.elementAt(index);
          Map<String, dynamic> data = widget.devices[deviceId]!;
          return _DevicesPreviewSensorDataCard(deviceId: deviceId, data: data);
        },
      ),
    );
  }
}

class _DevicesPreviewSensorDataCard extends StatelessWidget {
  final int deviceId;
  final Map<String, dynamic> data;
  const _DevicesPreviewSensorDataCard({super.key, required this.deviceId, required this.data});

  // Define danger thresholds
  final double temperatureThreshold = 40.0;
  final double humidityThreshold = 80.0;
  final double soilMoistureThreshold = 70.0;
  final double soilTemperatureThreshold = 35.0;
  final double soilPhLowThreshold = 5.5;
  final double soilPhHighThreshold = 7.5;

  Color getTextColor(String label, dynamic value) {
    if (value is num) {
      switch (label) {
        case "Temperature":
          return value > temperatureThreshold ? Colors.red : Colors.black;
        case "Humidity":
          return value > humidityThreshold ? Colors.red : Colors.black;
        case "Soil Moisture":
          return value > soilMoistureThreshold ? Colors.red : Colors.black;
        case "Soil Temperature":
          return value > soilTemperatureThreshold ? Colors.red : Colors.black;
        case "Soil pH":
          return (value < soilPhLowThreshold || value > soilPhHighThreshold) ? Colors.red : Colors.black;
      }
    }
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          InkWell(
            splashColor: Colors.blue.withAlpha(30),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeviceData(deviceId: deviceId)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Device $deviceId", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Icon(Icons.arrow_forward, size: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DataPreview(
                      icon: Icons.thermostat,
                      iconColor: Colors.redAccent,
                      label: "Temperature",
                      value: "${data["temperature"].toString()}°C",
                      textColor: getTextColor("Temperature", data["temperature"]),
                    ),
                    DataPreview(
                      icon: Icons.water_drop,
                      iconColor: Colors.blueAccent,
                      label: "Humidity",
                      value: data["humidity"].toString(),
                      textColor: getTextColor("Humidity", data["humidity"]),
                    ),
                    DataPreview(
                      icon: Icons.eco,
                      iconColor: Colors.green,
                      label: "Soil Moisture",
                      value: "${data["soilMoisturePercentage"].toStringAsFixed(2)}%",
                      textColor: getTextColor("Soil Moisture", data["soilMoisturePercentage"]),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DataPreview(
                      icon: Icons.thermostat,
                      iconColor: Colors.brown,
                      label: "Soil Temperature",
                      value: "${data["soilTemperature"].toStringAsFixed(2)}°C",
                      textColor: getTextColor("Soil Temperature", data["soilTemperature"]),
                    ),
                    DataPreview(
                      icon: Icons.science,
                      iconColor: Colors.grey,
                      label: "Soil pH",
                      value: data["soilPh"].toString(),
                      textColor: getTextColor("Soil pH", data["soilPh"]),
                    ),
                  ],
                ),
                if (data["nitrogen"].toString() != "0" || data["phosphorus"].toString() != "0" || data["potassium"].toString() != "0")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      DataPreview(
                        icon: Icons.gas_meter,
                        iconColor: Colors.green,
                        label: "Nitrogen",
                        value: data["nitrogen"].toString(),
                        textColor: Colors.black,
                      ),
                      DataPreview(
                        icon: Icons.gas_meter,
                        iconColor: Colors.blueAccent,
                        label: "Phosphorus",
                        value: data["phosphorus"].toString(),
                        textColor: Colors.black,
                      ),
                      DataPreview(
                        icon: Icons.gas_meter,
                        iconColor: Colors.purple,
                        label: "Potassium",
                        value: data["potassium"].toString(),
                        textColor: Colors.black,
                      ),
                    ],
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
