import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class IconUtils {
  static IconData getIconData(String iconName) {
    switch (iconName) {
      case 'heart':
        return LucideIcons.heart;
      case 'book':
        return LucideIcons.book;
      case 'briefcase':
        return LucideIcons.briefcase;
      case 'dumbbell':
        return LucideIcons.dumbbell;
      case 'music':
        return LucideIcons.music;
      case 'home':
        return Icons.home; // Sử dụng Material Icons
      case 'more-horizontal':
        return Icons.more_horiz; // Sử dụng Material Icons
      case 'target':
        return LucideIcons.target;
      case 'star':
        return LucideIcons.star;
      case 'shield':
        return LucideIcons.shield;
      case 'zap':
        return LucideIcons.zap;
      case 'sun':
        return LucideIcons.sun;
      case 'moon':
        return LucideIcons.moon;
      case 'coffee':
        return LucideIcons.coffee;
      case 'car':
        return LucideIcons.car;
      case 'plane':
        return LucideIcons.plane;
      case 'gift':
        return LucideIcons.gift;
      case 'smile':
        return LucideIcons.smile;
      case 'camera':
        return LucideIcons.camera;
      case 'phone':
        return LucideIcons.phone;
      case 'mail':
        return LucideIcons.mail;
      case 'map':
        return LucideIcons.map;
      case 'compass':
        return LucideIcons.compass;
      case 'flag':
        return LucideIcons.flag;
      default:
        return LucideIcons.target;
    }
  }
}
