import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/date_symbol_data_local.dart'; // Vẫn cần
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';

// Import các màn hình con
import 'habits_screen.dart'; // <<< IMPORT FILE MỚI
import 'habit_schedule_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'create_habit_screen.dart'; // Vẫn cần cho FloatingActionButton
import 'chatbot_screen.dart'; // Import ChatbotScreen

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
       body: _buildBody(),
       bottomNavigationBar: _buildBottomNavigationBar(),
       floatingActionButton: _selectedIndex == 2
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

  Widget _buildBody() {
     if (currentUserId == null) {
        return const Center(child: CircularProgressIndicator(color: Colors.pink));
     }

    switch (_selectedIndex) {
      case 0: return HabitScheduleScreen(userId: currentUserId!);
      
      // ==========================================================
      // <<< BƯỚC 2: GẮN GLOBALKEY VÀO WIDGET >>>
      // ==========================================================
      case 1: return const StatisticsScreen();
      case 2: return HabitsScreen(
                key: _habitsScreenKey, // <<< GẮN CHÌA KHÓA
                userId: currentUserId!
              );
      case 3: return const ChatbotScreen(); // Thêm ChatbotScreen
      case 4: return const SettingsScreen(); // Thêm SettingsScreen
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
    return CurvedNavigationBar(
      index: _selectedIndex,
      onTap: (index) {
        if (_selectedIndex != index) {
          setState(() => _selectedIndex = index);
        }
      },
      backgroundColor: Colors.black,
      color: Colors.grey[900]!,
      buttonBackgroundColor: Colors.pink,
      height: 65,
      animationDuration: const Duration(milliseconds: 300),
      animationCurve: Curves.easeInOut,
      items: const [
        CurvedNavigationBarItem(
          child: Icon(LucideIcons.calendar, color: Colors.white),
          label: 'Hôm nay',
          labelStyle: TextStyle(color: Colors.white, fontSize: 12),
        ),
        CurvedNavigationBarItem(
          child: Icon(Icons.bar_chart, color: Colors.white),
          label: 'Thống kê',
          labelStyle: TextStyle(color: Colors.white, fontSize: 12),
        ),
        CurvedNavigationBarItem(
          child: Icon(LucideIcons.target, color: Colors.white),
          label: 'Thói quen',
          labelStyle: TextStyle(color: Colors.white, fontSize: 12),
        ),
        CurvedNavigationBarItem(
          child: Icon(Icons.smart_toy, color: Colors.white),
          label: 'Trợ lý AI',
          labelStyle: TextStyle(color: Colors.white, fontSize: 12),
        ),
        CurvedNavigationBarItem(
          child: Icon(LucideIcons.settings, color: Colors.white),
          label: 'Cài đặt',
          labelStyle: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

} // End of _HomeScreenState