import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttManager {
  MqttServerClient? client;
  bool isConnected = false;

  Future<void> initialize() async {
    client = MqttServerClient('157.245.204.46', '1883');
    client!.logging(on: false); // Optional: Disable logging

    final connMess = MqttConnectMessage()
        // .withClientIdentifier('flutter_client') // Unique client ID
        .withWillTopic('will/topic') // Optional: Will topic
        .withWillMessage('My last will') // Optional: Will message
        .withWillQos(MqttQos.atLeastOnce); // Optional: Will QOS
    client!.connectionMessage = connMess;

    try {
      await client!.connect();
      isConnected = true;
      print('MQTT Connected!');
      client!.subscribe("greeting", MqttQos.atMostOnce); // Subscribe here after connection
    } catch (e) {
      print('MQTT Connection failed: $e');
      isConnected = false;
    }
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
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    }
  }

  void subscribe(String topic) {

    print("subscribing to $topic");
    if (client != null && isConnected) {
      print("subscribed to $topic");
      client!.subscribe(topic, MqttQos.atMostOnce);
    } else {

      print("SOmething went wrong");
    }
  }
}