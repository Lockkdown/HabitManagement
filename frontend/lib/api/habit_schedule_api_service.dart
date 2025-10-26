// lib/api/habit_schedule_api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/habit_schedule_model.dart';
import '../models/habit_model.dart';
import '../services/storage_service.dart';

class HabitScheduleApiService {
  // Read Base URL from .env, fallback to localhost
  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:5224';

  final StorageService _storageService = StorageService();

  /// Get access token from storage
  Future<String?> _getAccessToken() async {
    return await _storageService.getAccessToken();
  }

  /// Create headers with authorization and ngrok skip
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
  // ========== HABIT SCHEDULE ENDPOINTS ==========

  /// Get list of schedules for a specific habit
  Future<List<HabitSchedule>> getHabitSchedulesByHabitId(int habitId) async {
    try {
      debugPrint("Getting habit schedules for habitId: $habitId from: $_baseUrl/api/HabitSchedule/habit/$habitId");
      final headers = await _getHeaders();
      debugPrint("Making request with headers: $headers");
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/HabitSchedule/habit/$habitId'),
        headers: headers,
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => HabitSchedule.fromJson(json)).toList();
      } else {
        debugPrint('Error getting habit schedules (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi lấy lịch trình thói quen: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection error getting habit schedules: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Check if habit should be performed on a specific date
  Future<bool> checkHabitForDate(int habitId, DateTime date) async {
    try {
      final formattedDate = date.toIso8601String();
      debugPrint("Checking habit for date: $formattedDate from: $_baseUrl/api/HabitSchedule/check/$habitId/$formattedDate");
      final headers = await _getHeaders();
      debugPrint("Making request with headers: $headers");
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/HabitSchedule/check/$habitId/$formattedDate'),
        headers: headers,
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as bool;
      } else {
        debugPrint('Error checking habit for date (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi kiểm tra thói quen: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection error checking habit for date: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Get list of habits due today for a specific user
  Future<List<HabitModel>> getHabitsDueToday(String userId) async {
    try {
      debugPrint("Getting habits due today for userId: $userId from: $_baseUrl/api/HabitSchedule/due-today/$userId");
      final headers = await _getHeaders();
      debugPrint("Making request with headers: $headers");
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/HabitSchedule/due-today/$userId'),
        headers: headers,
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        debugPrint('Parsed JSON data: $data');
        return data.map((json) => HabitModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        debugPrint('Unauthorized - Token may be expired or invalid');
        throw Exception('Không có quyền truy cập (401)');
      } else {
        debugPrint('Error getting habits due today (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi lấy danh sách thói quen hôm nay: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection error getting habits due today: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Get a specific habit schedule by ID
  Future<HabitSchedule> getHabitSchedule(int id) async {
    try {
      debugPrint("Getting habit schedule with id: $id from: $_baseUrl/api/HabitSchedule/$id");
      final headers = await _getHeaders();
      debugPrint("Making request with headers: $headers");
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/HabitSchedule/$id'),
        headers: headers,
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        return HabitSchedule.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy lịch trình thói quen');
      } else {
        debugPrint('Error getting habit schedule (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi lấy lịch trình thói quen: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection error getting habit schedule: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Create a new habit schedule
  Future<HabitSchedule> createHabitSchedule(HabitSchedule schedule) async {
    try {
      debugPrint("Creating habit schedule: ${schedule.toJson()}");
      final headers = await _getHeaders();
      debugPrint("Making request with headers: $headers");
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/HabitSchedule'),
        headers: headers,
        body: json.encode(schedule.toJson()),
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 201) {
        return HabitSchedule.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        debugPrint('Error creating habit schedule (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi tạo lịch trình thói quen: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection error creating habit schedule: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Update an existing habit schedule
  Future<void> updateHabitSchedule(int id, HabitSchedule schedule) async {
    try {
      debugPrint("Updating habit schedule with id: $id, data: ${schedule.toJson()}");
      final headers = await _getHeaders();
      debugPrint("Making request with headers: $headers");
      
      final response = await http.put(
        Uri.parse('$_baseUrl/api/HabitSchedule/$id'),
        headers: headers,
        body: json.encode(schedule.toJson()),
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 204) {
        return; // Success
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy lịch trình thói quen');
      } else {
        debugPrint('Error updating habit schedule (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi cập nhật lịch trình thói quen: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection error updating habit schedule: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Delete a habit schedule
  Future<void> deleteHabitSchedule(int id) async {
    try {
      debugPrint("Deleting habit schedule with id: $id");
      final headers = await _getHeaders();
      debugPrint("Making request with headers: $headers");
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/HabitSchedule/$id'),
        headers: headers,
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 204) {
        return; // Success
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy lịch trình thói quen');
      } else {
        debugPrint('Error deleting habit schedule (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi xóa lịch trình thói quen: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection error deleting habit schedule: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Test authentication endpoint
  Future<Map<String, dynamic>> testAuth() async {
    try {
      debugPrint("Testing authentication from: $_baseUrl/api/HabitSchedule/test-auth");
      final headers = await _getHeaders();
      debugPrint("Making request with headers: $headers");
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/HabitSchedule/test-auth'),
        headers: headers,
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error testing auth (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi kiểm tra xác thực: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection error testing auth: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }
}
