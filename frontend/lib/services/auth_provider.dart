import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/auth_api_service.dart';
import '../models/user_model.dart';
import 'auth_state.dart';
import 'storage_service.dart';

/// Provider cho AuthApiService
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService();
});

/// Provider cho StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider chính quản lý trạng thái xác thực
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Notifier quản lý logic xác thực
class AuthNotifier extends Notifier<AuthState> {
  late final AuthApiService _authApiService;
  late final StorageService _storageService;

  /// Khởi tạo state ban đầu
  @override
  AuthState build() {
    // Khởi tạo services
    _authApiService = ref.read(authApiServiceProvider);
    _storageService = ref.read(storageServiceProvider);
    
    // Kiểm tra trạng thái đăng nhập khi khởi tạo
    _checkAuthStatus();
    
    return AuthState.initial();
  }

  /// Kiểm tra xem người dùng đã đăng nhập chưa
  /// Được gọi khi app khởi động
  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await _storageService.isLoggedIn();

      if (isLoggedIn) {
        // Lấy thông tin user từ storage
        final userId = await _storageService.getUserId();
        final username = await _storageService.getUsername();
        final email = await _storageService.getEmail();
        final fullName = await _storageService.getFullName();
        final themePreference = await _storageService.getThemePreference();
        final languageCode = await _storageService.getLanguageCode();

        if (userId != null &&
            username != null &&
            email != null &&
            fullName != null) {
          final user = UserModel(
            userId: userId,
            username: username,
            email: email,
            fullName: fullName,
            themePreference: themePreference ?? 'light',
            languageCode: languageCode ?? 'vi',
          );

          state = AuthState.authenticated(user);
        } else {
          state = AuthState.unauthenticated();
        }
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated(
        errorMessage: 'Lỗi khi kiểm tra trạng thái đăng nhập',
      );
    }
  }

  /// Đăng ký người dùng mới
  Future<bool> register({
    required String username,
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    String? phoneNumber,
    DateTime? dateOfBirth,
  }) async {
    try {
      // KHÔNG set loading state ở đây để tránh app chuyển sang splash screen
      // RegisterScreen sẽ tự quản lý loading indicator của riêng nó

      await _authApiService.register(
        username: username,
        fullName: fullName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
      );

      // Giữ state unauthenticated sau khi đăng ký thành công
      state = AuthState.unauthenticated();
      return true;
    } catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.toString());
      return false;
    }
  }

  /// Đăng nhập người dùng
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      // KHÔNG set loading state ở đây để tránh app chuyển sang splash screen
      // LoginScreen sẽ tự quản lý loading indicator của riêng nó

      final authResponse = await _authApiService.login(
        email: email,
        password: password,
      );

      // Lưu tokens và thông tin user vào storage
      await _storageService.saveAccessToken(authResponse.accessToken);
      await _storageService.saveRefreshToken(authResponse.refreshToken);
      await _storageService.saveUserInfo(
        userId: authResponse.user.userId,
        username: authResponse.user.username,
        email: authResponse.user.email,
        fullName: authResponse.user.fullName,
        themePreference: authResponse.user.themePreference,
        languageCode: authResponse.user.languageCode,
      );

      state = AuthState.authenticated(authResponse.user);
      return true;
    } catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.toString());
      return false;
    }
  }

  /// Đăng xuất người dùng
  Future<void> logout() async {
    await _storageService.clearAll();
    state = AuthState.unauthenticated();
  }

  /// Yêu cầu reset mật khẩu
  /// Trả về tokenId để polling, hoặc null nếu thất bại
  Future<String?> forgotPassword({required String email}) async {
    try {
      print('AuthProvider: Calling forgotPassword API for email: $email');
      final tokenId = await _authApiService.forgotPassword(email: email);
      print('AuthProvider: Received tokenId: $tokenId');
      return tokenId;
    } catch (e) {
      print('AuthProvider: Error in forgotPassword: $e');
      return null;
    }
  }

  /// Lấy thông tin user hiện tại
  UserModel? get currentUser => state.user;

  /// Kiểm tra xem đã đăng nhập chưa
  bool get isAuthenticated => state.status == AuthStatus.authenticated;
}
