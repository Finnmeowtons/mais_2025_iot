import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // final String baseUrl = 'http://localhost:3000/api'; // Replace with your actual API base URL
  final String baseUrl = 'http://10.0.2.2:3000/api';

  Future<List<Map<String, dynamic>>> getConnectedDevices() async {
    final response = await http.get(Uri.parse('$baseUrl/devices'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      print('Failed to fetch devices: ${response.statusCode}');
      throw Exception('Failed to fetch devices');
    }
  }

  Future<List<dynamic>> getRawData(int deviceId,
      {int page = 1, int limit = 50}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/raw-data?device=$deviceId&page=$page&limit=$limit'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Failed to fetch raw data: ${response.statusCode}');
      throw Exception('Failed to fetch raw data');
    }
  }

  Future<Map<String, dynamic>> getAnalyticsData(int deviceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics-data?device=$deviceId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Failed to fetch analytics data: ${response.statusCode}');
      throw Exception('Failed to fetch analytics data');
    }
  }

  Future<List<dynamic>> getGraphData(
      int deviceId, String start, String end) async {
    final response = await http.get(
      Uri.parse('$baseUrl/graph-data?device=$deviceId&start=$start&end=$end'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Failed to fetch graph data: ${response.statusCode}');
      throw Exception('Failed to fetch graph data');
    }
  }
}
