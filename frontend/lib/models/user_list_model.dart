/// Model cho danh sách users (Admin view)
class UserListModel {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final bool emailConfirmed;
  final bool lockoutEnabled;
  final DateTime? lockoutEnd;
  final List<String> roles;
  final bool twoFactorEnabled;
  final bool twoFactorSetupCompleted;

  UserListModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.emailConfirmed,
    required this.lockoutEnabled,
    this.lockoutEnd,
    required this.roles,
    required this.twoFactorEnabled,
    required this.twoFactorSetupCompleted,
  });

  /// Tạo từ JSON
  factory UserListModel.fromJson(Map<String, dynamic> json) {
    return UserListModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'],
      emailConfirmed: json['emailConfirmed'] ?? false,
      lockoutEnabled: json['lockoutEnabled'] ?? false,
      lockoutEnd: json['lockoutEnd'] != null 
          ? DateTime.parse(json['lockoutEnd']) 
          : null,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [],
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
      twoFactorSetupCompleted: json['twoFactorSetupCompleted'] ?? false,
    );
  }

  /// Check xem user có bị khóa không
  bool get isLocked {
    return lockoutEnd != null && lockoutEnd!.isAfter(DateTime.now());
  }

  /// Check xem user có phải Admin không
  bool get isAdmin {
    return roles.contains('Admin');
  }
}
