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

  // Keys để lưu trữ cài đặt
  static const String _notificationEnabledKey = 'notification_enabled';
  static const String _reminderEnabledKey = 'reminder_enabled';
  static const String _reminderTimeKey = 'reminder_time';
  static const String _phoneNumberKey = 'phone_number';

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

  /// Lưu Theme Preference
  Future<void> saveThemePreference(String themePreference) async {
    await _storage.write(key: _themePreferenceKey, value: themePreference);
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

  /// Cập nhật Full Name
  Future<void> updateFullName(String fullName) async {
    await _storage.write(key: _fullNameKey, value: fullName);
  }

  /// Cập nhật Email
  Future<void> updateEmail(String email) async {
    await _storage.write(key: _emailKey, value: email);
  }

  /// Cập nhật Username
  Future<void> updateUsername(String username) async {
    await _storage.write(key: _usernameKey, value: username);
  }

  /// Lưu số điện thoại
  Future<void> savePhoneNumber(String phoneNumber) async {
    await _storage.write(key: _phoneNumberKey, value: phoneNumber);
  }

  /// Lấy số điện thoại
  Future<String?> getPhoneNumber() async {
    return await _storage.read(key: _phoneNumberKey);
  }

  /// Lưu trạng thái thông báo
  Future<void> setNotificationEnabled(bool enabled) async {
    await _storage.write(
      key: _notificationEnabledKey,
      value: enabled.toString(),
    );
  }

  /// Kiểm tra trạng thái thông báo
  Future<bool> isNotificationEnabled() async {
    final value = await _storage.read(key: _notificationEnabledKey);
    return value != 'false'; // Mặc định là true nếu chưa set
  }

  /// Lưu trạng thái nhắc nhở
  Future<void> setReminderEnabled(bool enabled) async {
    await _storage.write(
      key: _reminderEnabledKey,
      value: enabled.toString(),
    );
  }

  /// Kiểm tra trạng thái nhắc nhở
  Future<bool> isReminderEnabled() async {
    final value = await _storage.read(key: _reminderEnabledKey);
    return value != 'false'; // Mặc định là true nếu chưa set
  }

  /// Lưu thời gian nhắc nhở
  Future<void> saveReminderTime(String time) async {
    await _storage.write(key: _reminderTimeKey, value: time);
  }

  /// Lấy thời gian nhắc nhở
  Future<String> getReminderTime() async {
    final time = await _storage.read(key: _reminderTimeKey);
    return time ?? '08:00'; // Mặc định là 8:00 AM
  }

  /// Keys for habit settings
  static const String _defaultHabitGoalKey = 'default_habit_goal';
  static const String _weekStartDayKey = 'week_start_day';
  static const String _habitColorKey = 'habit_color';
  
  // Default habit goal methods
  Future<void> saveDefaultHabitGoal(int goal) async {
    await _storage.write(key: _defaultHabitGoalKey, value: goal.toString());
  }

  Future<int> getDefaultHabitGoal() async {
    final goal = await _storage.read(key: _defaultHabitGoalKey);
    return goal != null ? int.tryParse(goal) ?? 7 : 7; // Default 7 days
  }

  // Week start day methods
  Future<void> saveWeekStartDay(int day) async {
    await _storage.write(key: _weekStartDayKey, value: day.toString());
  }

  Future<int> getWeekStartDay() async {
    final day = await _storage.read(key: _weekStartDayKey);
    return day != null ? int.tryParse(day) ?? 1 : 1; // Default Monday (1)
  }

  // Habit color methods
  Future<void> saveHabitColor(int colorValue) async {
    await _storage.write(key: _habitColorKey, value: colorValue.toString());
  }

  Future<int> getHabitColor() async {
    final color = await _storage.read(key: _habitColorKey);
    return color != null ? int.tryParse(color) ?? 0xFF6366F1 : 0xFF6366F1; // Default indigo color
  }
}
