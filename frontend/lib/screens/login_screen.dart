import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../services/auth_provider.dart';
import 'register_screen.dart';
import 'waiting_verification_screen.dart';

/// Màn hình đăng nhập
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  /// Controller cho các text field
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  /// Key cho form validation
  final _formKey = GlobalKey<FormState>();
  
  /// Trạng thái hiển thị/ẩn mật khẩu
  bool _obscurePassword = true;

  /// Trạng thái loading
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Xử lý đăng nhập
  Future<void> _handleLogin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Bắt đầu loading
    setState(() {
      _isLoading = true;
    });

    // Gọi API đăng nhập
    final success = await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    // Kết thúc loading
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (!mounted) return;

    if (success) {
      // Hiển thị thông báo thành công
      ElegantNotification.success(
        title: const Text('Thành công'),
        description: const Text('Đăng nhập thành công!'),
      ).show(context);
      
      // Chờ 500ms để user thấy notification trước khi navigate
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Chuyển hướng rõ ràng đến HomeScreen và clear navigation stack
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    } else {
      // Hiển thị thông báo lỗi
      final errorMessage = ref.read(authProvider).errorMessage ?? 
          'Đăng nhập thất bại';
      ElegantNotification.error(
        title: const Text('Lỗi'),
        description: Text(errorMessage),
      ).show(context);
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
        ElegantNotification.success(
          title: const Text('Đã gửi email'),
          description: const Text('Vui lòng kiểm tra email của bạn'),
        ).show(context);

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
        ElegantNotification.error(
          title: const Text('Lỗi'),
          description: const Text('Không thể gửi email reset'),
        ).show(context);
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
                  // Logo/Icon
                  Icon(
                    LucideIcons.logIn,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tiêu đề
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
                  
                  const SizedBox(height: 40),
                  
                  // Email field
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
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      hintText: '••••••••',
                      prefixIcon: const Icon(LucideIcons.lock),
                      suffixIcon: IconButton(
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
                    onPressed: isLoading ? null : _handleLogin,
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
