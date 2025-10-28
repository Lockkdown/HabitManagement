import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_notification.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../services/auth_provider.dart';
import '../services/biometric_service.dart';
import '../services/storage_service.dart';
import '../api/auth_api_service.dart';
import 'register_screen.dart';
import 'waiting_verification_screen.dart';
import 'home_screen.dart';
import 'setup_2fa_screen.dart';
import 'verify_2fa_screen.dart';
import 'admin_dashboard_screen.dart';
import '../utils/jwt_decoder.dart';

/// Màn hình đăng nhập
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  /// API Service cho 2FA
  final _authApiService = AuthApiService();
  
  /// Controller cho các text field
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  /// Key cho form validation
  final _formKey = GlobalKey<FormState>();
  
  /// Trạng thái hiển thị/ẩn mật khẩu
  bool _obscurePassword = true;

  /// Trạng thái loading
  bool _isLoading = false;

  /// Trạng thái sinh trắc học đã được bật
  bool _biometricEnabled = false;
  
  /// Chế độ đăng nhập: true = Quick Login (chỉ password), false = Full Login (email + password)
  bool _isQuickLogin = false;
  
  /// Thông tin user đã đăng nhập trước (cho Quick Login)
  String? _savedUsername;
  String? _savedFullName;
  String? _savedEmail;

  @override
  void initState() {
    super.initState();
    _checkLoginMode();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload login mode mỗi khi dependencies thay đổi
    _checkLoginMode();
  }

  /// Kiểm tra chế độ đăng nhập (Quick Login hay Full Login)
  Future<void> _checkLoginMode() async {
    final storageService = StorageService();
    
    // Kiểm tra có refresh token không
    final refreshToken = await storageService.getRefreshToken();
    
    // Kiểm tra có thông tin user đã lưu không
    final username = await storageService.getUsername();
    final fullName = await storageService.getFullName();
    final email = await storageService.getEmail();
    
    // Kiểm tra sinh trắc học có bật không
    final biometricEnabled = await storageService.isBiometricEnabled();
    
    if (mounted) {
      setState(() {
        // Quick Login nếu có refresh token VÀ có username
        _isQuickLogin = refreshToken != null && username != null;
        _savedUsername = username;
        _savedFullName = fullName;
        _savedEmail = email;
        _biometricEnabled = biometricEnabled;
      });
    }
  }
  
  /// Chuyển về Full Login (khi nhấn "Đăng nhập tài khoản khác")
  void _switchToFullLogin() {
    setState(() {
      _isQuickLogin = false;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Xử lý đăng nhập bằng sinh trắc học
  Future<void> _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi biộmetricLogin từ AuthProvider (bao gồm cả xác thực sinh trắc học)
      final success = await ref.read(authProvider.notifier).biometricLogin();

      if (!mounted) return;

      if (success) {
        // Hiển thị thông báo thành công
        AppNotification.showSuccess(context, 'Đăng nhập thành công!');

        // Navigate đến HomeScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        AppNotification.showError(context, 'Đăng nhập thất bại. Vui lòng đăng nhập bằng email/password');
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Xử lý đăng nhập với hỗ trợ 2FA
  Future<void> _handleLogin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Bắt đầu loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi API đăng nhập với 2FA
      final response = await _authApiService.loginWith2FA(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Case 1: Admin lần đầu - cần setup 2FA
      if (response.requiresTwoFactorSetup) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Setup2FAScreen(
              twoFactorResponse: response,
            ),
          ),
        );
        return;
      }

      // Case 2: Admin lần sau - cần verify OTP
      if (response.requiresTwoFactorVerification) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Verify2FAScreen(
              tempToken: response.tempToken!,
            ),
          ),
        );
        return;
      }

      // Case 3: User thường - không cần 2FA, lưu thông tin và navigate
      if (response.accessToken != null && response.user != null) {
        final storageService = StorageService();
        
        // Lưu tokens
        await storageService.saveAccessToken(response.accessToken!);
        await storageService.saveRefreshToken(response.refreshToken!);
        
        // Lưu thông tin user
        await storageService.saveUserInfo(
          userId: response.user!['userId'] ?? '',
          username: response.user!['username'] ?? '',
          email: response.user!['email'] ?? '',
          fullName: response.user!['fullName'] ?? '',
          themePreference: response.user!['themePreference'] ?? 'dark',
          languageCode: response.user!['languageCode'] ?? 'vi',
        );

        if (!mounted) return;

        // Hiển thị thông báo thành công
        AppNotification.showSuccess(context, 'Đăng nhập thành công!');

        // Hỏi bật sinh trậc học (chỉ cho User thường)
        final isAdmin = JwtDecoder.isAdmin(response.accessToken!);
        if (!isAdmin) {
          await _askEnableBiometric();
        }

        // Navigate: Admin → Dashboard, User → Home
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          if (isAdmin) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
            );
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      AppNotification.showError(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Xử lý Quick Login (chỉ cần password) với hỗ trợ 2FA
  Future<void> _handleQuickLogin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Kiểm tra có email đã lưu không
    if (_savedEmail == null || _savedEmail!.isEmpty) {
      AppNotification.showError(context, 'Không tìm thấy thông tin đăng nhập');
      return;
    }

    // Bắt đầu loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi API đăng nhập với 2FA
      final response = await _authApiService.loginWith2FA(
        email: _savedEmail!,
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Case 1: Admin lần đầu - cần setup 2FA
      if (response.requiresTwoFactorSetup) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Setup2FAScreen(
              twoFactorResponse: response,
            ),
          ),
        );
        return;
      }

      // Case 2: Admin lần sau - cần verify OTP
      if (response.requiresTwoFactorVerification) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Verify2FAScreen(
              tempToken: response.tempToken!,
            ),
          ),
        );
        return;
      }

      // Case 3: User thường - không cần 2FA
      if (response.accessToken != null && response.user != null) {
        final storageService = StorageService();
        
        // Lưu tokens
        await storageService.saveAccessToken(response.accessToken!);
        await storageService.saveRefreshToken(response.refreshToken!);
        
        // Lưu thông tin user
        await storageService.saveUserInfo(
          userId: response.user!['userId'] ?? '',
          username: response.user!['username'] ?? '',
          email: response.user!['email'] ?? '',
          fullName: response.user!['fullName'] ?? '',
          themePreference: response.user!['themePreference'] ?? 'dark',
          languageCode: response.user!['languageCode'] ?? 'vi',
        );

        if (!mounted) return;

        // Hiển thị thông báo thành công
        AppNotification.showSuccess(context, 'Đăng nhập thành công!');

        // Navigate: Admin → Dashboard, User → Home (không hỏi biometric)
        if (mounted) {
          final isAdmin = JwtDecoder.isAdmin(response.accessToken!);
          if (isAdmin) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      AppNotification.showError(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Hỏi người dùng có muốn bật sinh trắc học không
  Future<void> _askEnableBiometric() async {
    try {
      debugPrint('LoginScreen: _askEnableBiometric() được gọi');
      
      final storageService = ref.read(storageServiceProvider);
      final biometricService = BiometricService();

      // Kiểm tra xem đã bật sinh trắc học chưa
      final alreadyEnabled = await storageService.isBiometricEnabled();
      debugPrint('LoginScreen: alreadyEnabled = $alreadyEnabled');
      
      if (alreadyEnabled) {
        debugPrint('LoginScreen: Sinh trắc học đã được bật, bỏ qua hỏi');
        return;
      }

      // Kiểm tra thiết bị có hỗ trợ không
      final canUseBiometric = await biometricService.canUseBiometric();
      debugPrint('LoginScreen: canUseBiometric = $canUseBiometric');
      
      if (!canUseBiometric) {
        debugPrint('LoginScreen: Thiết bị không hỗ trợ sinh trắc học');
        return;
      }

      // Kiểm tra có sinh trắc học nào được đăng ký không
      final availableBiometrics = await biometricService.getAvailableBiometrics();
      debugPrint('LoginScreen: availableBiometrics = $availableBiometrics');
      
      if (availableBiometrics.isEmpty) {
        debugPrint('LoginScreen: Chưa đăng ký sinh trắc học trong cài đặt');
        return;
      }

      // Hiển thị dialog
      debugPrint('LoginScreen: Hiển thị dialog...');
      
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: Icon(
            LucideIcons.fingerprint,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          title: const Text('Bật sinh trắc học?'),
          content: const Text(
            'Bạn có muốn sử dụng vân tay hoặc khuôn mặt để đăng nhập nhanh hơn trong lần sau không?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(LucideIcons.check),
              label: const Text('Có, bật ngay'),
            ),
          ],
        ),
      );
      
      debugPrint('LoginScreen: Dialog result = $result');
      
      if (result == true) {
        debugPrint('LoginScreen: Người dùng chọn bật sinh trắc học');
        
        // Người dùng đồng ý bật sinh trắc học
        final authNotifier = ref.read(authProvider.notifier);
        final enabled = await authNotifier.enableBiometric();

        debugPrint('LoginScreen: enableBiometric result = $enabled');

        if (!mounted) return;

        if (enabled) {
          AppNotification.showSuccess(context, 'Đã bật đăng nhập sinh trắc học');
        } else {
          AppNotification.showError(context, 'Không thể bật sinh trắc học');
        }
      } else {
        debugPrint('LoginScreen: Người dùng chọn không bật sinh trắc học');
      }
    } catch (e) {
      debugPrint('LoginScreen: Lỗi khi hỏi bật sinh trắc học: $e');
      debugPrint('LoginScreen: Stack trace: ${StackTrace.current}');
    }
  }

  /// Điều hướng đến màn hình đăng ký
  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  /// Xử lý quên mật khẩu
  Future<void> _handleForgotPassword() async {
    // Hiển thị dialog nhập email
    final email = await showDialog<String>(
      context: context,
      builder: (context) => _ForgotPasswordDialog(),
    );

    if (email != null && email.isNotEmpty) {
      // Hiển thị loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Gửi email reset password
      final tokenId = await ref.read(authProvider.notifier).forgotPassword(
            email: email,
          );

      // Đóng loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      if (tokenId != null && tokenId.isNotEmpty) {
        // Hiển thị thông báo thành công
        AppNotification.showSuccess(context, 'Đã gửi email. Vui lòng kiểm tra email của bạn');

        // Chuyển sang màn hình chờ xác nhận
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!mounted) return;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WaitingVerificationScreen(
              email: email,
              tokenId: tokenId,
            ),
          ),
        );
      } else {
        // Hiển thị lỗi
        AppNotification.showError(context, 'Không thể gửi email reset');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng local loading state thay vì authState để tránh app navigation
    final isLoading = _isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icon hoặc Avatar (tùy mode)
                  if (_isQuickLogin) ...[
                    // Quick Login: Avatar + Greeting
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(
                        LucideIcons.user,
                        size: 50,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Xin chào,',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _savedFullName ?? _savedUsername ?? 'Người dùng',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    // Full Login: Icon + Title
                    Icon(
                      LucideIcons.logIn,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Đăng nhập',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chào mừng bạn trở lại!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                  
                  // Email field (chỉ hiển thị ở Full Login)
                  if (!_isQuickLogin) ...[
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'example@email.com',
                        prefixIcon: Icon(LucideIcons.mail),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!value.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Password field (với icon sinh trắc học ở Quick Login)
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      hintText: '••••••••',
                      prefixIcon: const Icon(LucideIcons.lock),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon sinh trắc học (chỉ hiển thị ở Quick Login nếu đã bật)
                          if (_isQuickLogin && _biometricEnabled)
                            IconButton(
                              icon: const Icon(LucideIcons.fingerprint),
                              onPressed: isLoading ? null : _handleBiometricLogin,
                              tooltip: 'Đăng nhập bằng sinh trắc học',
                            ),
                          // Icon show/hide password
                          IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Quên mật khẩu
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading ? null : _handleForgotPassword,
                      child: const Text('Quên mật khẩu?'),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Nút đăng nhập
                  ElevatedButton(
                    onPressed: isLoading ? null : (_isQuickLogin ? _handleQuickLogin : _handleLogin),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Đăng nhập'),
                  ),
                  
                  // Link "Đăng nhập tài khoản khác" (chỉ hiển thị ở Quick Login)
                  if (_isQuickLogin) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: isLoading ? null : _switchToFullLogin,
                      child: const Text('Đăng nhập tài khoản khác'),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Chuyển đến đăng ký
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chưa có tài khoản? ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: isLoading ? null : _navigateToRegister,
                        child: const Text('Đăng ký ngay'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog nhập email để quên mật khẩu
class _ForgotPasswordDialog extends StatefulWidget {
  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quên mật khẩu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Nhập email để nhận link đặt lại mật khẩu'),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'example@email.com',
              prefixIcon: Icon(LucideIcons.mail),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _emailController.text.trim());
          },
          child: const Text('Gửi'),
        ),
      ],
    );
  }
}
