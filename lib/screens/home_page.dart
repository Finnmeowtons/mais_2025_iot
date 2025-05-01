import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:mais_2025_iot/main.dart';
import 'package:mais_2025_iot/screens/all_devices_list.dart';
import 'package:mais_2025_iot/screens/camera_image_view.dart';
import 'package:mais_2025_iot/screens/camera_view.dart';
import 'package:mais_2025_iot/screens/device_data.dart';
import 'package:mais_2025_iot/screens/multiple_camera_image_view.dart';
import 'package:mais_2025_iot/screens/multiple_camera_view.dart';
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
  bool hasAnimal = false;

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

  Future<void> showNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id',
      'Channel Name',
      channelDescription: 'Description',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Animal Detected',
      'An animal has been detected near the crops. Check the camera view for more details.',
      platformDetails,
    );
  }

  void _setupMqttSubscriptions() {

    mqttManager.client?.updates.listen((dynamic c) {
        if (c == null || c.isEmpty) return;

        final MqttPublishMessage recMess = c![0].payload;
        String newMessage = MqttUtilities.bytesToStringAsString(recMess.payload.message!);
        print(newMessage);
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
            } else if (fullState.containsKey("has_animal")) {
              print(fullState["has_animal"]);
              setState(() {
                hasAnimal = fullState["has_animal"] ?? false;
                if (hasAnimal) {
                  showNotification();
                }
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
                    child: InkWell(
                      onTap: (){
                        _irrigationForecast();
                      },
                      child: Card(
                        elevation: 4,
                        margin: EdgeInsets.only(bottom: 16),
                        child: Container(
                          height: 120,
                          padding: EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Irrigation\nPrediction", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              irrigationTime.isEmpty ? SizedBox(width: 12, height: 12,child: CircularProgressIndicator(),) : Text(irrigationTime, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [Text("Animal Detected:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10),), Text(hasAnimal ? "Animal Farm Detected" : "No Animal Farm Detected", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10  ))],),
          )),
          SliverToBoxAdapter(
            child: _DeviceSummaryCard(devices: devices,),
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
                  Text("Water Control", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    return InkWell(
      onTap: (){
        _recommendFertilizer();
      },
      child: Card(
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              if (recommendedFertilizer.isEmpty)
                SizedBox(height:12, width: 12, child: CircularProgressIndicator())
              else if (recommendedFertilizer.isEmpty)
                Text(
                  "Tap to request fertilizer \n recommendation",
                  style: TextStyle(fontSize: 12),
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
            leading: Icon(Icons.image_rounded),
            title: Text('Pictures'),
            onTap: () async {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MultipleCameraImageView(),),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.analytics_rounded),
            title: Text('Analytics'),
            onTap: () async {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeviceData(deviceId: 0),),
              );
            },
          ),
          ExpansionTile(
            leading: Icon(Icons.camera_rounded),

            title: Text('Camera Devices'),
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Device 1'),
                onTap: () async {
                  final ipAddress = await apiService.getCameraIpAddress(context, "device1");
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraView(ipAddress: ipAddress["ip"], deviceNumber: "device1"),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Device 2'),
                onTap: () async {
                  final ipAddress = await apiService.getCameraIpAddress(context, "device2");
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraView(ipAddress: ipAddress["ip"], deviceNumber: "device2"),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Device 3'),
                onTap: () async {
                  final ipAddress = await apiService.getCameraIpAddress(context, "device3");
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraView(ipAddress: ipAddress["ip"], deviceNumber: "device3"),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Device 4'),
                onTap: () async {
                  final ipAddress = await apiService.getCameraIpAddress(context, "device4");
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraView(ipAddress: ipAddress["ip"], deviceNumber: "device4"),
                    ),
                  );
                },
              ),
            ],
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


class DataPreview extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color textColor;

  const DataPreview({
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
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14 , color: textColor, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _DeviceSummaryCard extends StatelessWidget {
  final Map<int, Map<String, dynamic>> devices;
  const _DeviceSummaryCard({super.key, required this.devices});

  Map<String, double> _calculateAverageValues() {
    final totals = <String, double>{};
    final count = devices.length.toDouble();

    for (var data in devices.values) {
      for (var key in data.keys) {
        if (data[key] is num) {
          totals[key] = (totals[key] ?? 0) + (data[key] as num).toDouble();
        }
      }
    }

    // Compute averages
    return totals.map((k, v) => MapEntry(k, v / count));
  }

  @override
  Widget build(BuildContext context) {
    final avgData = _calculateAverageValues();

    Color getTextColor(String label, double? value) {
      if (value == null) return Colors.black;
      switch (label) {
        case "Temperature":
          return value > 40.0 ? Colors.red : Colors.black;
        case "Humidity":
          return value > 80.0 ? Colors.red : Colors.black;
        case "Soil Moisture":
          return value > 70.0 ? Colors.red : Colors.black;
        case "Soil Temperature":
          return value > 35.0 ? Colors.red : Colors.black;
        case "Soil pH":
          return (value < 5.5 || value > 7.5) ? Colors.red : Colors.black;
        default:
          return Colors.black;
      }
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          InkWell(
            onTap: devices.isNotEmpty
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllDevicesList(devices: devices),
                ),
              );
            }
                : null, // disables the button if no devices,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("All Devices Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Top row: Temp, Humidity, Soil Moisture
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DataPreview(
                      icon: Icons.thermostat,
                      iconColor: Colors.redAccent,
                      label: "Temperature",
                      value: "${avgData["temperature"]?.toStringAsFixed(1) ?? "--"}°C",
                      textColor: getTextColor("Temperature", avgData["temperature"]),
                    ),
                    DataPreview(
                      icon: Icons.water_drop,
                      iconColor: Colors.blueAccent,
                      label: "Humidity",
                      value: "${avgData["humidity"]?.toStringAsFixed(1) ?? "--"}%",
                      textColor: getTextColor("Humidity", avgData["humidity"]),
                    ),
                    DataPreview(
                      icon: Icons.eco,
                      iconColor: Colors.green,
                      label: "Soil Moisture",
                      value: "${avgData["soilMoisturePercentage"]?.toStringAsFixed(1) ?? "--"}%",
                      textColor: getTextColor("Soil Moisture", avgData["soilMoisturePercentage"]),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Second row: Soil Temp, Soil pH
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DataPreview(
                      icon: Icons.thermostat,
                      iconColor: Colors.brown,
                      label: "Soil Temperature",
                      value: "${avgData["soilTemperature"]?.toStringAsFixed(1) ?? "--"}°C",
                      textColor: getTextColor("Soil Temperature", avgData["soilTemperature"]),
                    ),
                    DataPreview(
                      icon: Icons.science,
                      iconColor: Colors.grey,
                      label: "Soil pH",
                      value: avgData["soilPh"]?.toStringAsFixed(1) ?? "--",
                      textColor: getTextColor("Soil pH", avgData["soilPh"]),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // NPK Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DataPreview(
                      icon: Icons.gas_meter,
                      iconColor: Colors.green,
                      label: "Nitrogen",
                      value: avgData["nitrogen"]?.toStringAsFixed(1) ?? "--",
                      textColor: Colors.black,
                    ),
                    DataPreview(
                      icon: Icons.gas_meter,
                      iconColor: Colors.blueAccent,
                      label: "Phosphorus",
                      value: avgData["phosphorus"]?.toStringAsFixed(1) ?? "--",
                      textColor: Colors.black,
                    ),
                    DataPreview(
                      icon: Icons.gas_meter,
                      iconColor: Colors.purple,
                      label: "Potassium",
                      value: avgData["potassium"]?.toStringAsFixed(1) ?? "--",
                      textColor: Colors.black,
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


