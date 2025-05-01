import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mais_2025_iot/services/mqtt_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CameraView extends StatefulWidget {
  final String ipAddress;
  final String deviceNumber;

  const CameraView({
    super.key,
    required this.ipAddress,
    required this.deviceNumber,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  final MqttManager mqttManager = MqttManager();
  late final WebViewController controller;
  bool streamOn = true;
  bool _isLoading = false; // NEW: loading state

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onHttpError: (HttpResponseError error) {
            debugPrint('HTTP error: ${error.response}');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('http://${widget.ipAddress}/stream'));
  }

  void toggleStream() async {
    setState(() {
      _isLoading = true;
    });

    final payload = {
      "is_streaming": !streamOn,
      "device_id": widget.ipAddress,
      "timestamp": DateTime.now().toIso8601String(),
    };

    mqttManager.publish(
      "camera/${widget.deviceNumber}/stream",
      jsonEncode(payload),
    );

    // Wait for ESP32-CAM to process

    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      streamOn = !streamOn;
      _isLoading = false; // hide loading
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Camera Device ${(widget.deviceNumber).substring(6)}"),
        actions: [
          IconButton(
            icon: Icon(streamOn ? Icons.visibility_off : Icons.visibility),
            tooltip: streamOn ? "Turn ON Stream" : "Turn OFF Stream",
            onPressed: _isLoading ? null : toggleStream,
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (!streamOn)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                child: Center(child: Text("Please turn on the stream.")),
              ),
            ),
          if (_isLoading)
            Positioned.fill(
                child: Container(
                  color: Colors.white,
                  child: const Center(child: CircularProgressIndicator()),)),
        ],
      ),
    );
  }
}
