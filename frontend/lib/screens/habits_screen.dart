import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

// Import models, services, utils và các màn hình liên quan
import '../models/habit_model.dart';
import '../api/habit_api_service.dart';
import '../utils/icon_utils.dart';
import 'edit_habit_screen.dart';
import 'habit_journal_screen.dart';
// CreateHabitScreen không cần import ở đây vì nút + nằm ở HomeScreen

class HabitsScreen extends ConsumerStatefulWidget {
  final String userId; 

  const HabitsScreen({
    super.key, // <<< ĐẢM BẢO CÓ super.key
    required this.userId,
  });

  @override
  // ==========================================================
  // <<< SỬA DÒNG NÀY (Bỏ dấu gạch dưới '_') >>>
  ConsumerState<HabitsScreen> createState() => HabitsScreenState();
  // ==========================================================
}

// ==========================================================
// <<< SỬA DÒNG NÀY (Bỏ dấu gạch dưới '_') >>>
class HabitsScreenState extends ConsumerState<HabitsScreen> {
// ==========================================================

  // --- State và Services chuyển từ HomeScreen sang ---
  final HabitApiService _habitApiService = HabitApiService();
  List<HabitModel> _habits = [];
  bool _isLoading = true; 

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi_VN', null).then((_) {
      loadHabits(); // Load habits khi widget khởi tạo (gọi hàm public)
    });
     debugPrint("HabitsScreen received userId: ${widget.userId}");
  }

  // ==========================================================
  // <<< SỬA HÀM NÀY (Bỏ dấu gạch dưới '_') >>>
  // --- Hàm logic (Đã đổi tên _loadHabits -> loadHabits) ---
  Future<void> loadHabits() async { 
  // ==========================================================
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final habits = await _habitApiService.getHabits();
      if (!mounted) return;
      setState(() {
        _habits = habits;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Lỗi khi tải thói quen (HabitsScreen): $e\n$stackTrace');
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi tải thói quen: $e')),
          );
       }
    }
  }



  void _showHabitOptions(BuildContext context, HabitModel habit) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.grey[900],
      isScrollControlled: true, 
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Wrap(children: [
          ListTile(
            leading: const Icon(LucideIcons.bookOpen, color: Colors.white70),
            title: const Text('Nhật ký thói quen', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push( context, MaterialPageRoute( builder: (context) => HabitJournalScreen(habit: habit),),);
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.pencil, color: Colors.white70),
            title: const Text('Chỉnh sửa', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(ctx);
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute( builder: (context) => EditHabitScreen(habit: habit),),
              );
              if (result == true && mounted) {
                loadHabits(); // Gọi hàm public
              }
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.trash2, color: Colors.redAccent),
            title: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(ctx);
              _showDeleteConfirmDialog(context, habit);
            },
          ),
        ]),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, HabitModel habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text('Bạn có chắc chắn muốn xóa thói quen "${habit.name}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(child: const Text('Hủy'), onPressed: () => Navigator.pop(ctx)),
          TextButton(
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
            onPressed: () async {
              Navigator.pop(ctx);
              if (!mounted) return;
              try {
                await _habitApiService.deleteHabit(habit.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xóa thói quen: ${habit.name}')));
                loadHabits(); // Gọi hàm public
              } catch (e) {
                if (!mounted) return;
                debugPrint('Lỗi khi xóa thói quen: $e');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa thói quen: $e')));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SafeArea(child: Center(child: CircularProgressIndicator(color: Colors.pink)));

    if (_habits.isEmpty) {
      return SafeArea(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(LucideIcons.target, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Chưa có thói quen nào', style: TextStyle(fontSize: 18, color: Colors.grey[400], fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Nhấn nút + để tạo thói quen mới', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ]),
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
         onRefresh: loadHabits, // Gọi hàm public
         color: Colors.pink,
         backgroundColor: Colors.grey[900],
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             // Tiêu đề "Thói quen"
             Padding(
               padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
               child: Text(
                 'Thói quen',
                 style: TextStyle(
                   fontSize: 28,
                   fontWeight: FontWeight.bold,
                   color: Colors.white,
                 ),
               ),
             ),
             // Danh sách thói quen
             Expanded(
               child: ListView.builder(
                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                 itemCount: _habits.length,
                 itemBuilder: (context, index) => _buildHabitCard(_habits[index]),
               ),
             ),
           ],
         ),
      ),
    );
  }

  Widget _buildHabitCard(HabitModel habit) {
    return Card(
      key: ValueKey(habit.id),
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              // Icon
              Container(
                 width: 50, height: 50,
                 decoration: BoxDecoration(
                   color: Color(int.parse(habit.category.color.replaceFirst('#', '0xFF'))),
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Icon(IconUtils.getIconData(habit.category.icon), color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              // Tên và category
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(habit.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(habit.category.name, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                ]),
              ),
              // Nút options
              IconButton(
                onPressed: () => _showHabitOptions(context, habit),
                icon: Icon(Icons.more_vert, color: Colors.grey[400]),
              ),
            ]),
          ],
        ),
      ),
    );
  } // Kết thúc _buildHabitCard
} // Kết thúc HabitsScreenState