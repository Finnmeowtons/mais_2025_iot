import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mais_2025_iot/screens/camera_view.dart';
import 'package:mais_2025_iot/screens/device_data.dart';
import 'package:mais_2025_iot/screens/raw_data_table.dart';
import 'package:mais_2025_iot/screens/water_monitoring.dart';
import 'package:mais_2025_iot/services/api_service.dart';
import 'package:mais_2025_iot/services/mqtt_manager.dart';
import 'package:mqtt5_client/mqtt5_client.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MqttManager mqttManager = MqttManager();
  final ApiService apiService = ApiService();
  Map<int, Map<String, dynamic>> devices = {}; // Stores data per device

  bool faucetControl = false;
  int waterState = 0;

  String recommendedFertilizer = "";
  String irrigationTime = "";

  @override
  void initState() {
    _setupMqttSubscriptions();
    _irrigationForecast();
    _recommendFertilizer();
    super.initState();
  }

  void _recommendFertilizer() {
    apiService.recommendFertilizer().then((value) {
      final fertilizer = value['recommendation'];
      print(fertilizer);
      if (fertilizer != null && fertilizer.isNotEmpty) {

        setState(() {
          recommendedFertilizer = fertilizer;
        });
      }
    }).catchError((error) {
      print("Error fetching recommended fertilizer: $error");

    });
  }

  void _irrigationForecast() {
    apiService.irrigationForecast().then((value) {
      final rawTimestamp = value['irrigation_needed_at']; // e.g. "2025-04-12T18:15:01"

      if (rawTimestamp != null && rawTimestamp.isNotEmpty) {
        final dateTime = DateTime.parse(rawTimestamp);
        final formattedTime = DateFormat('hh:mm a').format(dateTime);

        setState(() {
          irrigationTime = formattedTime; // e.g. "06:15 PM"
        });
      }
    }).catchError((error) {
      print("Error fetching irrigation forecast: $error");
    });
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
      drawer: appDrawer(),
      body: CustomScrollView(
        slivers: [
          // Water Monitor Card at the Top
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _waterMonitor(), // Your water monitor widget
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  recommendFertilizer(),
                  SizedBox(width: 16,),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      margin: EdgeInsets.only(bottom: 16),
                      child: Container(
                        height: 120,
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Irrigation\nPrediction", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            irrigationTime.isEmpty ? SizedBox(width: 20, height: 20,child: CircularProgressIndicator(),) : Text(irrigationTime, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ), // Your water monitor widget
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
    );
  }

  Widget _waterMonitor() {
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

  Widget recommendFertilizer() {
    return Card(
      elevation: 4,
      clipBehavior: Clip.hardEdge,
      margin: EdgeInsets.only(bottom: 16),
      child: Container(
        height: 120,
        width: 170,
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Recommended\nFertilizer",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            if (recommendedFertilizer.isEmpty)
              SizedBox(height:20, width: 20, child: CircularProgressIndicator())
            else if (recommendedFertilizer.isEmpty)
              Text(
                "Tap to request fertilizer \n recommendation",
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              )
            else
              Center(
                child: Text(
                  recommendedFertilizer,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }


  Drawer appDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
            ),
            child: Center(child: Text("Optimizing Corn Yield Using Smart Agricultural Management", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),)),
          ),
          ListTile(
            leading: Icon(Icons.table_chart_rounded),
            title: Text('Raw Data Table'),
            onTap: () async {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RawDataTable()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt_rounded),
            title: Text('Camera Device 1'),
            onTap: () async {
              Navigator.pop(context);
              await apiService.getCameraIpAddress(context, "device1").then((value) {
                final ipAddress = value['ip'];
                print(ipAddress);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraView(ipAddress: ipAddress,)),
                );
              });
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt_rounded),
            title: Text('Camera Device 2'),
            onTap: () async {
              Navigator.pop(context);
              await apiService.getCameraIpAddress(context, "device2").then((value) {
                final ipAddress = value['ip'];
                print(ipAddress);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraView(ipAddress: ipAddress,)),
                );
              });
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt_rounded),
            title: Text('Camera Device 3'),
            onTap: () async {
              Navigator.pop(context);
              await apiService.getCameraIpAddress(context, "device3").then((value) {
                final ipAddress = value['ip'];
                print(ipAddress);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraView(ipAddress: ipAddress,)),
                );
              });
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt_rounded),
            title: Text('Camera Device 4'),
            onTap: () async {
              Navigator.pop(context);
              await apiService.getCameraIpAddress(context, "device4").then((value) {
                final ipAddress = value['ip'];
                print(ipAddress);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraView(ipAddress: ipAddress,)),
                );
              });
            },
          ),

        ],
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
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
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
                MaterialPageRoute(builder: (context) => DeviceData(deviceId: deviceId, data: data)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Device $deviceId", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
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
                if (data["nitrogen"].toString() != "0" || data["phosphorus"].toString() != "0" || data["potassium"].toString() != "0")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _DataPreview(
                        icon: Icons.gas_meter,
                        iconColor: Colors.green,
                        label: "Nitrogen",
                        value: data["nitrogen"].toString(),
                        textColor: Colors.black,
                      ),
                      _DataPreview(
                        icon: Icons.gas_meter,
                        iconColor: Colors.blueAccent,
                        label: "Phosphorus",
                        value: data["phosphorus"].toString(),
                        textColor: Colors.black,
                      ),
                      _DataPreview(
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
