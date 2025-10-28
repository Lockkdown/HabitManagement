import 'package:flutter/material.dart';
import '../utils/app_notification.dart';
import '../api/admin_api_service.dart';
import '../models/user_list_model.dart';
import '../services/storage_service.dart';

/// Màn hình Admin Dashboard - Quản lý users
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminApiService _adminApiService = AdminApiService();
  final StorageService _storageService = StorageService();
  
  List<UserListModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  /// Load danh sách users
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    try {
      final users = await _adminApiService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppNotification.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  /// Filtered users dựa trên search query
  List<UserListModel> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    
    return _users.where((user) {
      return user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  /// Toggle lock/unlock user
  Future<void> _toggleLockout(UserListModel user) async {
    try {
      final message = await _adminApiService.toggleLockout(user.id);
      
      if (mounted) {
        AppNotification.showSuccess(context, message);
        
        _loadUsers(); // Reload danh sách
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  /// Reset password
  Future<void> _resetPassword(UserListModel user) async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Reset mật khẩu cho ${user.username}?\nMật khẩu mới: User@123'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final message = await _adminApiService.resetPassword(user.id);
      
      if (mounted) {
        AppNotification.showSuccess(context, message);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  /// Delete user
  Future<void> _deleteUser(UserListModel user) async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa user ${user.username}?\nHành động này không thể hoàn tác!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final message = await _adminApiService.deleteUser(user.id);
      
      if (mounted) {
        AppNotification.showSuccess(context, message);
        
        _loadUsers(); // Reload danh sách
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  /// Assign role
  Future<void> _assignRole(UserListModel user) async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gán role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('User'),
              leading: Radio<String>(
                value: 'User',
                groupValue: user.isAdmin ? 'Admin' : 'User',
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ),
            ListTile(
              title: const Text('Admin'),
              leading: Radio<String>(
                value: 'Admin',
                groupValue: user.isAdmin ? 'Admin' : 'User',
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ),
          ],
        ),
      ),
    );

    if (newRole == null || newRole == (user.isAdmin ? 'Admin' : 'User')) return;

    try {
      final message = await _adminApiService.assignRole(user.id, newRole);
      
      if (mounted) {
        AppNotification.showSuccess(context, message);
        
        _loadUsers(); // Reload danh sách
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  /// Logout
  Future<void> _logout() async {
    await _storageService.clearAll();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('👑 Admin Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Làm mới',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm user...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Tổng users',
                    _users.length.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Admins',
                    _users.where((u) => u.isAdmin).length.toString(),
                    Icons.admin_panel_settings,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Đã khóa',
                    _users.where((u) => u.isLocked).length.toString(),
                    Icons.lock,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(child: Text('Không tìm thấy user'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return _buildUserCard(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserListModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: user.isAdmin ? Colors.orange : Colors.blue,
          child: Text(
            user.username.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Row(
              children: [
                if (user.isAdmin)
                  Chip(
                    label: const Text('Admin', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.zero,
                  ),
                if (user.isLocked)
                  const Chip(
                    label: Text('Đã khóa', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.zero,
                  ),
                if (user.twoFactorEnabled)
                  const Chip(
                    label: Text('2FA', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Họ tên: ${user.fullName}'),
                if (user.phoneNumber != null) Text('SĐT: ${user.phoneNumber}'),
                const SizedBox(height: 16),
                // Row 1: Khóa/Mở khóa + Reset MK
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleLockout(user),
                        icon: Icon(user.isLocked ? Icons.lock_open : Icons.lock),
                        label: Text(user.isLocked ? 'Mở khóa' : 'Khóa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user.isLocked ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _resetPassword(user),
                        icon: const Icon(Icons.key),
                        label: const Text('Reset MK'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: Gán role + Xóa
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _assignRole(user),
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Gán role'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteUser(user),
                        icon: const Icon(Icons.delete),
                        label: const Text('Xóa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
