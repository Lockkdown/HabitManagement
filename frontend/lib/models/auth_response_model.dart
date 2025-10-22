import 'user_model.dart';

/// Model chứa thông tin phản hồi từ API sau khi đăng nhập thành công
class AuthResponseModel {
  /// Thông tin người dùng
  final UserModel user;

  /// Access Token (JWT) để xác thực các request
  final String accessToken;

  /// Refresh Token để lấy Access Token mới khi hết hạn
  final String refreshToken;

  /// Thời gian hết hạn của Access Token
  final DateTime expiresAt;

  /// Khởi tạo AuthResponseModel
  AuthResponseModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  /// Tạo AuthResponseModel từ JSON
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: UserModel.fromJson(json),
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Chuyển AuthResponseModel thành JSON
  Map<String, dynamic> toJson() {
    return {
      ...user.toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}
