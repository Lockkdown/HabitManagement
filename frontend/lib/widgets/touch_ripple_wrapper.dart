import 'package:flutter/material.dart';
import 'package:flutter_touch_ripple/flutter_touch_ripple.dart';

/// TouchRipple wrapper với hiệu ứng nhẹ nhàng
class TouchRippleWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final Color? rippleColor;
  final Duration? animationDuration;
  final Function(DragEndDetails)? onHorizontalDragEnd;

  const TouchRippleWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.rippleColor,
    this.animationDuration,
    this.onHorizontalDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return TouchRippleStyle(
      rippleColor: rippleColor ?? (isDark 
        ? Colors.white.withValues(alpha: 0.08)  // Sử dụng withValues thay vì withOpacity
        : Colors.black.withValues(alpha: 0.04)), // Sử dụng withValues thay vì withOpacity
      hoverColor: isDark 
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.02),
      focusColor: isDark 
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.03),
      rippleBorderRadius: borderRadius ?? BorderRadius.circular(8),
      child: TouchRipple(
        onTap: onTap,
        onLongTapStart: onLongPress,
        onDragHorizontalEnd: onHorizontalDragEnd != null ? () => onHorizontalDragEnd!(DragEndDetails()) : null, // Sử dụng onDragHorizontalEnd
        child: child,
      ),
    );
  }
}

/// TouchRipple nhẹ cho các element nhỏ
class LightTouchRipple extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const LightTouchRipple({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return TouchRippleStyle(
      rippleColor: isDark 
        ? Colors.white.withValues(alpha: 0.05)  // Rất nhẹ
        : Colors.black.withValues(alpha: 0.03), // Rất nhẹ
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      rippleBorderRadius: borderRadius ?? BorderRadius.circular(4),
      child: TouchRipple(
        onTap: onTap,
        child: child,
      ),
    );
  }
}

/// Style tùy chỉnh cho TouchRipple theo app theme
class AppTouchRippleStyle {
  static Widget primary({
    required Widget child,
    VoidCallback? onTap,
    BorderRadius? borderRadius,
  }) {
    return TouchRippleStyle(
      rippleColor: Colors.blue.withValues(alpha: 0.1),
      hoverColor: Colors.blue.withValues(alpha: 0.05),
      focusColor: Colors.blue.withValues(alpha: 0.08),
      rippleBorderRadius: borderRadius ?? BorderRadius.circular(12),
      child: TouchRipple(
        onTap: onTap,
        child: child,
      ),
    );
  }

  static Widget success({
    required Widget child,
    VoidCallback? onTap,
    BorderRadius? borderRadius,
  }) {
    return TouchRippleStyle(
      rippleColor: Colors.green.withValues(alpha: 0.1),
      hoverColor: Colors.green.withValues(alpha: 0.05),
      focusColor: Colors.green.withValues(alpha: 0.08),
      rippleBorderRadius: borderRadius ?? BorderRadius.circular(12),
      child: TouchRipple(
        onTap: onTap,
        child: child,
      ),
    );
  }

  static Widget subtle({
    required Widget child,
    VoidCallback? onTap,
    BorderRadius? borderRadius,
  }) {
    return TouchRippleStyle(
      rippleColor: Colors.grey.withValues(alpha: 0.06),
      hoverColor: Colors.grey.withValues(alpha: 0.03),
      focusColor: Colors.grey.withValues(alpha: 0.04),
      rippleBorderRadius: borderRadius ?? BorderRadius.circular(8),
      child: TouchRipple(
        onTap: onTap,
        child: child,
      ),
    );
  }
}