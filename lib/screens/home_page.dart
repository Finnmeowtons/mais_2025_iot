import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mais_2025_iot/mqtt_manager.dart';
import 'package:mais_2025_iot/screens/device_data.dart';
import 'package:mais_2025_iot/screens/water_monitoring.dart';
import 'package:mqtt_client/mqtt_client.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MqttManager mqttManager = MqttManager();
  Map<int, Map<String, dynamic>> devices = {}; // Stores data per device

  bool faucetControl = false;
  int waterState = 0;

  @override
  void initState() {
    _setupMqttSubscriptions();
    super.initState();
  }

  void _setupMqttSubscriptions() {
    mqttManager.client?.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      if (c == null || c.isEmpty) return;

      final recMess = c[0].payload as MqttPublishMessage;
      String newMessage = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      if (newMessage.isNotEmpty && newMessage.trim().startsWith("{")) {
        try {
          Map<String, dynamic> fullState = json.decode(newMessage);

          if (fullState.containsKey("device_id")) {
            // Sensor Data
            int deviceId = fullState["device_id"];

            setState(() {
              devices[deviceId] = {
                "temperature": fullState["temperature"] ?? 0,
                "humidity": fullState["humidity"] ?? 0,
                "soilMoistureRaw": fullState["soil_moisture_raw"] ?? 0,
                "soilMoisturePercentage": fullState["soil_moisture_percentage"] ?? 0,
                "soilTemperature": fullState["soil_temperature"] ?? 0,
                "soilPh": fullState["soil_ph"] ?? 0,
              };
            });
          } else {
            // Water Control Data
            setState(() {
              faucetControl = fullState["faucet_state"]?.toString() == "true";
              waterState = int.tryParse(fullState["water_level"]?.toString() ?? "0") ?? 0;
            });
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
      appBar: _AppBar(),
      body: CustomScrollView(
        slivers: [
          // Water Monitor Card at the Top
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _waterMonitor(), // Your water monitor widget
            ),
          ),

          // List of Device Cards
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                int deviceId = devices.keys.elementAt(index);
                Map<String, dynamic> data = devices[deviceId]!;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _DevicesPreviewSensorDataCard(deviceId: deviceId, data: data),
                );
              },
              childCount: devices.length,
            ),
          ),
        ],
      ),

      // devices.isEmpty
      //     ? Center(child: Text("No devices connected"))
      //     : ListView.builder(
      //   itemCount: devices.length,
      //   itemBuilder: (context, index) {
      //     int deviceId = devices.keys.elementAt(index);
      //     Map<String, dynamic> data = devices[deviceId]!;
      //
      //     return _DevicesPreviewSensorDataCard(data: data, deviceId: deviceId,);
      //   },
      // ),
    );
  }

  Widget _waterMonitor(){
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WaterMonitoring()),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Water Control", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("Faucet: ${faucetControl ? "ON" : "OFF"}"),
                  Text("Water Level: $waterState%"),
                ],
              ),
              Icon(Icons.water, size: 36, color: Colors.blueAccent),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBar extends StatefulWidget implements PreferredSizeWidget {
  const _AppBar({super.key});

  @override
  State<_AppBar> createState() => _AppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 1.5);
}

class _AppBarState extends State<_AppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.menu),
        onPressed: () {},
      ),
      backgroundColor: Colors.blue,
      toolbarHeight: kToolbarHeight * 1.5,
      title: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text("Optimizing Corn Yield Using"),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text("Smart Agricultural Management"),
          ),
        ],
      ),
    );
  }
}

class _WaterMonitor extends StatelessWidget {
  final bool faucetControl;
  final int waterState;
  const _WaterMonitor({super.key, required this.faucetControl, required this.waterState});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WaterMonitoring()),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Water Control", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("Faucet: ${faucetControl ? "ON" : "OFF"}"),
                  Text("Water Level: $waterState%"),
                ],
              ),
              Icon(Icons.water, size: 36, color: Colors.blueAccent),
            ],
          ),
        ),
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
          return (value < soilPhLowThreshold || value > soilPhHighThreshold)
              ? Colors.red
              : Colors.black;
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
                MaterialPageRoute(
                    builder: (context) => DeviceData(deviceId: deviceId, data: data)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Device $deviceId",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
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
                    _DataPreview(
                      icon: Icons.thermostat,
                      iconColor: Colors.redAccent,
                      label: "Temperature",
                      value: "${data["temperature"].toString()}°C",
                      textColor: getTextColor("Temperature", data["temperature"]),
                    ),
                    _DataPreview(
                      icon: Icons.water_drop,
                      iconColor: Colors.blueAccent,
                      label: "Humidity",
                      value: data["humidity"].toString(),
                      textColor: getTextColor("Humidity", data["humidity"]),
                    ),
                    _DataPreview(
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
                    _DataPreview(
                      icon: Icons.thermostat,
                      iconColor: Colors.brown,
                      label: "Soil Temperature",
                      value: "${data["soilTemperature"].toStringAsFixed(2)}°C",
                      textColor: getTextColor("Soil Temperature", data["soilTemperature"]),
                    ),
                    _DataPreview(
                      icon: Icons.science,
                      iconColor: Colors.grey,
                      label: "Soil pH",
                      value: data["soilPh"].toString(),
                      textColor: getTextColor("Soil pH", data["soilPh"]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataPreview extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color textColor;

  const _DataPreview({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 30),
        // const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold)),
      ],
    );
  }
}