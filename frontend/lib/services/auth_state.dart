import '../models/user_model.dart';

/// Các trạng thái của quá trình xác thực
enum AuthStatus {
  /// Chưa xác định (đang kiểm tra)
  initial,

  /// Đã đăng nhập
  authenticated,

  /// Chưa đăng nhập
  unauthenticated,

  /// Đang trong quá trình xác thực
  loading,
}

/// State quản lý trạng thái xác thực
class AuthState {
  /// Trạng thái hiện tại
  final AuthStatus status;

  /// Thông tin người dùng (null nếu chưa đăng nhập)
  final UserModel? user;

  /// Thông báo lỗi (null nếu không có lỗi)
  final String? errorMessage;

  /// Khởi tạo AuthState
  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  /// State ban đầu (chưa xác định)
  factory AuthState.initial() {
    return AuthState(status: AuthStatus.initial);
  }

  /// State đang loading
  factory AuthState.loading() {
    return AuthState(status: AuthStatus.loading);
  }

  /// State đã đăng nhập thành công
  factory AuthState.authenticated(UserModel user) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
    );
  }

  /// State chưa đăng nhập
  factory AuthState.unauthenticated({String? errorMessage}) {
    return AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: errorMessage,
    );
  }

  /// Tạo bản sao với các giá trị được cập nhật
  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
