import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/storage_service.dart';

/// Service để gọi các API endpoints liên quan đến thống kê
class StatisticsApiService {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://localhost:7297';
  final StorageService _storageService = StorageService();

  /// Lấy headers với JWT token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  /// Lấy thống kê tổng quan
  Future<Map<String, dynamic>> getOverviewStatistics() async {
    try {
      final headers = await _getHeaders();
      print('Making request to: $_baseUrl/api/Statistics/overview');
      print('Headers: $headers');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/Statistics/overview'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          throw Exception('Server trả về dữ liệu rỗng');
        }
        
        try {
          return json.decode(responseBody);
        } catch (e) {
          print('JSON decode error: $e');
          print('Raw response: $responseBody');
          throw Exception('Dữ liệu không hợp lệ từ server');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết hạn');
      } else {
        throw Exception('Không thể tải thống kê tổng quan (${response.statusCode})');
      }
    } catch (e) {
      print('Error in getOverviewStatistics: $e');
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Lấy dữ liệu heatmap cho tất cả thói quen
  Future<List<dynamic>> getHeatmapData({int days = 365}) async {
    try {
      final headers = await _getHeaders();
      print('Making request to: $_baseUrl/api/Statistics/heatmap?days=$days');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/Statistics/heatmap?days=$days'),
        headers: headers,
      );

      print('Heatmap response status: ${response.statusCode}');
      print('Heatmap response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          throw Exception('Server trả về dữ liệu heatmap rỗng');
        }
        
        try {
          return json.decode(responseBody);
        } catch (e) {
          print('Heatmap JSON decode error: $e');
          print('Raw heatmap response: $responseBody');
          throw Exception('Dữ liệu heatmap không hợp lệ từ server');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết hạn');
      } else {
        throw Exception('Không thể tải dữ liệu heatmap (${response.statusCode})');
      }
    } catch (e) {
      print('Error in getHeatmapData: $e');
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Lấy chi tiết thống kê cho một thói quen cụ thể
  Future<Map<String, dynamic>> getHabitDetails(int habitId, {int days = 365}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/Statistics/habit/$habitId/details?days=$days'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết hạn');
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy thói quen');
      } else {
        throw Exception('Không thể tải chi tiết thói quen');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Lấy dữ liệu heatmap cho tháng cụ thể
  Future<List<dynamic>> getMonthlyHeatmapData(int habitId, DateTime month) async {
    try {
      final headers = await _getHeaders();
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);
      final days = endDate.difference(startDate).inDays + 1;
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/Statistics/habit/$habitId/details?days=$days'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['completionData'] ?? [];
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết hạn');
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy thói quen');
      } else {
        throw Exception('Không thể tải dữ liệu tháng');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }
}