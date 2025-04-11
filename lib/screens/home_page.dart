import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mais_2025_iot/mqtt_manager.dart';
import 'package:mais_2025_iot/screens/device_data.dart';
import 'package:mais_2025_iot/screens/water_monitoring.dart';
import 'package:mais_2025_iot/service/api_service.dart';
import 'package:mqtt_client/mqtt_client.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MqttManager mqttManager = MqttManager();
  Map<int, Map<String, dynamic>> devices = {}; // Stores real-time sensor data
  final ApiService _apiService = ApiService();
  bool faucetControl = false;
  int waterState = 0;
  bool _loadingInitialData = true;
  String _initialDataError = '';
  final int targetDeviceId = 4; // The specific device ID you're interested in

  @override
  void initState() {
    _setupMqttSubscriptions();
    _fetchInitialDeviceData();
    super.initState();
  }

  Future<void> _fetchInitialDeviceData() async {
    try {
      // You might want to fetch raw data or analytics data initially
      final rawData = await _apiService.getRawData(targetDeviceId, limit: 1);
      if (rawData.isNotEmpty && rawData[0] is Map<String, dynamic>) {
        setState(() {
          devices[targetDeviceId] = {
            "temperature": rawData[0]["temperature"] ?? 0,
            "humidity": rawData[0]["humidity"] ?? 0,
            "soilMoistureRaw": rawData[0]["soil_moisture_raw"] ?? 0,
            "soilMoisturePercentage":
                rawData[0]["soil_moisture_percentage"] ?? 0,
            "soilTemperature": rawData[0]["soil_temperature"] ?? 0,
            "soilPh": rawData[0]["soil_ph"] ?? 0,
            "nitrogen": rawData[0]["nitrogen"] ?? 0,
            "phosphorus": rawData[0]["phosphorus"] ?? 0,
            "potassium": rawData[0]["potassium"] ?? 0,
          };
          _loadingInitialData = false;
          _initialDataError = '';
        });
      } else {
        setState(() {
          _loadingInitialData = false;
          _initialDataError =
              'No initial data found for device $targetDeviceId';
        });
      }
    } catch (e) {
      setState(() {
        _loadingInitialData = false;
        _initialDataError = 'Failed to load initial data: $e';
      });
      print(_initialDataError);
    }
  }

  void _setupMqttSubscriptions() {
    mqttManager.client?.updates
        ?.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      if (c == null || c.isEmpty) return;

      final recMess = c[0].payload as MqttPublishMessage;
      String newMessage =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      if (newMessage.isNotEmpty && newMessage.trim().startsWith("{")) {
        try {
          Map<String, dynamic> fullState = json.decode(newMessage);

          if (fullState.containsKey("device_id") &&
              fullState["device_id"] == targetDeviceId) {
            // Only process data for the specific device ID
            int deviceId = fullState["device_id"];
            setState(() {
              devices[deviceId] = {
                "temperature": fullState["temperature"] ?? 0,
                "humidity": fullState["humidity"] ?? 0,
                "soilMoistureRaw": fullState["soil_moisture_raw"] ?? 0,
                "soilMoisturePercentage":
                    fullState["soil_moisture_percentage"] ?? 0,
                "soilTemperature": fullState["soil_temperature"] ?? 0,
                "soilPh": fullState["soil_ph"] ?? 0,
                "nitrogen": fullState["nitrogen"] ?? 0,
                "phosphorus": fullState["phosphorus"] ?? 0,
                "potassium": fullState["potassium"] ?? 0,
              };
            });
          } else {
            // Water Control Data
            setState(() {
              faucetControl = fullState["faucet_state"]?.toString() == "true";
              waterState =
                  int.tryParse(fullState["water_level"]?.toString() ?? "0") ??
                      0;
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
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _waterMonitor(), // Restored _waterMonitor() here
            ),
          ),
          if (_loadingInitialData)
            SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_initialDataError.isNotEmpty)
            SliverToBoxAdapter(
              child: Center(
                  child: Text(_initialDataError,
                      style: TextStyle(color: Colors.red))),
            ),
          if (!_loadingInitialData &&
              _initialDataError.isEmpty &&
              !devices.containsKey(targetDeviceId)) // Corrected condition
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "No data received for device $targetDeviceId",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          if (devices.containsKey(targetDeviceId))
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final data = devices[targetDeviceId]!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _DevicesPreviewSensorDataCard(
                        deviceId: targetDeviceId, data: data),
                  );
                },
                childCount: 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _waterMonitor() {
    // Restored _waterMonitor() widget
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
                  Text("Water Control",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
  const _WaterMonitor(
      {super.key, required this.faucetControl, required this.waterState});

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
                  Text("Water Control",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
  const _DevicesPreviewSensorDataCard(
      {super.key, required this.deviceId, required this.data});

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
                    builder: (context) =>
                        DeviceData(deviceId: deviceId, data: data)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Device $deviceId",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600)),
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
                      value: data["temperature"] != null
                          ? "${double.parse(data["temperature"].toString())}°C"
                          : "N/A",
                      textColor:
                          getTextColor("Temperature", data["temperature"]),
                    ),
                    _DataPreview(
                      icon: Icons.water_drop,
                      iconColor: Colors.blueAccent,
                      label: "Humidity",
                      value: data["humidity"]?.toString() ??
                          "N/A", // No need for toStringAsFixed on humidity
                      textColor: getTextColor("Humidity", data["humidity"]),
                    ),
                    _DataPreview(
                      icon: Icons.science,
                      iconColor: Colors.grey,
                      label: "Soil pH",
                      value: data["soilPh"]?.toString() ??
                          "N/A", // No need for toStringAsFixed on pH (usually displayed as is)
                      textColor: getTextColor("Soil pH", data["soilPh"]),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _DataPreview(
                      icon: Icons.eco,
                      iconColor: Colors.green,
                      label: "Soil Moisture",
                      value: data["soilMoisturePercentage"] != null
                          ? "${double.parse(data["soilMoisturePercentage"].toString()).toStringAsFixed(2)}%"
                          : "N/A", // Or some other default value
                      textColor: getTextColor(
                          "Soil Moisture", data["soilMoisturePercentage"]),
                    ),
                    _DataPreview(
                      icon: Icons.thermostat,
                      iconColor: Colors.brown,
                      label: "Soil Temperature",
                      value: data["soilTemperature"] != null
                          ? "${double.parse(data["soilTemperature"].toString()).toStringAsFixed(2)}°C"
                          : "N/A",
                      textColor: getTextColor(
                          "Soil Temperature", data["soilTemperature"]),
                    ),
                  ],
                ),
                if (data["nitrogen"].toString() != "0")
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
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 16, color: textColor, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
