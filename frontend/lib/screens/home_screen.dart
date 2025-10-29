import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/date_symbol_data_local.dart'; // Vẫn cần

// Import các màn hình con
import 'habits_screen.dart'; // <<< IMPORT FILE MỚI
import 'habit_schedule_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'create_habit_screen.dart'; // Vẫn cần cho FloatingActionButton

// Import services và providers
import '../services/storage_service.dart';
import '../services/auth_provider.dart';
// KHÔNG CẦN import '../services/providers.dart' nữa

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 1; 
  String? currentUserId; 

  // ==========================================================
  // <<< BƯỚC 1: TẠO GLOBALKEY >>>
  // ==========================================================
  // Khởi tạo GlobalKey trỏ đến HabitsScreenState (class public mới)
  final GlobalKey<HabitsScreenState> _habitsScreenKey = GlobalKey<HabitsScreenState>();


  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi_VN', null).then((_) async {
       await _loadCurrentUserId();
        if (mounted) {
           setState(() {});
        }
    });
  }

  Future<void> _loadCurrentUserId() async {
    final storageService = StorageService();
    try {
       currentUserId = await storageService.getUserId();
       debugPrint('HomeScreen loaded userId: $currentUserId');
       if (currentUserId == null && mounted) {
          debugPrint('UserId is null, navigating to LoginScreen.');
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
          );
       }
    } catch (e) {
       debugPrint('Error loading userId: $e');
       if (mounted) {
           Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
           );
       }
    }
     if (mounted) setState(() {});
  }

  // --- TOÀN BỘ LOGIC HABIT ĐÃ BỊ XÓA KHỎI ĐÂY ---

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
       return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.pink)),
       );
    }

    return Scaffold(
       appBar: AppBar( 
         leading: IconButton(
           icon: const Icon(LucideIcons.settings),
           onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()),);
           },
         ),
         title: Text(_getAppBarTitle(_selectedIndex)),
         backgroundColor: Colors.transparent, elevation: 0,
         actions: [
           IconButton(
             icon: const Icon(LucideIcons.logOut),
             onPressed: () async {
                _handleLogout();
             },
           ),
         ],
       ),
       body: _buildBody(),
       bottomNavigationBar: _buildBottomNavigationBar(),
       floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                   context,
                   MaterialPageRoute(builder: (context) => const CreateHabitScreen()),
                );
                 if (result == true) {
                    print("Create Habit success! Triggering reload via GlobalKey.");
                    
                    // ==========================================================
                    // <<< BƯỚC 3: SỬ DỤNG GLOBALKEY ĐỂ GỌI HÀM >>>
                    // ==========================================================
                    // Dùng chìa khóa để gọi hàm loadHabits() (public) bên trong HabitsScreenState
                    _habitsScreenKey.currentState?.loadHabits();
                    // ==========================================================
                 }
              },
              backgroundColor: Colors.pink,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

   String _getAppBarTitle(int index) {
     switch (index) {
       case 0: return 'Lịch trình hôm nay';
       case 1: return 'Thói quen';
       case 2: return 'Thống kê';
       default: return 'Thói quen';
     }
   }

   Future<void> _handleLogout() async {
     final confirm = await showDialog<bool>(
       context: context,
       builder: (context) => AlertDialog(
         backgroundColor: Colors.grey[850],
         title: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
         content: const Text('Bạn có chắc muốn đăng xuất?', style: TextStyle(color: Colors.white70)),
         actions: [
           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
           ElevatedButton(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
             onPressed: () => Navigator.pop(context, true), child: const Text('Đăng xuất'),
           ),
         ],
       ),
     );
     if (confirm == true) {
       await ref.read(authProvider.notifier).logout();
       if (mounted) {
         Navigator.of(context).pushAndRemoveUntil(
           MaterialPageRoute(builder: (context) => const LoginScreen()),
           (route) => false,
         );
       }
     }
   }

  Widget _buildBody() {
     if (currentUserId == null) {
        return const Center(child: CircularProgressIndicator(color: Colors.pink));
     }

    switch (_selectedIndex) {
      case 0: return HabitScheduleScreen(userId: currentUserId!);
      
      // ==========================================================
      // <<< BƯỚC 2: GẮN GLOBALKEY VÀO WIDGET >>>
      // ==========================================================
      case 1: return HabitsScreen(
                key: _habitsScreenKey, // <<< GẮN CHÌA KHÓA
                userId: currentUserId!
              );
      case 2: return const StatisticsScreen();
      default: return HabitsScreen(
                 key: _habitsScreenKey, // <<< GẮN CHÌA KHÓA
                 userId: currentUserId!
               );
      // ==========================================================
    }
  }

  // --- CÁC HÀM CŨ ĐÃ BỊ XÓA ---
  // _buildHabitsScreen()
  // _buildHabitCard()
  // _showHabitOptions()
  // _showDeleteConfirmDialog()
  // _completeHabitForDate()
  // _formatDate()

   Widget _buildStatisticsScreen() {
    return const StatisticsScreen();
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        if (_selectedIndex != index) {
          setState(() => _selectedIndex = index);
        }
      },
      backgroundColor: Colors.grey[900],
      selectedItemColor: Colors.pink,
      unselectedItemColor: Colors.grey[600],
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(LucideIcons.calendar), label: 'Hôm nay'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.target), label: 'Thói quen'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Thống kê'),
      ],
    );
  }

} // End of _HomeScreenState