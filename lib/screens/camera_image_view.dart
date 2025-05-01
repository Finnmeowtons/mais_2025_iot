import 'dart:async';
import 'package:flutter/material.dart';

class CameraImageView extends StatefulWidget {
  final int deviceNumber;
  const CameraImageView({super.key, required this.deviceNumber});

  @override
  State<CameraImageView> createState() => _CameraImageViewState();
}

class _CameraImageViewState extends State<CameraImageView> {
  late Timer _timer;
  late String _currentImageUrl;
  late String _nextImageUrl;
  bool _showFirstImage = true;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = _generateImageUrl();
    _nextImageUrl = _generateImageUrl();

    _timer = Timer.periodic(Duration(seconds: 10), (_) => _refreshImage());
  }

  String _generateImageUrl() {
    return "http://157.245.204.46:3000/image/device${widget.deviceNumber}?t=${DateTime.now().millisecondsSinceEpoch}";
  }

  Future<void> _refreshImage() async {
    final newUrl = _generateImageUrl();

    // Preload image first
    final Image newImage = Image.network(newUrl);
    final completer = Completer<void>();

    final ImageStream stream = newImage.image.resolve(ImageConfiguration());
    final listener = ImageStreamListener((ImageInfo _, bool __) {
      completer.complete();
    }, onError: (dynamic _, __) {
      completer.complete(); // still complete to avoid stuck timer
    });

    stream.addListener(listener);
    await completer.future;
    stream.removeListener(listener);

    // Once preloaded, swap
    if (mounted) {
      setState(() {
        _showFirstImage = !_showFirstImage;
        if (_showFirstImage) {
          _currentImageUrl = newUrl;
        } else {
          _nextImageUrl = newUrl;
        }
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Device ${widget.deviceNumber}")),
      body: Center(
        child: Stack(
          children: [
            AnimatedOpacity(
              opacity: _showFirstImage ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Image.network(_currentImageUrl, fit: BoxFit.cover),
            ),
            AnimatedOpacity(
              opacity: _showFirstImage ? 0.0 : 1.0,
              duration: Duration(milliseconds: 300),
              child: Image.network(_nextImageUrl, fit: BoxFit.cover),
            ),
          ],
        ),
      ),
    );
  }
}
