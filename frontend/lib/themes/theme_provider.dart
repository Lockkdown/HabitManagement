import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'app_theme.dart';

/// Provider quản lý theme của ứng dụng
class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;
  
  ThemeData get lightTheme => AppTheme.lightTheme;
  ThemeData get darkTheme => AppTheme.darkTheme;

  /// Khởi tạo theme từ storage
  Future<void> initializeTheme() async {
    final savedTheme = await _storageService.getThemePreference();
    
    if (savedTheme != null) {
      switch (savedTheme) {
        case 'light':
          _themeMode = ThemeMode.light;
          _isDarkMode = false;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          _isDarkMode = true;
          break;
        case 'system':
        default:
          _themeMode = ThemeMode.system;
          _isDarkMode = false;
          break;
      }
    }
    
    notifyListeners();
  }

  /// Chuyển đổi theme
  Future<void> toggleTheme() async {
    try {
      if (_themeMode == ThemeMode.light) {
        await setThemeMode(ThemeMode.dark);
      } else {
        await setThemeMode(ThemeMode.light);
      }
      print('Theme toggled successfully to: $_themeMode'); // Debug log
    } catch (e) {
      print('Error toggling theme: $e'); // Debug log
    }
  }

  /// Đặt theme mode cụ thể
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      _themeMode = mode;
      _isDarkMode = mode == ThemeMode.dark;
      
      String themeString;
      switch (mode) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.system:
        default:
          themeString = 'system';
          break;
      }
      
      await _storageService.saveThemePreference(themeString);
      print('Theme saved to storage: $themeString'); // Debug log
      notifyListeners();
    } catch (e) {
      print('Error setting theme mode: $e'); // Debug log
    }
  }

  /// Kiểm tra xem có đang ở dark mode không (bao gồm system theme)
  bool isDarkModeActive(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}