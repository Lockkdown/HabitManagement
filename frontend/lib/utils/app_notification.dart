import 'package:flutter/material.dart';

/// Custom notification helper với theme-aware colors
class AppNotification {
  /// Hiển thị notification thành công
  static void showSuccess(BuildContext context, String message) {
    _showNotification(
      context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: Colors.green.shade600,
      iconColor: Colors.white,
    );
  }

  /// Hiển thị notification lỗi
  static void showError(BuildContext context, String message) {
    _showNotification(
      context,
      message: message,
      icon: Icons.error,
      backgroundColor: Colors.red.shade600,
      iconColor: Colors.white,
    );
  }

  /// Hiển thị notification thông tin
  static void showInfo(BuildContext context, String message) {
    _showNotification(
      context,
      message: message,
      icon: Icons.info,
      backgroundColor: Colors.blue.shade600,
      iconColor: Colors.white,
    );
  }

  /// Hiển thị notification cảnh báo
  static void showWarning(BuildContext context, String message) {
    _showNotification(
      context,
      message: message,
      icon: Icons.warning,
      backgroundColor: Colors.orange.shade600,
      iconColor: Colors.white,
    );
  }

  /// Base method để hiển thị notification
  static void _showNotification(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _NotificationWidget(
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
      ),
    );

    overlay.insert(overlayEntry);

    // Auto remove sau 3 giây
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}

/// Widget notification
class _NotificationWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const _NotificationWidget({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    // Auto fade out sau 2.7 giây
    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Positioned(
      top: isSmallScreen ? 16 : 50,
      left: isSmallScreen ? 16 : null,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? screenWidth - 32 : 400,
                minWidth: isSmallScreen ? screenWidth - 32 : 280,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
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
