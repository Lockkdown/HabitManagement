import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/auth_api_service.dart';
import '../services/storage_service.dart';
import '../services/auth_provider.dart';
import '../services/auth_state.dart';
import '../models/user_model.dart';
import '../utils/jwt_decoder.dart';
import '../utils/app_notification.dart';
import 'admin_dashboard_screen.dart';

/// Màn hình verify OTP (đăng nhập lần sau)
class Verify2FAScreen extends ConsumerStatefulWidget {
  final String tempToken;

  const Verify2FAScreen({
    super.key,
    required this.tempToken,
  });

  @override
  ConsumerState<Verify2FAScreen> createState() => _Verify2FAScreenState();
}

class _Verify2FAScreenState extends ConsumerState<Verify2FAScreen> {
  final AuthApiService _authApiService = AuthApiService();
  final StorageService _storageService = StorageService();
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  /// Verify OTP
  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      AppNotification.showError(context, 'OTP phải có 6 chữ số');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authResponse = await _authApiService.verifyTwoFactorLogin(
        tempToken: widget.tempToken,
        otp: _otpController.text.trim(),
      );

      // Lưu tokens
      await _storageService.saveAccessToken(authResponse.accessToken);
      await _storageService.saveRefreshToken(authResponse.refreshToken);
      
      // Lưu thông tin user
      await _storageService.saveUserInfo(
        userId: authResponse.user.userId,
        username: authResponse.user.username,
        email: authResponse.user.email,
        fullName: authResponse.user.fullName,
        themePreference: authResponse.user.themePreference,
        languageCode: authResponse.user.languageCode,
      );

      // CẬP NHẬT AUTHPROVIDER STATE - Quan trọng!
      final authNotifier = ref.read(authProvider.notifier);
      final userModel = UserModel(
        userId: authResponse.user.userId,
        username: authResponse.user.username,
        email: authResponse.user.email,
        fullName: authResponse.user.fullName,
        themePreference: authResponse.user.themePreference,
        languageCode: authResponse.user.languageCode,
      );
      authNotifier.state = AuthState.authenticated(userModel);

      if (!mounted) return;

      AppNotification.showSuccess(context, 'Đăng nhập thành công');

      // Navigate: Admin → Dashboard (Admin luôn có 2FA)
      final isAdmin = JwtDecoder.isAdmin(authResponse.accessToken);
      if (isAdmin) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('🔐 Xác thực 2FA'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),

            // Icon
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),

            const SizedBox(height: 32),

            // Header
            const Text(
              'Nhập mã xác thực',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Mở Google Authenticator và nhập mã 6 số',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // OTP Input
            TextField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: 'Mã OTP (6 số)',
                hintText: '123456',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                letterSpacing: 12,
                fontWeight: FontWeight.bold,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              autofocus: true,
            ),

            const SizedBox(height: 24),

            // Verify Button
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Xác nhận',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),

            const SizedBox(height: 16),

            // Help text
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cần trợ giúp?'),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. Mở Google Authenticator'),
                        SizedBox(height: 8),
                        Text('2. Tìm tài khoản "HabitManagement"'),
                        SizedBox(height: 8),
                        Text('3. Nhập mã 6 số hiển thị'),
                        SizedBox(height: 16),
                        Text(
                          'Lưu ý: Mã thay đổi mỗi 30 giây',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Cần trợ giúp?'),
            ),
          ],
        ),
      ),
    );
  }
}
