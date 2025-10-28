/// Model cho response login với 2FA
class TwoFactorLoginResponseModel {
  /// Có yêu cầu setup 2FA không (lần đầu)
  final bool requiresTwoFactorSetup;

  /// Có yêu cầu verify 2FA không (lần sau)
  final bool requiresTwoFactorVerification;

  /// Temporary token (5 phút) để verify OTP
  final String? tempToken;

  /// QR Code base64 (chỉ có khi requiresTwoFactorSetup = true)
  final String? qrCode;

  /// Secret Key (chỉ có khi requiresTwoFactorSetup = true)
  final String? secretKey;

  /// Access Token (chỉ có khi không cần 2FA)
  final String? accessToken;

  /// Refresh Token (chỉ có khi không cần 2FA)
  final String? refreshToken;

  /// Thời gian hết hạn của Access Token
  final DateTime? expiresAt;

  /// Thông tin user (chỉ có khi không cần 2FA)
  final Map<String, dynamic>? user;

  TwoFactorLoginResponseModel({
    required this.requiresTwoFactorSetup,
    required this.requiresTwoFactorVerification,
    this.tempToken,
    this.qrCode,
    this.secretKey,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.user,
  });

  /// Tạo model từ JSON
  factory TwoFactorLoginResponseModel.fromJson(Map<String, dynamic> json) {
    return TwoFactorLoginResponseModel(
      requiresTwoFactorSetup: json['requiresTwoFactorSetup'] ?? false,
      requiresTwoFactorVerification: json['requiresTwoFactorVerification'] ?? false,
      tempToken: json['tempToken'],
      qrCode: json['qrCode'],
      secretKey: json['secretKey'],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt']) 
          : null,
      user: json['user'],
    );
  }

  /// Chuyển model thành JSON
  Map<String, dynamic> toJson() {
    return {
      'requiresTwoFactorSetup': requiresTwoFactorSetup,
      'requiresTwoFactorVerification': requiresTwoFactorVerification,
      'tempToken': tempToken,
      'qrCode': qrCode,
      'secretKey': secretKey,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt?.toIso8601String(),
      'user': user,
    };
  }
}
