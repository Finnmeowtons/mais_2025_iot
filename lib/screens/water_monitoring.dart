import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../mqtt_manager.dart';

class WaterMonitoring extends StatefulWidget {
  const WaterMonitoring({super.key});

  @override
  State<WaterMonitoring> createState() => _WaterMonitoringState();
}

class _WaterMonitoringState extends State<WaterMonitoring> {
  final MqttManager mqttManager = MqttManager();

  bool _isLoading = false; // Track loading state
  String pumpControl = '';
  String autoPump = '';
  String faucetControl = '';
  String autoWater = '';
  String mode = 'mais';
  int waterState = 0;

  String? lastPumpControl;
  String? lastAutoPump;
  String? lastFaucetControl;
  String? lastAutoWater;
  String? lastMode;
  int? lastWaterState;

  void firstLoad() {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });

      Future.delayed(Duration(seconds: 3), () {
        if (mounted) { // Check again before calling setState
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();

    mqttManager.onDisconnectedCallback = () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disconnected from MQTT! Reconnecting...'),
          duration: Duration(seconds: 3),
        ),
      );
    };


    _setupMqttSubscriptions();
    firstLoad();
  }



  void _setupMqttSubscriptions() {

    mqttManager.client?.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      if (c == null || c.isEmpty) return;

      final recMess = c[0].payload as MqttPublishMessage;
      String newMessage = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      if (newMessage.isNotEmpty) {
        // ✅ Check if the message is valid JSON
        if (!newMessage.trim().startsWith("{")) {
          print("Received non-JSON message: $newMessage");
          return; // Ignore invalid messages
        }

        try {
          Map<String, dynamic> fullState = json.decode(newMessage);

          // ✅ Ensure all values exist and convert types safely
          String newPumpControl = fullState["pump_state"]?.toString() ?? "false";
          String newAutoPump = fullState["auto_pump"]?.toString() ?? "false";
          String newFaucetControl = fullState["faucet_state"]?.toString() ?? "false";
          String newAutoWater = fullState["auto_faucet"]?.toString() ?? "false";
          String newMode = fullState["mode"]?.toString() ?? "tank";
          int newWaterState = int.tryParse(fullState["water_level"]?.toString() ?? "0") ?? 0;

          // ✅ Check if values changed before updating the state
          if (newPumpControl != pumpControl || newAutoPump != autoPump || newFaucetControl != faucetControl || newAutoWater != autoWater || newMode != mode || newWaterState != waterState) {
            if (mounted) {
              setState(() {
                pumpControl = newPumpControl;
                autoPump = newAutoPump;
                faucetControl = newFaucetControl;
                autoWater = newAutoWater;
                mode = newMode;
                waterState = newWaterState;
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
  void dispose() {
    mqttManager.client?.updates?.listen((event) {}).cancel(); // Cancel subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
          child: Stack(
        children: [
          Column(
            children: [
              _modeSelectionSegmentedButton(),
              _WaterLevelAlert(
                waterState: waterState ?? 0,
              ),
              _FaucetAlert(
                watering: faucetControl ?? "false",
              ),
              _pumpSwitches(),
            ],
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: .8), // Semi-transparent overlay
                child: Center(
                  child: CircularProgressIndicator(), // Loading indicator
                ),
              ),
            ),
        ],
      )),
    );
  }

  Widget _pumpSwitches() {
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
                    value: autoPump == "true",
                    onChanged: (value) {
                      setState(() {
                        value ? autoPump = "true" : autoPump = "false";
                        pumpControl = "false"; // Turn off pump when auto mode is enabled
                      });
                      mqttManager.publish("water-level/auto-pump", value.toString());
                      // mqttManager.publish("water-level/pump-control", pumpControl);
                    },
                  ),
                ],
              ),
              Column(
                children: [
                  Text("Pump:"),
                  Switch(
                    value: pumpControl == "true",
                    onChanged: autoPump == "true"
                        ? null // Disable switch if autoPump is on
                        : (value) {
                            setState(() {
                              value ? pumpControl = "true" : pumpControl = "false";
                            });
                            mqttManager.publish("water-level/pump-control", value.toString());
                          },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 32,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text("Auto Water:"),
                  Switch(
                    value: autoWater == "true",
                    onChanged: (value) {
                      setState(() {
                        value ? autoWater = "true" : autoWater = "false";
                        faucetControl = "false"; // Turn off faucet when auto mode is disabled
                      });
                      mqttManager.publish("water-level/auto-faucet", value.toString());
                      // mqttManager.publish("water-level/faucet-control", faucetControl);
                    },
                  ),
                ],
              ),
              Column(
                children: [
                  Text("Faucet:"),
                  Switch(
                    value: faucetControl == "true",
                    onChanged: autoWater == "true"
                        ? null
                        : (value) {
                            setState(() {
                              value ? faucetControl = "true" : faucetControl = "false";
                            });
                            mqttManager.publish("water-level/faucet-control", value.toString());
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

  Widget _modeSelectionSegmentedButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsetsDirectional.symmetric(horizontal: 48.0, vertical: 8.0),
      child: SegmentedButton(
        segments: [
          ButtonSegment(
              value: "mais",
              label: Text("MAIS"),
              icon: SvgPicture.asset(
                mode == "mais" ? "assets/mais_fill.svg" : "assets/mais.svg",
                width: 24,
                height: 24,
              )),
          ButtonSegment(
              value: "tank",
              label: Text("Tank"),
              icon: SvgPicture.asset(
                mode == "tank" ? "assets/water_full_fill.svg" : "assets/water_full.svg",
                width: 24,
                height: 24,
              )),
        ],
        selected: {mode},
        showSelectedIcon: false,
        onSelectionChanged: _isLoading
            ? null // Disable button when loading
            : (newMode) {
                _confirmModeChange(newMode.join());
              },
      ),
    );
  }

  void _confirmModeChange(String newMode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Mode Change"),
          content: Text("Switching to '${newMode.toUpperCase()}' will activate automatic water control. "
              "Are you sure you want to proceed?"),
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
                  autoWater = "false";
                  autoPump = "false";
                  _isLoading = true;
                });

                Future.delayed(Duration(seconds: 3), () {
                  setState(() {
                    _isLoading = false;
                  });
                });

                mqttManager.publish("water-level/mode", newMode);
              },
              child: Text("Confirm", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

class _WaterLevelAlert extends StatelessWidget {
  final int waterState;
  const _WaterLevelAlert({super.key, required this.waterState});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 100,
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$waterState%",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(
                width: 16,
              ),
              waterState > 20
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
  final String watering;
  const _FaucetAlert({super.key, required this.watering});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 100,
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                watering == "true" ? "Faucet: Open" : "Faucet: Close",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(
                width: 16,
              ),
              watering == "true"
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
      child: SegmentedButton(
        segments: [
          ButtonSegment(
              value: "mais",
              label: Text("MAIS"),
              icon: SvgPicture.asset(
                mode == "mais" ? "assets/mais_fill.svg" : "assets/mais.svg",
                width: 24,
                height: 24,
              )),
          ButtonSegment(
              value: "tank",
              label: Text("Tank"),
              icon: SvgPicture.asset(
                mode == "tank" ? "assets/water_full_fill.svg" : "assets/water_full.svg",
                width: 24,
                height: 24,
              )),
        ],
        selected: {mode},
        showSelectedIcon: false,
        onSelectionChanged: (newMode) {
          _confirmModeChange(newMode.join());
        },
      ),
    );
  }

  void _confirmModeChange(String newMode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Mode Change"),
          content: Text("Switching to '${newMode.toUpperCase()}' will activate automatic water control. "
              "Are you sure you want to proceed?"),
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
                  widget.mqttManager.publish("water-level/auto-pump", "true");
                  widget.mqttManager.publish("water-level/auto-faucet", "true");
                });
                widget.mqttManager.publish("water-level/mode", newMode);
              },
              child: Text("Confirm", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
