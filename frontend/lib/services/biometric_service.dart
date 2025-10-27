import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// Service quản lý xác thực sinh trắc học (vân tay, khuôn mặt)
/// Sử dụng local_auth plugin để tương tác với API sinh trắc học của Android
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Kiểm tra thiết bị có hỗ trợ sinh trắc học không
  /// Trả về true nếu thiết bị có cảm biến sinh trắc học hoặc hỗ trợ xác thực
  Future<bool> canUseBiometric() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } catch (e) {
      print('BiometricService: Lỗi kiểm tra hỗ trợ sinh trắc học: $e');
      return false;
    }
  }

  /// Lấy danh sách các phương thức sinh trắc học có sẵn trên thiết bị
  /// Ví dụ: BiometricType.fingerprint, BiometricType.face, BiometricType.strong
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();
      
      print('BiometricService: Sinh trắc học có sẵn: $availableBiometrics');
      return availableBiometrics;
    } catch (e) {
      print('BiometricService: Lỗi lấy danh sách sinh trắc học: $e');
      return [];
    }
  }

  /// Xác thực sinh trắc học (chỉ sinh trắc học, không cho phép PIN/Pattern)
  /// Trả về true nếu xác thực thành công, false nếu thất bại hoặc hủy bỏ
  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Xác thực để đăng nhập vào Habit Management',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Xác thực sinh trắc học',
            cancelButton: 'Hủy',
          ),
        ],
      );

      print('BiometricService: Kết quả xác thực: $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      print('BiometricService: Lỗi xác thực sinh trắc học: $e');
      return false;
    }
  }

  /// Xác thực với fallback (cho phép PIN/Pattern nếu sinh trắc học thất bại)
  /// Trả về true nếu xác thực thành công (bằng sinh trắc học hoặc PIN/Pattern)
  Future<bool> authenticateWithFallback() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Xác thực để đăng nhập vào Habit Management',
        biometricOnly: false, // Cho phép fallback
        persistAcrossBackgrounding: true,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Xác thực',
            cancelButton: 'Hủy',
          ),
        ],
      );

      print('BiometricService: Kết quả xác thực (với fallback): $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      print('BiometricService: Lỗi xác thực: $e');
      return false;
    }
  }

  /// Kiểm tra xem có sinh trắc học nào được đăng ký không
  /// Trả về true nếu người dùng đã đăng ký ít nhất 1 phương thức sinh trắc học
  Future<bool> hasBiometricEnrolled() async {
    try {
      final List<BiometricType> availableBiometrics =
          await getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      print('BiometricService: Lỗi kiểm tra đăng ký sinh trắc học: $e');
      return false;
    }
  }
}
