import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../mqtt_manager.dart';

class HomePage extends StatefulWidget {
  final MqttManager mqttManager;
  const HomePage({super.key, required this.mqttManager});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String float = '';
  String pumpControl = '';
  String autoPump = '';
  String faucetControl = '';
  String autoWater = '';
  String mode = '';

  @override
  void initState() {
    super.initState();
    print("initialize");
    widget.mqttManager.subscribe("water-level/float");
    widget.mqttManager.subscribe("water-level/pump-control");
    widget.mqttManager.subscribe("water-level/auto-pump");
    widget.mqttManager.subscribe("water/faucet-control");
    widget.mqttManager.subscribe("water/auto-water");
    widget.mqttManager.subscribe("water/mode");
    widget.mqttManager.client?.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      String newMessage = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      if (c[0].topic == "water-level/float" && newMessage != float) {
        setState(() {
          float = newMessage;
        });
        print("float: $float");
      } else if (c[0].topic == "water-level/pump-control" && newMessage != pumpControl) {
        setState(() {
          pumpControl = newMessage;
        });
        print("pumpControl: $pumpControl");
      } else if (c[0].topic == "water-level/auto-pump" && newMessage != autoPump) {
        setState(() {
          autoPump = newMessage;
        });
        print("autoPump: $autoPump");
      } else if (c[0].topic == "water/auto-water" && newMessage != autoWater) {
        setState(() {
          autoWater = newMessage;
        });
        print("autoWater: $autoWater");
      } else if (c[0].topic == "water/faucet-control" && newMessage != faucetControl) {
        setState(() {
          faucetControl = newMessage;
        });
        print("faucetControl: $faucetControl");
      } else if (c[0].topic == "water/mode" && newMessage != mode) {
        setState(() {
          mode = newMessage;
        });
        print("mode: $mode");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
          child: Column(
        children: [
          _ModeSelectionSegmentedButton(mqttManager: widget.mqttManager,),

          _WaterLevelAlert(
            float: float,
          ),
          _FaucetAlert(
            float: float,
          ),
          _PumpSwitches(mqttManager: widget.mqttManager)
        ],
      )),
    );
  }
}

class _WaterLevelAlert extends StatelessWidget {
  final String float;
  const _WaterLevelAlert({super.key, required this.float});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 100,
      width: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                float,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(
                width: 16,
              ),
              float == "OK"
                  ? Image.asset(
                      "assets/water_tank_ok.png",
                      height: 100,
                    )
                  : Image.asset(
                      "assets/water_tank_warning.png",
                      height: 100,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaucetAlert extends StatelessWidget {
  final String float;
  const _FaucetAlert({super.key, required this.float});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 100,
      width: 250,
      child: Card(

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                float,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(
                width: 16,
              ),
              float == "OK"
                  ? Image.asset(
                "assets/water.png",
                height: 100,
              )
                  : Image.asset(
                "assets/no_water.png",
                height: 100,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PumpSwitches extends StatefulWidget {
  final MqttManager mqttManager;
  const _PumpSwitches({super.key, required this.mqttManager});

  @override
  State<_PumpSwitches> createState() => _PumpSwitchesState();
}

class _PumpSwitchesState extends State<_PumpSwitches> {
  bool autoPumpEnabled = true;
  bool pumpEnabled = false;
  bool autoWaterEnabled = true;
  bool faucetEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,

            children: [
              Column(
                children: [
                  Text("Auto Pump:"),
                  Switch(
                    value: autoPumpEnabled,
                    onChanged: (value) {
                      setState(() {
                        autoPumpEnabled = value;
                        if (autoPumpEnabled) {
                          pumpEnabled = false; // Turn off pump when auto mode is enabled

                        }
                      });
                        widget.mqttManager.publish("water-level/auto-pump", value.toString());
                    },
                  ),
                ],
              ),
              Column(
                children: [
                  Text("Pump:"),
                  Switch(
                    value: pumpEnabled,
                    onChanged: autoPumpEnabled
                        ? null // Disable switch if autoPump is on
                        : (value) {
                            setState(() {
                              pumpEnabled = value;
                            });
                            widget.mqttManager.publish("water-level/pump-control", value.toString());
                          },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 32,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text("Auto Water:"),
                  Switch(
                    value: autoWaterEnabled,
                    onChanged: (value) {
                      setState(() {
                        autoWaterEnabled = value;
                        if (autoWaterEnabled) {
                          faucetEnabled = false; // Turn off pump when auto mode is enabled

                        }
                      });
                      widget.mqttManager.publish("water/auto-water", value.toString());
                    },
                  ),
                ],
              ),
              Column(
                children: [
                  Text("Faucet:"),
                  Switch(
                    value: faucetEnabled,
                    onChanged: autoWaterEnabled
                        ? null
                        : (value) {
                      setState(() {
                        faucetEnabled = value;
                      });
                      widget.mqttManager.publish("water/faucet-control", value.toString());
                    },
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _ModeSelectionSegmentedButton extends StatefulWidget {
  final MqttManager mqttManager;
  const _ModeSelectionSegmentedButton({super.key, required this.mqttManager});

  @override
  State<_ModeSelectionSegmentedButton> createState() => _ModeSelectionSegmentedButtonState();
}

class _ModeSelectionSegmentedButtonState extends State<_ModeSelectionSegmentedButton> {
  var mode = "mais";

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsetsDirectional.symmetric(horizontal: 48.0, vertical: 8.0),
      child: SegmentedButton(segments: [
        ButtonSegment(value: "mais",
            label: Text("MAIS"),
          icon: SvgPicture.asset(
            mode == "mais" ? "assets/mais_fill.svg" : "assets/mais.svg", width: 24, height: 24,)
        ),
        ButtonSegment(value: "tank",
          label: Text("Tank"),
            icon: SvgPicture.asset(
              mode == "tank" ? "assets/water_full_fill.svg" : "assets/water_full.svg", width: 24, height: 24,)
        ),

      ], selected: {mode},
        showSelectedIcon: false,
      onSelectionChanged: (newMode){
        _confirmModeChange(newMode.join());
      },),
    );
  }

  void _confirmModeChange(String newMode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Mode Change"),
          content: Text(
              "Switching to '${newMode.toUpperCase()}' will activate automatic water control. "
                  "Are you sure you want to proceed?"
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  mode = newMode;
                });
                widget.mqttManager.publish("water/mode", newMode);
              },
              child: Text("Confirm", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

