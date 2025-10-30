import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/auth_provider.dart';
import '../services/biometric_service.dart';
import '../themes/theme_provider.dart';
import '../api/habit_api_service.dart';
import '../api/user_api_service.dart';
import '../api/statistics_api_service.dart';
import '../models/habit_model.dart';
import 'login_screen.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final HabitApiService _habitApiService = HabitApiService();
  final UserApiService _userApiService = UserApiService();
  final BiometricService _biometricService = BiometricService();
  
  // Controllers cho form chỉnh sửa thông tin
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  
  // Trạng thái các settings
  bool _notificationsEnabled = true;
  bool _remindersEnabled = true;
  bool _biometricEnabled = false;
  String _reminderTime = '08:00';
  int _currentHabitColorValue = 0xFF6366F1; // Giá trị màu mặc định
  int _weekStartDay = 1; // 0 = Chủ nhật, 1 = Thứ 2, ...
  
  // Thông tin người dùng
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSettings();
    _loadBiometricSettings();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  /// Load thông tin người dùng
  Future<void> _loadUserData() async {
    try {
      // Thử load từ API trước
      try {
        final userProfile = await _userApiService.getUserProfile();
        
        setState(() {
          _fullName = userProfile['fullName'] ?? '';
          _email = userProfile['email'] ?? '';
          _phone = userProfile['phoneNumber'] ?? '';
          _username = userProfile['username'] ?? '';
        });
        
        // Cập nhật local storage với dữ liệu từ server
        await _storageService.updateFullName(_fullName);
        await _storageService.updateEmail(_email);
        await _storageService.savePhoneNumber(_phone);
        await _storageService.updateUsername(_username);
        
        print('Loaded user data from API: fullName=$_fullName, email=$_email, phone=$_phone, username=$_username');
      } catch (apiError) {
        print('API error, loading from local storage: $apiError');
        
        // Fallback to local storage
        final fullName = await _storageService.getFullName() ?? '';
        final email = await _storageService.getEmail() ?? '';
        final phone = await _storageService.getPhoneNumber() ?? '';
        final username = await _storageService.getUsername() ?? '';
        
        setState(() {
          _fullName = fullName;
          _email = email;
          _phone = phone;
          _username = username;
        });
        
        print('Loaded user data from storage: fullName=$fullName, email=$email, phone=$phone, username=$username');
      }
      
      _fullNameController.text = _fullName;
      _emailController.text = _email;
      _phoneController.text = _phone;
      _usernameController.text = _username;
    } catch (e) {
      print('Error loading user data: $e'); // Debug log
      _showErrorSnackBar('Có lỗi xảy ra khi tải thông tin người dùng');
    }
  }

  /// Load cài đặt
  Future<void> _loadSettings() async {
    try {
      // Thử load từ API trước
      try {
        final userProfile = await _userApiService.getUserProfile();
        
        setState(() {
          _notificationsEnabled = userProfile['notificationEnabled'] ?? true;
          _remindersEnabled = userProfile['reminderEnabled'] ?? true;
          _reminderTime = userProfile['reminderTime'] ?? '08:00';
        });
        
        // Cập nhật local storage với dữ liệu từ server
        await _storageService.setNotificationEnabled(_notificationsEnabled);
        await _storageService.setReminderEnabled(_remindersEnabled);
        
        print('Loaded settings from API: notifications=$_notificationsEnabled, reminders=$_remindersEnabled, time=$_reminderTime');
      } catch (apiError) {
        print('API error, loading from local storage: $apiError');
        
        // Fallback to local storage
        final notificationsEnabled = await _storageService.isNotificationEnabled();
        final remindersEnabled = await _storageService.isReminderEnabled();
        
        setState(() {
          _notificationsEnabled = notificationsEnabled;
          _remindersEnabled = remindersEnabled;
        });
        
        print('Loaded settings from storage: notifications=$notificationsEnabled, reminders=$remindersEnabled');
      }
      
      // Load màu chủ đạo và ngày bắt đầu tuần từ storage
      final habitColor = await _storageService.getHabitColor();
      final weekStartDay = await _storageService.getWeekStartDay();
      
      setState(() {
        _currentHabitColorValue = habitColor; // Sử dụng giá trị int
        _weekStartDay = weekStartDay;
      });
      
      print('Loaded appearance settings: habitColor=$_currentHabitColorValue, weekStartDay=$_weekStartDay');
    } catch (e) {
      print('Error loading settings: $e'); // Debug log
      _showErrorSnackBar('Có lỗi xảy ra khi tải cài đặt');
    }
  }

  /// Load cài đặt sinh trắc học
  Future<void> _loadBiometricSettings() async {
    try {
      final isBiometricEnabled = await _storageService.isBiometricEnabled();
      
      setState(() {
        _biometricEnabled = isBiometricEnabled;
      });
      
      print('Loaded biometric settings: enabled=$_biometricEnabled');
    } catch (e) {
      print('Error loading biometric settings: $e');
      // Không hiển thị lỗi cho người dùng vì đây không phải lỗi nghiêm trọng
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cài đặt',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin người dùng
            _buildUserInfoSection(),
            const SizedBox(height: 24),
            
            // Cài đặt thông báo
            _buildNotificationSection(),
            const SizedBox(height: 24),
            
            // Cài đặt giao diện
            _buildAppearanceSection(),
            const SizedBox(height: 24),
            
            // Cài đặt thói quen
            _buildHabitSection(),
            const SizedBox(height: 24),
            
            // Dữ liệu và bảo mật
            _buildDataSection(),
            const SizedBox(height: 24),
            
            // Hỗ trợ
            _buildSupportSection(),
            const SizedBox(height: 24),
            
            // Đăng xuất
            _buildLogoutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin tài khoản',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.pink,
                  child: Text(
                    _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fullName.isNotEmpty ? _fullName : 'Người dùng',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _username.isNotEmpty ? '@$_username' : 'Chưa có tên người dùng',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _email.isNotEmpty ? _email : 'Chưa có email',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _phone.isNotEmpty ? _phone : 'Chưa có số điện thoại',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.pencil, color: Colors.white70),
                  onPressed: _showEditProfileDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông báo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              icon: LucideIcons.bell,
              title: 'Bật thông báo',
              subtitle: 'Nhận thông báo nhắc nhở thói quen',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                activeColor: Colors.pink,
              ),
            ),
            const Divider(color: Colors.white24),
            _buildSettingTile(
              icon: LucideIcons.clock,
              title: 'Nhắc nhở hàng ngày',
              subtitle: 'Bật/tắt nhắc nhở thói quen hàng ngày',
              trailing: Switch(
                value: _remindersEnabled,
                onChanged: _toggleReminders,
                activeColor: Colors.pink,
              ),
            ),
            const Divider(color: Colors.white24),
            _buildSettingTile(
              icon: LucideIcons.clock,
              title: 'Thời gian nhắc nhở',
              subtitle: 'Thời gian nhận thông báo hàng ngày',
              trailing: Text(
                _reminderTime,
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: () => _showTimePickerDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return provider.Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          color: Colors.grey[850],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Giao diện',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingTile(
                  icon: LucideIcons.moon,
                  title: 'Chế độ tối',
                  subtitle: 'Sử dụng giao diện tối',
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) => themeProvider.toggleTheme(),
                    activeColor: Colors.pink,
                  ),
                ),
                const Divider(color: Colors.white24),
                _buildSettingTile(
                  icon: LucideIcons.palette,
                  title: 'Màu chủ đạo',
                  subtitle: 'Tùy chỉnh màu sắc ứng dụng',
                  trailing: const Icon(LucideIcons.chevronRight, color: Colors.white70),
                  onTap: () => _showColorPickerDialog(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHabitSection() {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thói quen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              icon: LucideIcons.target,
              title: 'Mục tiêu mặc định',
              subtitle: 'Số lần thực hiện mặc định cho thói quen mới',
              trailing: const Icon(LucideIcons.chevronRight, color: Colors.white70),
              onTap: () => _showDefaultGoalDialog(),
            ),
            const Divider(color: Colors.white24),
            _buildSettingTile(
              icon: LucideIcons.calendar,
              title: 'Tuần bắt đầu',
              subtitle: 'Ngày đầu tuần trong lịch',
              trailing: Text(_getWeekDayName(_weekStartDay), style: const TextStyle(color: Colors.white70)),
              onTap: () => _showWeekStartDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection() {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dữ liệu & Bảo mật',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              icon: LucideIcons.fingerprint,
              title: 'Đăng nhập sinh trắc học',
              subtitle: 'Sử dụng vân tay hoặc khuôn mặt để đăng nhập',
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: (value) => _toggleBiometric(value),
                activeColor: const Color(0xFFE91E63),
              ),
            ),
            const Divider(color: Colors.white24),
            _buildSettingTile(
              icon: LucideIcons.download,
              title: 'Xuất dữ liệu',
              subtitle: 'Tải xuống dữ liệu thói quen của bạn',
              trailing: const Icon(LucideIcons.chevronRight, color: Colors.white70),
              onTap: () => _exportData(),
            ),
            const Divider(color: Colors.white24),
            _buildSettingTile(
              icon: LucideIcons.upload,
              title: 'Nhập dữ liệu',
              subtitle: 'Khôi phục dữ liệu từ file backup',
              trailing: const Icon(LucideIcons.chevronRight, color: Colors.white70),
              onTap: () => _importData(),
            ),
            const Divider(color: Colors.white24),
            _buildSettingTile(
              icon: LucideIcons.trash2,
              title: 'Xóa tất cả dữ liệu',
              subtitle: 'Xóa vĩnh viễn tất cả thói quen và tiến trình',
              trailing: const Icon(LucideIcons.chevronRight, color: Colors.red),
              onTap: () => _showDeleteAllDataDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hỗ trợ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              icon: LucideIcons.info,
              title: 'Trợ giúp',
              subtitle: 'Hướng dẫn sử dụng ứng dụng',
              trailing: const Icon(LucideIcons.chevronRight, color: Colors.white70),
              onTap: () => _showHelpDialog(),
            ),
            const Divider(color: Colors.white24),
            _buildSettingTile(
              icon: LucideIcons.messageCircle,
              title: 'Phản hồi',
              subtitle: 'Gửi ý kiến và báo lỗi',
              trailing: const Icon(LucideIcons.chevronRight, color: Colors.white70),
              onTap: () => _showFeedbackDialog(),
            ),
            const Divider(color: Colors.white24),
            _buildSettingTile(
              icon: LucideIcons.info,
              title: 'Về ứng dụng',
              subtitle: 'Phiên bản 1.0.0',
              trailing: const Icon(LucideIcons.chevronRight, color: Colors.white70),
              onTap: () => _showAboutDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildSettingTile(
          icon: LucideIcons.logOut,
          title: 'Đăng xuất',
          subtitle: 'Thoát khỏi tài khoản hiện tại',
          trailing: const Icon(LucideIcons.chevronRight, color: Colors.red),
          onTap: () => _showLogoutDialog(),
          titleColor: Colors.red,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white60),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// Hiển thị dialog chỉnh sửa thông tin cá nhân
  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Chỉnh sửa thông tin',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tên người dùng',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE91E63)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _fullNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE91E63)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE91E63)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE91E63)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => _saveUserInfo(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
            ),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Lưu thông tin người dùng
  Future<void> _saveUserInfo() async {
    try {
      // Validate input
      if (_usernameController.text.trim().isEmpty) {
        _showErrorSnackBar('Tên người dùng không được để trống');
        return;
      }
      
      if (_fullNameController.text.trim().isEmpty) {
        _showErrorSnackBar('Họ và tên không được để trống');
        return;
      }
      
      if (_emailController.text.trim().isEmpty) {
        _showErrorSnackBar('Email không được để trống');
        return;
      }
      
      // Validate email format
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(_emailController.text.trim())) {
        _showErrorSnackBar('Định dạng email không hợp lệ');
        return;
      }
      
      // Cập nhật thông tin qua API
      await _userApiService.updateUserProfile(
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );
      
      // Cập nhật local storage
      await _storageService.updateUsername(_usernameController.text.trim());
      await _storageService.updateFullName(_fullNameController.text.trim());
      await _storageService.updateEmail(_emailController.text.trim());
      if (_phoneController.text.trim().isNotEmpty) {
        await _storageService.savePhoneNumber(_phoneController.text.trim());
      }
      
      // Reload dữ liệu từ storage để đảm bảo đồng bộ
      await _loadUserData();
      
      Navigator.pop(context);
      _showSuccessSnackBar('Thông tin đã được cập nhật thành công!');
    } catch (e) {
      print('Error saving user info: $e'); // Debug log
      String errorMessage = 'Có lỗi xảy ra khi cập nhật thông tin';
      
      // Parse error message from API
      if (e.toString().contains('Exception:')) {
        final parts = e.toString().split('Exception:');
        if (parts.length > 1) {
          errorMessage = parts[1].trim();
        }
      }
      
      _showErrorSnackBar(errorMessage);
    }
  }

  /// Thay đổi trạng thái thông báo
  Future<void> _toggleNotifications(bool value) async {
    try {
      // Cập nhật thông báo qua API
      await _userApiService.updateUserProfile(
        notificationEnabled: value,
      );
      
      await _storageService.setNotificationEnabled(value);
      setState(() {
        _notificationsEnabled = value;
      });
      _showSuccessSnackBar(value ? 'Đã bật thông báo' : 'Đã tắt thông báo');
    } catch (e) {
      print('Error toggling notifications: $e'); // Debug log
      
      // Revert state on error
      setState(() {
        _notificationsEnabled = !value;
      });
      
      String errorMessage = 'Có lỗi xảy ra khi thay đổi cài đặt thông báo';
      
      // Parse error message from API
      if (e.toString().contains('Exception:')) {
        final parts = e.toString().split('Exception:');
        if (parts.length > 1) {
          errorMessage = parts[1].trim();
        }
      }
      
      _showErrorSnackBar(errorMessage);
    }
  }

  /// Thay đổi trạng thái nhắc nhở
  Future<void> _toggleReminders(bool value) async {
    try {
      // Cập nhật nhắc nhở qua API
      await _userApiService.updateUserProfile(
        reminderEnabled: value,
      );
      
      await _storageService.setReminderEnabled(value);
      setState(() {
        _remindersEnabled = value;
      });
      _showSuccessSnackBar(value ? 'Đã bật nhắc nhở' : 'Đã tắt nhắc nhở');
    } catch (e) {
      print('Error toggling reminders: $e'); // Debug log
      
      // Revert state on error
      setState(() {
        _remindersEnabled = !value;
      });
      
      String errorMessage = 'Có lỗi xảy ra khi thay đổi cài đặt nhắc nhở';
      
      // Parse error message from API
      if (e.toString().contains('Exception:')) {
        final parts = e.toString().split('Exception:');
        if (parts.length > 1) {
          errorMessage = parts[1].trim();
        }
      }
      
      _showErrorSnackBar(errorMessage);
    }
  }

  void _showTimePickerDialog() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final newTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      
      try {
        // Cập nhật thời gian nhắc nhở qua API
        await _userApiService.updateUserProfile(
          reminderTime: newTime,
        );
        
        // Cập nhật local storage
        await _storageService.saveReminderTime(newTime);
        
        setState(() {
          _reminderTime = newTime;
        });
        _showSuccessSnackBar('Đã cập nhật thời gian nhắc nhở');
      } catch (e) {
        print('Error updating reminder time: $e');
        
        String errorMessage = 'Có lỗi xảy ra khi cập nhật thời gian nhắc nhở';
        
        // Parse error message from API
        if (e.toString().contains('Exception:')) {
          final parts = e.toString().split('Exception:');
          if (parts.length > 1) {
            errorMessage = parts[1].trim();
          }
        }
        
        _showErrorSnackBar(errorMessage);
      }
    }
  }

  void _showColorPickerDialog() {
    final List<Color> colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFE91E63), // Pink
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF2196F3), // Blue
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
      const Color(0xFF00BCD4), // Cyan
    ];
    
    Color selectedColor = Color(_currentHabitColorValue); // Sử dụng màu hiện tại từ state
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Màu sắc mặc định', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn màu sắc mặc định cho thói quen mới:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: colors.map((color) => GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selectedColor == color
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _storageService.saveHabitColor(selectedColor.value);
                  // Cập nhật state để hiển thị màu mới
                  this.setState(() {
                    _currentHabitColorValue = selectedColor.value;
                  });
                  Navigator.pop(context);
                  _showSuccessSnackBar('Đã cập nhật màu sắc mặc định');
                } catch (e) {
                  Navigator.pop(context);
                  _showErrorSnackBar('Lỗi khi lưu màu sắc: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDefaultGoalDialog() async {
    final currentGoal = await _storageService.getDefaultHabitGoal();
    final TextEditingController goalController = TextEditingController(text: currentGoal.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Mục tiêu mặc định', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Số ngày thực hiện mặc định cho thói quen mới:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: goalController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Số ngày',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE91E63)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
              onPressed: () async {
                final goal = int.tryParse(goalController.text) ?? 7;
                if (goal > 0 && goal <= 365) {
                  try {
                    await _storageService.saveDefaultHabitGoal(goal);
                    Navigator.pop(context);
                    _showSuccessSnackBar('Đã cập nhật mục tiêu mặc định: $goal ngày');
                  } catch (e) {
                    Navigator.pop(context);
                    _showErrorSnackBar('Lỗi khi lưu mục tiêu: $e');
                  }
                } else {
                  _showErrorSnackBar('Vui lòng nhập số ngày từ 1 đến 365');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  void _showWeekStartDialog() async {
    final List<String> weekDays = ['Chủ nhật', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'];
    final currentWeekStart = await _storageService.getWeekStartDay();
    String selectedDay = weekDays[currentWeekStart];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Tuần bắt đầu', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: weekDays.map((day) => RadioListTile<String>(
              title: Text(day, style: const TextStyle(color: Colors.white)),
              value: day,
              groupValue: selectedDay,
              activeColor: const Color(0xFFE91E63),
              onChanged: (value) {
                setState(() {
                  selectedDay = value!;
                });
              },
            )).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                final dayIndex = weekDays.indexOf(selectedDay);
                try {
                  await _storageService.saveWeekStartDay(dayIndex);
                  // Cập nhật state để hiển thị ngày mới
                  this.setState(() {
                    _weekStartDay = dayIndex;
                  });
                  Navigator.pop(context);
                  _showSuccessSnackBar('Đã cập nhật ngày bắt đầu tuần: $selectedDay');
                } catch (e) {
                  Navigator.pop(context);
                  _showErrorSnackBar('Lỗi khi lưu ngày bắt đầu tuần: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _exportData() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          backgroundColor: Color(0xFF2A2A2A),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFE91E63)),
              SizedBox(width: 16),
              Text('Đang xuất dữ liệu...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );

      // Get habits data from API
      final habitApiService = HabitApiService();
      final habits = await habitApiService.getHabits();
      
      // Get statistics data from API
      final statisticsApiService = StatisticsApiService();
      Map<String, dynamic>? overviewStats;
      List<Map<String, dynamic>>? heatmapData;
      Map<String, Map<String, dynamic>> habitDetailsMap = {};
      
      try {
        // Get overview statistics
        final overviewResponse = await statisticsApiService.getOverviewStatistics();
        overviewStats = Map<String, dynamic>.from(overviewResponse);
        
        // Get heatmap data for all habits
        final heatmapResponse = await statisticsApiService.getHeatmapData(days: 365);
        heatmapData = List<Map<String, dynamic>>.from(
          heatmapResponse.map((item) => Map<String, dynamic>.from(item))
        );
        
        // Get detailed statistics for each habit
        for (final habit in habits) {
          try {
            final habitDetails = await statisticsApiService.getHabitDetails(habit.id, days: 365);
            habitDetailsMap[habit.id.toString()] = Map<String, dynamic>.from(habitDetails);
          } catch (e) {
            print('Lỗi khi lấy chi tiết thói quen ${habit.id}: $e');
            // Continue with other habits even if one fails
          }
        }
      } catch (e) {
        print('Lỗi khi lấy dữ liệu thống kê: $e');
        // Continue with export even if statistics fail
      }
      
      // Get user settings
      final userSettings = {
        'fullName': await _storageService.getFullName(),
        'email': await _storageService.getEmail(),
        'phone': await _storageService.getPhoneNumber(),
        'notificationEnabled': await _storageService.isNotificationEnabled(),
        'reminderEnabled': await _storageService.isReminderEnabled(),
        'themePreference': await _storageService.getThemePreference(),
        'defaultHabitGoal': await _storageService.getDefaultHabitGoal(),
        'weekStartDay': await _storageService.getWeekStartDay(),
        'habitColor': await _storageService.getHabitColor(),
      };

      // Create export data with statistics
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '2.0', // Updated version to include statistics
        'userSettings': userSettings,
        'habits': habits.map((habit) => {
          'id': habit.id,
          'name': habit.name,
          'description': habit.description,
          'category': {
            'id': habit.category.id,
            'name': habit.category.name,
            'color': habit.category.color,
            'icon': habit.category.icon,
          },
          'startDate': habit.startDate.toIso8601String(),
          'endDate': habit.endDate?.toIso8601String(),
          'frequency': habit.frequency,
          'hasReminder': habit.hasReminder,
          'reminderTime': habit.reminderTime?.toString(),
          'reminderType': habit.reminderType,
          'isActive': habit.isActive,
          'weeklyCompletions': habit.weeklyCompletions,
          'monthlyCompletions': habit.monthlyCompletions,
          'createdAt': habit.createdAt.toIso8601String(),
          'completionDates': habit.completionDates.map((date) => date.toIso8601String()).toList(),
        }).toList(),
        'statistics': {
          'overviewStats': overviewStats,
          'heatmapData': heatmapData,
          'habitDetails': habitDetailsMap,
        },
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'habit_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      
      // Write file
      await file.writeAsString(jsonString);
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Dữ liệu sao lưu thói quen',
        subject: 'Habit Management Backup',
      );
      
      _showSuccessSnackBar('Đã xuất dữ liệu thành công');
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showErrorSnackBar('Lỗi khi xuất dữ liệu: $e');
    }
  }

  void _importData() async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            backgroundColor: Color(0xFF2A2A2A),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFE91E63)),
                SizedBox(width: 16),
                Text('Đang nhập dữ liệu...', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );

        // Read file
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final importData = jsonDecode(jsonString);

        // Validate data structure
        if (importData['version'] == null || importData['userSettings'] == null) {
          throw Exception('File không đúng định dạng');
        }

        // Show confirmation dialog with statistics info
        Navigator.pop(context); // Close loading
        
        final hasStatistics = importData['statistics'] != null;
        final statisticsInfo = hasStatistics ? importData['statistics'] : null;
        
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text('Xác nhận nhập dữ liệu', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dữ liệu được xuất: ${DateTime.parse(importData['exportDate']).toLocal().toString().split('.')[0]}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Phiên bản: ${importData['version'] ?? 'N/A'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Số thói quen: ${importData['habits']?.length ?? 0}',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (hasStatistics) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Dữ liệu thống kê: ${statisticsInfo['habitDetails']?.length ?? 0} thói quen có chi tiết',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Việc nhập dữ liệu sẽ ghi đè lên cài đặt hiện tại và tự động cập nhật giao diện. Bạn có muốn tiếp tục?',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
                child: const Text('Nhập dữ liệu', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          // Show loading again
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              backgroundColor: Color(0xFF2A2A2A),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE91E63)),
                  SizedBox(height: 16),
                  Text('Đang khôi phục dữ liệu...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          );

          // Import user settings
          final userSettings = importData['userSettings'];
          if (userSettings['fullName'] != null) {
            await _storageService.updateFullName(userSettings['fullName']);
          }
          if (userSettings['email'] != null) {
            await _storageService.updateEmail(userSettings['email']);
          }
          if (userSettings['phone'] != null) {
            await _storageService.savePhoneNumber(userSettings['phone']);
          }
          if (userSettings['notificationEnabled'] != null) {
            await _storageService.setNotificationEnabled(userSettings['notificationEnabled']);
          }
          if (userSettings['reminderEnabled'] != null) {
            await _storageService.setReminderEnabled(userSettings['reminderEnabled']);
          }
          if (userSettings['themePreference'] != null) {
            await _storageService.saveThemePreference(userSettings['themePreference']);
          }
          if (userSettings['defaultHabitGoal'] != null) {
            await _storageService.saveDefaultHabitGoal(userSettings['defaultHabitGoal']);
          }
          if (userSettings['weekStartDay'] != null) {
            await _storageService.saveWeekStartDay(userSettings['weekStartDay']);
          }
          if (userSettings['habitColor'] != null) {
            await _storageService.saveHabitColor(userSettings['habitColor']);
          }

          // Import habits if available
          if (importData['habits'] != null && importData['habits'].isNotEmpty) {
            try {
              final habits = importData['habits'] as List;
              for (final habitData in habits) {
                try {
                  // Create habit via API using CreateHabitModel
                  final createHabitModel = CreateHabitModel(
                    name: habitData['name'] ?? '',
                    description: habitData['description'],
                    categoryId: habitData['category']?['id'] ?? 1,
                    startDate: habitData['startDate'] != null 
                      ? DateTime.parse(habitData['startDate'])
                      : DateTime.now(),
                    endDate: habitData['endDate'] != null 
                      ? DateTime.parse(habitData['endDate']) 
                      : null,
                    frequency: habitData['frequency'] ?? 'daily',
                    hasReminder: habitData['hasReminder'] ?? false,
                    reminderTime: habitData['reminderTime'] != null 
                      ? Duration(
                          hours: int.parse(habitData['reminderTime'].split(':')[0]),
                          minutes: int.parse(habitData['reminderTime'].split(':')[1])
                        )
                      : null,
                    reminderType: habitData['reminderType'],
                  );
                  
                  await _habitApiService.createHabit(createHabitModel);
                } catch (e) {
                  print('Error importing habit ${habitData['name']}: $e');
                  // Continue with other habits even if one fails
                }
              }
            } catch (e) {
              print('Error importing habits: $e');
            }
          }

          // Reload all data to update UI
          await _loadUserData();
          await _loadSettings();
          await _loadBiometricSettings();
          
          // Update UI state
          setState(() {});
          
          Navigator.pop(context); // Close loading
          _showSuccessSnackBar('Đã nhập dữ liệu thành công! Tất cả thông tin đã được cập nhật.');
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showErrorSnackBar('Lỗi khi nhập dữ liệu: $e');
    }
  }

  void _showDeleteAllDataDialog() {
    final TextEditingController confirmController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Sử dụng controller.text để lấy giá trị hiện tại
          final confirmText = confirmController.text.trim();
          final isConfirmValid = confirmText == 'XÓA TẤT CẢ';
          
          return AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 28),
                const SizedBox(width: 8),
                const Text('Xóa tất cả thói quen', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ CẢNH BÁO: Hành động này sẽ xóa vĩnh viễn tất cả dữ liệu thói quen bao gồm:',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Tất cả thói quen và lịch sử hoàn thành\n'
                  '• Dữ liệu thống kê và báo cáo\n'
                  '• Tiến trình và streak của các thói quen\n\n'
                  'Lưu ý: Cài đặt cá nhân và thông tin tài khoản sẽ được giữ nguyên.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Để xác nhận, vui lòng nhập "XÓA TẤT CẢ" vào ô bên dưới:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Nhập "XÓA TẤT CẢ" để xác nhận',
                    hintStyle: TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setDialogState(() {}); // Chỉ cần rebuild UI
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConfirmValid ? Colors.red : Colors.grey,
                ),
                onPressed: isConfirmValid 
                  ? () => _performDeleteAllData(context)
                  : null,
                child: const Text('Xóa thói quen', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _performDeleteAllData(BuildContext context) async {
    Navigator.pop(context); // Close confirmation dialog
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Color(0xFF2A2A2A),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFE91E63)),
            SizedBox(height: 16),
            Text('Đang xóa dữ liệu thói quen...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      // Delete all habits via API
      final habits = await _habitApiService.getHabits();
      for (final habit in habits) {
        try {
          await _habitApiService.deleteHabit(habit.id);
        } catch (e) {
          print('Error deleting habit ${habit.id}: $e');
        }
      }

      // Note: We don't clear all local storage anymore, only habit-related data
      // User settings, authentication, and preferences are preserved

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      _showSuccessSnackBar('Đã xóa tất cả thói quen thành công! Cài đặt cá nhân được giữ nguyên.');

    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      _showErrorSnackBar('Lỗi khi xóa dữ liệu thói quen: $e');
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Trợ giúp', style: TextStyle(color: Colors.white)),
        content: const SingleChildScrollView(
          child: Text(
            'Hướng dẫn sử dụng ứng dụng:\n\n'
            '1. Tạo thói quen mới từ màn hình chính\n'
            '2. Đánh dấu hoàn thành thói quen hàng ngày\n'
            '3. Xem tiến trình trong phần thống kê\n'
            '4. Tùy chỉnh cài đặt theo nhu cầu\n\n'
            'Liên hệ hỗ trợ: support@habitapp.com',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Phản hồi', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chia sẻ ý kiến của bạn để giúp chúng tôi cải thiện ứng dụng:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Nhập phản hồi của bạn...',
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE91E63)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('Cảm ơn phản hồi của bạn!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
            child: const Text('Gửi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Habit Management',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 Habit Management App',
      children: [
        const Text('Ứng dụng quản lý thói quen giúp bạn xây dựng và duy trì các thói quen tích cực.'),
      ],
    );
  }

  void _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
        content: const Text('Bạn có chắc muốn đăng xuất?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        // Hiển thị loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFFE91E63)),
          ),
        );

        // Thực hiện đăng xuất sử dụng AuthProvider
        await ref.read(authProvider.notifier).logout();
        
        // Đóng loading dialog
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        // Clear navigation stack và chuyển về login
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
        
      } catch (e) {
        // Đóng loading dialog nếu có lỗi
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        print('Error during logout: $e');
        _showErrorSnackBar('Có lỗi xảy ra khi đăng xuất: $e');
      }
    }
  }

  /// Bật/tắt sinh trắc học
  Future<void> _toggleBiometric(bool enabled) async {
    try {
      if (enabled) {
        // Kiểm tra thiết bị có hỗ trợ sinh trắc học không
        final isAvailable = await _biometricService.canUseBiometric();
        if (!isAvailable) {
          _showErrorSnackBar('Thiết bị không hỗ trợ sinh trắc học');
          return;
        }

        // Kiểm tra có sinh trắc học nào được đăng ký không
        final hasBiometric = await _biometricService.hasBiometricEnrolled();
        if (!hasBiometric) {
          _showErrorSnackBar('Vui lòng đăng ký sinh trắc học trong cài đặt thiết bị trước');
          return;
        }

        // Xác thực sinh trắc học trước khi bật
        final isAuthenticated = await _biometricService.authenticate();

        if (!isAuthenticated) {
          _showErrorSnackBar('Xác thực sinh trắc học thất bại');
          return;
        }

        // Bật sinh trắc học
        final authNotifier = ref.read(authProvider.notifier);
        final success = await authNotifier.enableBiometric();
        
        if (!success) {
          _showErrorSnackBar('Không thể bật sinh trắc học');
          return;
        }
        
        setState(() {
          _biometricEnabled = true;
        });
        
        _showSuccessSnackBar('Đã bật đăng nhập sinh trắc học');
      } else {
        // Tắt sinh trắc học
        final authNotifier = ref.read(authProvider.notifier);
        await authNotifier.disableBiometric();
        
        setState(() {
          _biometricEnabled = false;
        });
        
        _showSuccessSnackBar('Đã tắt đăng nhập sinh trắc học');
      }
    } catch (e) {
      print('Error toggling biometric: $e');
      _showErrorSnackBar('Có lỗi xảy ra: $e');
    }
  }

  /// Hiển thị SnackBar thành công
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Hiển thị SnackBar lỗi
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Lấy tên ngày trong tuần từ index
  String _getWeekDayName(int dayIndex) {
    final List<String> weekDays = ['Chủ nhật', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'];
    return weekDays[dayIndex];
  }
}