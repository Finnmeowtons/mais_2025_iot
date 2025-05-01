import 'dart:async';
import 'package:flutter/material.dart';

class MultipleCameraImageView extends StatefulWidget {
  const MultipleCameraImageView({super.key});

  @override
  State<MultipleCameraImageView> createState() => _MultipleCameraImageViewState();
}

class _MultipleCameraImageViewState extends State<MultipleCameraImageView> {
  final int cameraCount = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Camera Feeds")),
      body: GridView.builder(
        itemCount: cameraCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2x2 grid
        ),
        itemBuilder: (context, index) {
          return _SmoothCameraTile(deviceNumber: index + 1);
        },
      ),
    );
  }
}

class _SmoothCameraTile extends StatefulWidget {
  final int deviceNumber;
  const _SmoothCameraTile({super.key, required this.deviceNumber});

  @override
  State<_SmoothCameraTile> createState() => _SmoothCameraTileState();
}

class _SmoothCameraTileState extends State<_SmoothCameraTile> {
  late Timer _timer;
  late String _currentImageUrl;
  late String _nextImageUrl;
  bool _showFirst = true;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = _generateUrl();
    _nextImageUrl = _generateUrl();

    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refreshImage());
  }

  String _generateUrl() {
    return "http://157.245.204.46:3000/image/device${widget.deviceNumber}?t=${DateTime.now().millisecondsSinceEpoch}";
  }

  Future<void> _refreshImage() async {
    final newUrl = _generateUrl();

    final Image newImage = Image.network(newUrl);
    final completer = Completer<void>();

    final ImageStream stream = newImage.image.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((ImageInfo _, bool __) {
      completer.complete();
    }, onError: (dynamic _, __) {
      completer.complete(); // fallback even if it fails
    });

    stream.addListener(listener);
    await completer.future;
    stream.removeListener(listener);

    if (!mounted) return;

    setState(() {
      _showFirst = !_showFirst;
      if (_showFirst) {
        _currentImageUrl = newUrl;
      } else {
        _nextImageUrl = newUrl;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: _showFirst ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Image.network(
              _currentImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Center(child: Text("Failed to load")),
            ),
          ),
          AnimatedOpacity(
            opacity: _showFirst ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Image.network(
              _nextImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Center(child: Text("Failed to load")),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black54,
              child: Text(
                "Device ${widget.deviceNumber}",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
