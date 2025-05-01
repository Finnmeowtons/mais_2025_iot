import 'package:flutter/material.dart';
import 'package:mais_2025_iot/services/api_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MultipleCameraView extends StatefulWidget {
  const MultipleCameraView({super.key});

  @override
  State<MultipleCameraView> createState() => _MultipleCameraViewState();
}

class _MultipleCameraViewState extends State<MultipleCameraView> {
  ApiService apiService = ApiService();
  bool isDone = false;
  final List<String> cameraIPs = [];

  @override
  void initState() {
    getDevicesIpAddress();
    super.initState();
  }

  void getDevicesIpAddress() async {
    final deviceIds = ["device1", "device2", "device3", "device4"];

    for (final deviceId in deviceIds) {
      try {
        final value = await apiService.getCameraIpAddress(context, deviceId);
        final ipAddress = value['ip'];
        print(ipAddress);
        cameraIPs.add(ipAddress);
      } catch (e) {
        print("Skipping $deviceId due to error: $e");
      }
    }

    if (mounted) {
      setState(() {
        isDone = true;
      });
    }
  }


  WebViewWidget buildCameraWebView(String ip) {
    final controller = WebViewController()
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
      ..loadRequest(Uri.parse('http://$ip/stream'));

    return WebViewWidget(controller: controller);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Multi Camera View")),
      body: GridView.builder(
        itemCount: cameraIPs.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 cameras side by side
        ),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: isDone ? buildCameraWebView(cameraIPs[index]) : CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
