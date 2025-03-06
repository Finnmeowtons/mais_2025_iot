import 'package:flutter/material.dart';
import 'package:mais_2025_iot/screens/water_monitoring.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("MAIS"),),
    body: Center(
      child: FilledButton(onPressed: (){
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>  WaterMonitoring()));
      }, child: Text("Water Monitoring")),
    ),);
  }
}
