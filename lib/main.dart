import 'package:flutter/material.dart';
import 'package:mais_2025_iot/mqtt_manager.dart';
import 'package:mais_2025_iot/screens/home_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final mqttManager = MqttManager();
  await mqttManager.initialize(); // Initialize connection
  mqttManager.subscribe("sensor/+/data");
  mqttManager.subscribe("water-level/full-state");
  runApp(MyApp(mqttManager: mqttManager));
}

class MyApp extends StatefulWidget {
  final MqttManager mqttManager;
  const MyApp({super.key, required this.mqttManager});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    widget.mqttManager.disconnect(); // Disconnect when app closes
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: HomePage());
  }
}
