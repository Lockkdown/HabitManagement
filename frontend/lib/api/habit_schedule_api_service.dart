// lib/services/habit_schedule_api_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/habit_schedule_model.dart';
import '../models/habit_model.dart';
import '../services/storage_service.dart';

class HabitScheduleApiService {
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:5224';
  final StorageService _storageService = StorageService();

  ///  Lấy access token từ local storage
  Future<String?> _getAccessToken() async {
    return await _storageService.getAccessToken();
  }

  ///  Tạo headers có Authorization nếu có token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAccessToken();
    debugPrint("Token retrieved: ${token != null ? 'EXISTS (${token.length} chars)' : 'NULL'}");
    
    // Return empty headers if no token (adjust based on your API needs)
    if (token == null) {
       debugPrint("Warning: No access token found for API request.");
       return {
         'Content-Type': 'application/json; charset=UTF-8',
         'ngrok-skip-browser-warning': 'true',
       };
    }
    
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8', // Added charset=UTF-8
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
    };
    
    debugPrint("Headers created: $headers");
    return headers;
  }
  //  Lấy lịch của một habit
  Future<List<HabitSchedule>> getHabitSchedulesByHabitId(int habitId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/HabitSchedule/habit/$habitId'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => HabitSchedule.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải HabitSchedule: ${response.statusCode}');
    }
  }

  //  Kiểm tra xem habit có xuất hiện vào 1 ngày cụ thể không
  Future<bool> checkHabitForDate(int habitId, DateTime date) async {
    final formattedDate = date.toIso8601String();
    final response = await http.get(
      Uri.parse('$baseUrl/api/HabitSchedule/check/$habitId/$formattedDate'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as bool;
    } else {
      throw Exception('Lỗi kiểm tra HabitSchedule: ${response.statusCode}');
    }
  }

  //  Lấy danh sách habit phải làm vào ngày được chọn (dành cho user hiện tại - lấy từ JWT)
  Future<List<HabitModel>> getHabitsDueToday(String userId, {DateTime? selectedDate}) async {
    // Nếu không có ngày được chọn, sử dụng ngày hiện tại
    final date = selectedDate ?? DateTime.now();
    final formattedDate = date.toIso8601String().split('T')[0]; // Lấy phần ngày YYYY-MM-DD
    
    final url = '$baseUrl/api/HabitSchedule/due-today/$userId?date=$formattedDate';
    print('[API CALL] GET $url');

    try {
      final headers = await _getHeaders();
      print('Headers: $headers');

      final response = await http.get(Uri.parse(url), headers: headers);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        print('Parsed JSON data: $jsonData');
        return jsonData.map((e) => HabitModel.fromJson(e)).toList();
      } else if (response.statusCode == 401) {
        print(' Unauthorized - Token có thể hết hạn hoặc không hợp lệ');
        throw Exception('Không có quyền truy cập (401)');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print(' Error in getHabitsDueToday: $e');
      throw Exception('Không thể tải danh sách thói quen cho ngày đã chọn: $e');
    }
  }

  //  Test authentication endpoint
  Future<Map<String, dynamic>> testAuth() async {
    try {
      print('[API CALL] /api/HabitSchedule/test-auth');
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/HabitSchedule/test-auth'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print(' Error in testAuth: $e');
      throw Exception('Test auth failed: $e');
    }
  }
}
