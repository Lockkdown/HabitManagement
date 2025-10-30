/// Model đại diện cho thông tin người dùng
class UserModel {
  /// ID duy nhất của người dùng
  final String userId;

  /// Tên đăng nhập
  final String username;

  /// Địa chỉ email
  final String email;

  /// Họ và tên đầy đủ
  final String fullName;

  /// Lựa chọn giao diện (light, dark, system)
  final String themePreference;

  /// Mã ngôn ngữ (vi, en)
  final String languageCode;

  /// Khởi tạo UserModel
  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.fullName,
    required this.themePreference,
    required this.languageCode,
  });

  /// Tạo UserModel từ JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      themePreference: json['themePreference'] ?? 'dark',
      languageCode: json['languageCode'] ?? 'vi',
    );
  }

  /// Chuyển UserModel thành JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'fullName': fullName,
      'themePreference': themePreference,
      'languageCode': languageCode,
    };
  }

  /// Tạo bản sao của UserModel với các giá trị được cập nhật
  UserModel copyWith({
    String? userId,
    String? username,
    String? email,
    String? fullName,
    String? themePreference,
    String? languageCode,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      themePreference: themePreference ?? this.themePreference,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}
