import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/auth_api_service.dart';
import '../models/two_factor_login_response_model.dart';
import '../services/storage_service.dart';
import '../utils/jwt_decoder.dart';
import '../utils/app_notification.dart';
import 'admin_dashboard_screen.dart';

/// Màn hình setup 2FA lần đầu (scan QR code + verify OTP)
class Setup2FAScreen extends StatefulWidget {
  final TwoFactorLoginResponseModel twoFactorResponse;

  const Setup2FAScreen({
    super.key,
    required this.twoFactorResponse,
  });

  @override
  State<Setup2FAScreen> createState() => _Setup2FAScreenState();
}

class _Setup2FAScreenState extends State<Setup2FAScreen> {
  final AuthApiService _authApiService = AuthApiService();
  final StorageService _storageService = StorageService();
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _isQrCodeExpanded = true;

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
      final authResponse = await _authApiService.verifyTwoFactorSetup(
        tempToken: widget.twoFactorResponse.tempToken!,
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

      if (!mounted) return;

      AppNotification.showSuccess(context, 'Setup 2FA hoàn tất');

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

  /// Copy Secret Key
  void _copySecretKey() {
    if (widget.twoFactorResponse.secretKey != null) {
      Clipboard.setData(ClipboardData(text: widget.twoFactorResponse.secretKey!));
      AppNotification.showInfo(context, 'Secret Key đã được sao chép');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('🔐 Setup 2FA'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'Quét QR Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sử dụng Google Authenticator để quét mã QR',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // QR Code Image
            if (widget.twoFactorResponse.qrCode != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isQrCodeExpanded = !_isQrCodeExpanded;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _isQrCodeExpanded ? 250 : 150,
                          height: _isQrCodeExpanded ? 250 : 150,
                          child: Image.memory(
                            base64Decode(widget.twoFactorResponse.qrCode!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nhấn để ${_isQrCodeExpanded ? 'thu nhỏ' : 'phóng to'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Secret Key (backup)
            if (widget.twoFactorResponse.secretKey != null)
              Card(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Secret Key (sao lưu)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.twoFactorResponse.secretKey!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: _copySecretKey,
                            tooltip: 'Sao chép',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hướng dẫn:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStep('1', 'Tải Google Authenticator (nếu chưa có)'),
                    _buildStep('2', 'Mở app → Nhấn dấu + (Add)'),
                    _buildStep('3', 'Chọn "Scan a QR code"'),
                    _buildStep('4', 'Quét QR Code ở trên'),
                    _buildStep('5', 'Nhập mã 6 số vào ô bên dưới'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

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
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }
}
