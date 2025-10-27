import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/storage_service.dart';

/// Service để gọi các API liên quan đến thông tin người dùng
class UserApiService {
  /// Lấy base URL từ file .env
  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:5224';
  final StorageService _storageService = StorageService();

  /// Lấy headers với Authorization token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Lấy thông tin profile người dùng
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/user/profile'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Lỗi khi lấy thông tin người dùng: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Cập nhật thông tin profile người dùng
  Future<void> updateUserProfile({
    String? username,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? themePreference,
    String? languageCode,
    bool? notificationEnabled,
    bool? reminderEnabled,
    String? reminderTime,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      
      if (username != null) body['username'] = username;
      if (fullName != null) body['fullName'] = fullName;
      if (email != null) body['email'] = email;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (themePreference != null) body['themePreference'] = themePreference;
      if (languageCode != null) body['languageCode'] = languageCode;
      if (notificationEnabled != null) body['notificationEnabled'] = notificationEnabled;
      if (reminderEnabled != null) body['reminderEnabled'] = reminderEnabled;
      if (reminderTime != null) body['reminderTime'] = reminderTime;

      final response = await http.put(
        Uri.parse('$_baseUrl/api/user/profile'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Lỗi khi cập nhật thông tin người dùng');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}