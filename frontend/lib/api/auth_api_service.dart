import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/auth_response_model.dart';

/// Service xử lý các API calls liên quan đến xác thực
class AuthApiService {
  /// Lấy base URL từ file .env
  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:5224';

  /// Đăng ký người dùng mới
  ///
  /// Nhận vào [username], [fullName], [email], [password], [confirmPassword]
  /// và các thông tin tùy chọn như [phoneNumber], [dateOfBirth]
  ///
  /// Trả về message nếu thành công, throw Exception nếu thất bại
  Future<String> register({
    required String username,
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    String? phoneNumber,
    DateTime? dateOfBirth,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'fullName': fullName,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'phoneNumber': phoneNumber,
          'dateOfBirth': dateOfBirth?.toIso8601String(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['message'] ?? 'Đăng ký thành công';
      } else {
        throw Exception(data['message'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Đăng nhập người dùng
  ///
  /// Nhận vào [email] và [password]
  ///
  /// Trả về [AuthResponseModel] chứa thông tin user và tokens
  /// Throw Exception nếu đăng nhập thất bại
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResponseModel.fromJson(data);
      } else {
        throw Exception(data['message'] ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Yêu cầu reset mật khẩu
  ///
  /// Gửi email chứa link reset mật khẩu đến [email]
  ///
  /// Trả về tokenId để polling status
  Future<String> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('Forgot password response status: ${response.statusCode}');
      print('Forgot password response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final tokenId = data['tokenId'] ?? '';
        print('TokenId received: $tokenId');
        
        if (tokenId.isEmpty) {
          throw Exception('TokenId is empty in response');
        }
        
        return tokenId;
      } else {
        throw Exception(data['message'] ?? 'Yêu cầu thất bại');
      }
    } catch (e) {
      print('Forgot password error: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Kiểm tra trạng thái token reset password
  ///
  /// App sẽ polling endpoint này để biết khi nào user đã click link
  ///
  /// Trả về object chứa isVerified và token (nếu đã verified)
  Future<Map<String, dynamic>> checkTokenStatus({required String tokenId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/check-token-status?tokenId=$tokenId'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'isVerified': data['isVerified'] ?? false,
          'token': data['token'],
          'message': data['message'] ?? '',
        };
      } else {
        throw Exception(data['message'] ?? 'Kiểm tra thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Đặt lại mật khẩu với token từ email
  ///
  /// Nhận vào [email], [token] từ email, [newPassword] và [confirmPassword]
  ///
  /// Trả về message nếu thành công
  Future<String> resetPassword({
    required String email,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['message'] ?? 'Đặt lại mật khẩu thành công';
      } else {
        throw Exception(data['message'] ?? 'Đặt lại mật khẩu thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Kiểm tra trạng thái API server
  ///
  /// Trả về message từ server nếu hoạt động tốt
  Future<String> ping() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/ping'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['message'] ?? 'Server đang hoạt động';
      } else {
        throw Exception('Server không phản hồi');
      }
    } catch (e) {
      throw Exception('Không thể kết nối tới server: $e');
    }
  }
}
