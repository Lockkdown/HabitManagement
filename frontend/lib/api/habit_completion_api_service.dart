import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/storage_service.dart';

/// Service để xử lý các thao tác liên quan đến completion của thói quen
class HabitCompletionApiService {
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

  /// Đánh dấu thói quen hoàn thành cho ngày cụ thể
  Future<void> markAsCompleted(int habitId, DateTime date, {String? notes}) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'completedAt': date.toIso8601String(),
        if (notes != null) 'notes': notes,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/api/habit/$habitId/complete'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Không thể đánh dấu hoàn thành thói quen');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Xóa completion cho ngày cụ thể
  Future<void> deleteCompletion(int habitId, DateTime date) async {
    try {
      final headers = await _getHeaders();
      
      // Lấy danh sách completions để tìm completion cần xóa
      final completions = await getHabitCompletions(habitId);
      
      // Tìm completion cho ngày cụ thể
      final targetDate = DateTime(date.year, date.month, date.day);
      final completion = completions.firstWhere(
        (c) {
          final completionDate = DateTime.parse(c['completedAt']);
          final completionDateOnly = DateTime(
            completionDate.year, 
            completionDate.month, 
            completionDate.day
          );
          return completionDateOnly.isAtSameMomentAs(targetDate);
        },
        orElse: () => null,
      );

      if (completion != null) {
        final response = await http.delete(
          Uri.parse('$_baseUrl/api/habit/$habitId/completions/${completion['id']}'),
          headers: headers,
        );

        if (response.statusCode != 200 && response.statusCode != 204) {
          throw Exception('Không thể xóa completion');
        }
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Lấy danh sách completions của thói quen
  Future<List<dynamic>> getHabitCompletions(int habitId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final headers = await _getHeaders();
      String url = '$_baseUrl/api/habit/$habitId/completions';
      
      List<String> queryParams = [];
      if (startDate != null) {
        queryParams.add('startDate=${startDate.toUtc().toIso8601String()}');
      }
      if (endDate != null) {
        queryParams.add('endDate=${endDate.toUtc().toIso8601String()}');
      }
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết hạn');
      } else {
        throw Exception('Không thể lấy danh sách completions');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Kiểm tra xem thói quen đã hoàn thành trong ngày cụ thể chưa
  Future<bool> isCompletedOnDate(int habitId, DateTime date) async {
    try {
      final completions = await getHabitCompletions(habitId);
      final targetDate = DateTime(date.year, date.month, date.day);
      
      return completions.any((completion) {
        final completionDate = DateTime.parse(completion['completedAt']);
        final completionDateOnly = DateTime(
          completionDate.year, 
          completionDate.month, 
          completionDate.day
        );
        return completionDateOnly.isAtSameMomentAs(targetDate);
      });
    } catch (e) {
      return false;
    }
  }
}