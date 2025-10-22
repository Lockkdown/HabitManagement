import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../api/auth_api_service.dart';
import 'reset_password_screen.dart';

/// Màn hình chờ xác nhận từ email
/// Polling backend mỗi 3 giây để check xem user đã click link chưa
class WaitingVerificationScreen extends StatefulWidget {
  /// Email người dùng
  final String email;
  
  /// Token ID để polling
  final String tokenId;

  const WaitingVerificationScreen({
    super.key,
    required this.email,
    required this.tokenId,
  });

  @override
  State<WaitingVerificationScreen> createState() =>
      _WaitingVerificationScreenState();
}

class _WaitingVerificationScreenState extends State<WaitingVerificationScreen>
    with SingleTickerProviderStateMixin {
  /// Timer để polling
  Timer? _pollTimer;
  
  /// Animation controller
  late AnimationController _animationController;
  
  /// Số lần đã poll
  int _pollCount = 0;
  
  /// Tối đa 10 phút (200 lần x 3 giây)
  static const int maxPollCount = 200;

  @override
  void initState() {
    super.initState();
    
    // Khởi tạo animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // Bắt đầu polling sau 2 giây
    Future.delayed(const Duration(seconds: 2), () {
      _startPolling();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  /// Bắt đầu polling backend
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkStatus();
      _pollCount++;
      
      // Timeout sau 10 phút
      if (_pollCount >= maxPollCount) {
        timer.cancel();
        if (mounted) {
          _showTimeoutDialog();
        }
      }
    });
  }

  /// Kiểm tra trạng thái token
  Future<void> _checkStatus() async {
    try {
      final authApiService = AuthApiService();
      final status = await authApiService.checkTokenStatus(
        tokenId: widget.tokenId,
      );

      if (!mounted) return;

      // Nếu đã verified, chuyển sang màn hình reset password
      if (status['isVerified'] == true) {
        _pollTimer?.cancel();
        
        // Navigate sang reset password screen với token thật
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              email: widget.email,
              token: status['token'] ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      // Không làm gì nếu lỗi, tiếp tục polling
      debugPrint('Poll error: $e');
    }
  }

  /// Hiển thị dialog timeout
  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Hết thời gian chờ'),
        content: const Text(
          'Đã quá 10 phút mà chưa nhận được xác nhận. Vui lòng thử lại.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to login
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chờ xác nhận'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animation loading
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rotating circle
                    RotationTransition(
                      turns: _animationController,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                            width: 3,
                          ),
                        ),
                        child: CustomPaint(
                          painter: _ArcPainter(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.mail,
                        size: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Tiêu đề
                Text(
                  'Đang chờ xác nhận',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Mô tả
                Text(
                  'Chúng tôi đã gửi email xác nhận đến:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Email
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.email,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Hướng dẫn
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.info,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Hướng dẫn:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InstructionStep(
                        number: '1',
                        text: 'Mở email và tìm email từ Habit Management',
                      ),
                      const SizedBox(height: 8),
                      _InstructionStep(
                        number: '2',
                        text: 'Nhấn nút "Xác nhận đặt lại mật khẩu"',
                      ),
                      const SizedBox(height: 8),
                      _InstructionStep(
                        number: '3',
                        text: 'Quay lại app, màn hình sẽ tự động chuyển',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Loading indicator
                SpinKitThreeBounce(
                  color: Theme.of(context).primaryColor,
                  size: 24.0,
                ),

                const SizedBox(height: 16),

                Text(
                  'Đang chờ xác nhận từ email...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget hiển thị một bước hướng dẫn
class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.orange[700],
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
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

/// Custom painter để vẽ arc loading
class _ArcPainter extends CustomPainter {
  final Color color;

  _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const startAngle = -90.0 * 3.14159 / 180.0;
    const sweepAngle = 270.0 * 3.14159 / 180.0;

    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
