// lib/api/habit_api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit_model.dart';
import '../models/category_model.dart';
import '../services/storage_service.dart'; // Assuming storage_service is in ../services/

class HabitApiService {
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

  // ========== CATEGORY ENDPOINTS ==========

  /// Get list of all user categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/category'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        // Decode response body explicitly as UTF8
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
          debugPrint('Error getting categories (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi lấy danh sách danh mục: ${response.statusCode}');
      }
    } catch (e) {
        debugPrint('Connection error getting categories: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Get list of default categories
  Future<List<CategoryModel>> getDefaultCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/category/default'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
          debugPrint('Error getting default categories (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi lấy danh sách danh mục mặc định: ${response.statusCode}');
      }
    } catch (e) {
        debugPrint('Connection error getting default categories: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Create a new category
  Future<CategoryModel> createCategory(CreateCategoryModel category) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/category'),
        headers: await _getHeaders(),
        body: json.encode(category.toJson()),
      );

      if (response.statusCode == 201) { // 201 Created
        return CategoryModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
          debugPrint('Error creating category (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi tạo danh mục: ${response.statusCode}');
      }
    } catch (e) {
        debugPrint('Connection error creating category: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Update a category
  Future<void> updateCategory(int id, CreateCategoryModel category) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/category/$id'),
        headers: await _getHeaders(),
        body: json.encode(category.toJson()),
      );

      if (response.statusCode != 204) { // 204 No Content
          debugPrint('Error updating category $id (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi cập nhật danh mục: ${response.statusCode}');
      }
    } catch (e) {
        debugPrint('Connection error updating category $id: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Delete a category
  Future<void> deleteCategory(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/category/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 400) {
        // Lỗi 400: Parse message từ backend
        debugPrint('Cannot delete category $id (400): ${response.body}');
        String errorMessage = 'Không thể xóa danh mục này';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (parseError) {
          debugPrint('Failed to parse error message: $parseError');
        }
        throw Exception(errorMessage);
      } else if (response.statusCode != 204) { // 204 No Content
        debugPrint('Error deleting category $id (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi xóa danh mục: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow; // Giữ nguyên Exception message từ trên
      }
      debugPrint('Connection error deleting category $id: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // ========== HABIT ENDPOINTS ==========

  /// Get list of all user habits
  Future<List<HabitModel>> getHabits() async {
    try {
      debugPrint("Getting habits from: $_baseUrl/api/habit");
      final headers = await _getHeaders();
      debugPrint("Making request with headers: $headers");
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/habit'),
        headers: headers,
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => HabitModel.fromJson(json)).toList();
      } else {
          debugPrint('Error getting habits (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi lấy danh sách thói quen: ${response.statusCode}');
      }
    } catch (e) {
        debugPrint('Connection error getting habits: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Get details of a specific habit
  Future<HabitModel> getHabit(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/habit/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return HabitModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
          debugPrint('Error getting habit $id (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi lấy thông tin thói quen: ${response.statusCode}');
      }
    } catch (e) {
        debugPrint('Connection error getting habit $id: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // ==========================================================
  // <<< BẮT ĐẦU SỬA HÀM createHabit >>>
  // ==========================================================
  /// Create a new habit
  Future<HabitModel> createHabit(CreateHabitModel habit) async {
    try {
      final headers = await _getHeaders();
      debugPrint('Creating habit with headers: $headers');
      
      // === SỬA LỖI: KHÔNG CẦN jsonData nữa ===
      // CreateHabitModel.toJson() đã xử lý đúng việc gán List<int>
      final body = json.encode(habit.toJson()); 
      
      // In ra JSON body (đã sửa)
      debugPrint('JSON body (Corrected): $body');
      debugPrint('Frequency: ${habit.frequency}');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/habit'),
        headers: headers,
        body: body, // <<< Gửi body đã encode đúng
      );

      if (response.statusCode == 201) { // 201 Created
        return HabitModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
          // Log detailed error from backend if available
          debugPrint('Error creating habit (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi tạo thói quen: ${response.statusCode}');
      }
    } catch (e) {
        debugPrint('Connection error creating habit: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }
  // ==========================================================
  // <<< KẾT THÚC SỬA HÀM createHabit >>>
  // ==========================================================


  /// Update a habit
  Future<void> updateHabit(int id, UpdateHabitModel habit) async { // <-- Đã sửa thành UpdateHabitModel
    try {
      final headers = await _getHeaders();
      
      // Dòng này sẽ tự động gọi hàm toJson() của UpdateHabitModel
      final body = json.encode(habit.toJson()); 
      
      debugPrint('Updating habit $id with headers: $headers');
      debugPrint('Updating habit $id with body: $body'); // In ra body đã được chuyển đổi

      final response = await http.put(
        Uri.parse('$_baseUrl/api/habit/$id'),
        headers: headers,
        body: body, // Gửi body đã chuyển đổi
      );

      if (response.statusCode != 204) { // 204 No Content
          debugPrint('Error updating habit $id (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi cập nhật thói quen: ${response.statusCode}');
      }
        debugPrint('Successfully updated habit $id');
    } catch (e) {
        debugPrint('Connection error updating habit $id: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }
  

  /// Delete a habit
  Future<void> deleteHabit(int id) async {
    try {
      final headers = await _getHeaders();
      debugPrint('Deleting habit $id with headers: $headers');

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/habit/$id'),
        headers: headers,
      );

      if (response.statusCode != 204) { // 204 No Content
          debugPrint('Error deleting habit $id (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi xóa thói quen: ${response.statusCode}');
      }
        debugPrint('Successfully deleted habit $id');
    } catch (e) {
        debugPrint('Connection error deleting habit $id: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Mark a habit as completed for a specific date
  Future<void> completeHabit(int id, {String? notes, DateTime? completedAt}) async {
    try {
      final body = <String, dynamic>{};
      if (notes != null) body['notes'] = notes;
      
      // Gửi thời gian đã được chuyển sang UTC (hoặc UTC nếu null)
      final completionTime = completedAt?.toUtc() ?? DateTime.now().toUtc(); // <<< SỬA: Đảm bảo là UTC
      body['completedAt'] = completionTime.toIso8601String();

      final headers = await _getHeaders();
      debugPrint('Completing habit $id with headers: $headers');
      debugPrint('Completing habit $id with completionTime (UTC): $completionTime'); // Log giờ UTC
      debugPrint('Completing habit $id with body: ${json.encode(body)}');


      final response = await http.post(
        Uri.parse('$_baseUrl/api/habit/$id/complete'),
        headers: headers,
        body: json.encode(body),
      );

      // Backend might return 200 OK or 201 Created depending on implementation
      if (response.statusCode != 200 && response.statusCode != 201) {
          debugPrint('Error completing habit $id (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi đánh dấu hoàn thành thói quen: ${response.statusCode}');
      }
        debugPrint('Successfully completed habit $id');
    } catch (e) {
        debugPrint('Connection error completing habit $id: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Get completion history for a habit
  Future<List<HabitCompletionModel>> getHabitCompletions(
    int id, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String url = '$_baseUrl/api/habit/$id/completions';
      List<String> queryParams = [];
      if (startDate != null) queryParams.add('startDate=${startDate.toUtc().toIso8601String()}');
      if (endDate != null) queryParams.add('endDate=${endDate.toUtc().toIso8601String()}');
      if (queryParams.isNotEmpty) url += '?${queryParams.join('&')}';

      final response = await http.get(Uri.parse(url), headers: await _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => HabitCompletionModel.fromJson(json)).toList();
      } else {
          debugPrint('Error getting completions for habit $id (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi lấy lịch sử hoàn thành: ${response.statusCode}');
      }
    } catch (e) {
        debugPrint('Connection error getting completions for habit $id: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }
  
}