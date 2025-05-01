import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // final String baseUrl = 'http://localhost:3000/api';
  final String baseUrl = 'http://157.245.204.46:';
  final String port = '3001';
  final String port2 = '3003';

  Future<Map<String, dynamic>> getRawData(int page, int limit, int deviceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl$port/api/raw-data?&page=$page&limit=$limit&device=$deviceId')
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
      Uri.parse('$baseUrl$port/api/analytics-data?device=$deviceId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Failed to fetch analytics data: ${response.statusCode}');
      throw Exception('Failed to fetch analytics data');
    }
  }

  Future<List<dynamic>> getAggregatedData(bool isHour, int duration, int? deviceId) async {
    String url = isHour
        ? '$baseUrl$port/api/aggregated-data?hours=$duration'
        : '$baseUrl$port/api/aggregated-data?days=$duration';
    if (deviceId != null && deviceId != 0) {
      url += '&device=$deviceId';
    }
    print(url);

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Failed to fetch aggregated data: ${response.statusCode}');
      throw Exception('Failed to fetch aggregated data');
    }
  }


  Future<Map<String, dynamic>> irrigationForecast() async{
    final response = await http.get(
      Uri.parse('$baseUrl$port2/predict_irrigation_time'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Failed to fetch graph data: ${response.statusCode}');
      throw Exception('Failed to fetch irrigation time');
    }
  }

  Future<Map<String, dynamic>> recommendFertilizer() async{
    print("recommend fertilizer");
    final response = await http.get(
      Uri.parse('$baseUrl$port2/recommend-fertilizer'),
    );

    print("recommend fertilizer2");
    if (response.statusCode == 200) {
      print(response.statusCode);
      return jsonDecode(response.body);
    } else {
      print('Failed to fetch graph data: ${response.statusCode}');
      throw Exception('Failed to fetch irrigation time');
    }
  }

  Future<Map<String, dynamic>> getCameraIpAddress(BuildContext context, String deviceId) async{
    final response = await http.get(
      Uri.parse('$baseUrl$port/api/device-ip?device_id=$deviceId'),
    );
    if (response.statusCode == 200) {
      final successResponse = jsonDecode(response.body);
      return successResponse;
    } else {
      final errorResponse = jsonDecode(response.body);
      print('Failed to fetch devices ip: ${errorResponse['error']}');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Status ${response.statusCode}'),
          content: Text(errorResponse['error']),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      throw Exception('Failed to fetch devices ip');
    }
  }
}
