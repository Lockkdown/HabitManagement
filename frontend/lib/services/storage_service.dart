import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service quản lý lưu trữ an toàn các thông tin nhạy cảm
/// Sử dụng flutter_secure_storage để mã hóa dữ liệu
class StorageService {
  /// Instance của FlutterSecureStorage
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Keys để lưu trữ
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';
  static const String _fullNameKey = 'full_name';
  static const String _themePreferenceKey = 'theme_preference';
  static const String _languageCodeKey = 'language_code';
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Lưu Access Token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// Lấy Access Token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Lưu Refresh Token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Lấy Refresh Token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Lưu toàn bộ thông tin người dùng sau khi đăng nhập
  Future<void> saveUserInfo({
    required String userId,
    required String username,
    required String email,
    required String fullName,
    required String themePreference,
    required String languageCode,
  }) async {
    await Future.wait([
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _usernameKey, value: username),
      _storage.write(key: _emailKey, value: email),
      _storage.write(key: _fullNameKey, value: fullName),
      _storage.write(key: _themePreferenceKey, value: themePreference),
      _storage.write(key: _languageCodeKey, value: languageCode),
    ]);
  }

  /// Lấy User ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Lấy Username
  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  /// Lấy Email
  Future<String?> getEmail() async {
    return await _storage.read(key: _emailKey);
  }

  /// Lấy Full Name
  Future<String?> getFullName() async {
    return await _storage.read(key: _fullNameKey);
  }

  /// Lấy Theme Preference
  Future<String?> getThemePreference() async {
    return await _storage.read(key: _themePreferenceKey);
  }

  /// Lấy Language Code
  Future<String?> getLanguageCode() async {
    return await _storage.read(key: _languageCodeKey);
  }

  /// Lưu trạng thái bật/tắt đăng nhập sinh trắc học
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  /// Kiểm tra xem đăng nhập sinh trắc học đã được bật chưa
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// Kiểm tra xem người dùng đã đăng nhập chưa
  /// Dựa vào việc có Access Token hay không
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Xóa toàn bộ dữ liệu đăng nhập (đăng xuất)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Xóa chỉ tokens (giữ lại thông tin user)
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}
