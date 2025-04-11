import 'dart:async';
import 'dart:ui';

import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

class MqttManager {
  static final MqttManager _instance = MqttManager._internal();
  factory MqttManager() {
    return _instance;
  }


  MqttServerClient? client;
  bool isConnected = false;
  final String server = '157.245.204.46';
  final int port = 1883;
  final String clientId = 'flutter_client';
  final Set<String> _subscribedTopics = {}; // Store unique topics
  VoidCallback? onDisconnectedCallback;


  MqttManager._internal();

  Future<void> initialize() async {
    client = MqttServerClient.withPort(server, clientId, port);
    client!.logging(on: false);
    client!.keepAlivePeriod = 20;
    client!.autoReconnect = true;
    client!.resubscribeOnAutoReconnect = false;
    client!.onDisconnected = _onDisconnected;
    client!.onConnected = _onConnected;

    await _connect();
  }

  Future<void> _connect() async {
    try {
      print('Connecting to MQTT broker...');
      await client!.connect();
      isConnected = true;
      print('MQTT Connected!');

      _resubscribeTopics(); // Resubscribe to topics after reconnection
    } catch (e) {
      print('MQTT Connection failed: $e');
      isConnected = false;
    }
  }

  void _onDisconnected() {
    print('MQTT Disconnected! Attempting to reconnect...');
    isConnected = false;

    onDisconnectedCallback?.call();
  }

  void _onConnected() {
    print('MQTT Reconnected!');
    isConnected = true;
  }

  void disconnect() {
    if (client != null) {
      client!.disconnect();
      isConnected = false;
      print('MQTT Disconnected!');
    }
  }

  void publish(String topic, String message) {
    if (client != null && isConnected) {
      final builder = MqttPayloadBuilder();
      builder.addString(message);
      client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    }
  }

  void subscribe(String topic) {
    if (_subscribedTopics.contains(topic)) {
      print("Already subscribed to $topic, skipping.");
      return;
    }

    if (client != null && isConnected) {
      client!.subscribe(topic, MqttQos.atMostOnce);
      _subscribedTopics.add(topic); // Store topic to avoid duplicates
      print("Subscribed to $topic");
    } else {
      print("Subscription failed: Not connected");
    }
  }

  void _resubscribeTopics() {
    if (!isConnected || client == null) return;

    for (var topic in _subscribedTopics) {
      client!.subscribe(topic, MqttQos.atMostOnce);
      print("Re-subscribed to $topic");
    }
  }
}
