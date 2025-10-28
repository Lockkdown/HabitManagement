import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_list_model.dart';
import '../services/storage_service.dart';

/// Service xử lý các API calls cho Admin
class AdminApiService {
  /// Lấy base URL từ file .env
  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:5224';
  
  final StorageService _storageService = StorageService();

  /// Lấy headers với access token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  /// Lấy danh sách tất cả users
  Future<List<UserListModel>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/admin/users'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserListModel.fromJson(json)).toList();
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Lấy danh sách users thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Lấy chi tiết một user
  Future<UserListModel> getUserDetail(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/admin/users/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return UserListModel.fromJson(jsonDecode(response.body));
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Lấy chi tiết user thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Kích hoạt/Vô hiệu hóa tài khoản
  Future<String> toggleLockout(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/users/$userId/toggle-lockout'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data['message'] ?? 'Thao tác thành công';
      } else {
        throw Exception(data['message'] ?? 'Thao tác thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Reset mật khẩu về mặc định
  Future<String> resetPassword(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/users/$userId/reset-password'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final newPassword = data['newPassword'] ?? 'User@123';
        return 'Reset mật khẩu thành công. Mật khẩu mới: $newPassword';
      } else {
        throw Exception(data['message'] ?? 'Reset mật khẩu thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Xóa user
  Future<String> deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/admin/users/$userId'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data['message'] ?? 'Xóa user thành công';
      } else {
        throw Exception(data['message'] ?? 'Xóa user thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Gán role cho user
  Future<String> assignRole(String userId, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/users/assign-role'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'userId': userId,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data['message'] ?? 'Gán role thành công';
      } else {
        throw Exception(data['message'] ?? 'Gán role thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}
