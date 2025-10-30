import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:intl/intl.dart';
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
  bool _isCompletingHabit = false; 

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

  // --- Các hàm còn lại giữ nguyên logic (bao gồm cả logic sửa lỗi múi giờ) ---

  Future<void> _completeHabitForDate(HabitModel habit, DateTime selectedDateLocal) async {
    if (_isCompletingHabit) return;

    final DateTime dateOnlySelectedLocal = DateUtils.dateOnly(selectedDateLocal);
    final DateTime todayLocal = DateUtils.dateOnly(DateTime.now());

    if (dateOnlySelectedLocal.isAfter(todayLocal)) {
      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đánh dấu cho ngày tương lai')),
      );
      return;
    }

    final DateTime completionTimeUtc = dateOnlySelectedLocal.toUtc();
    debugPrint("[UI ACTION] Request complete/uncomplete for habit ${habit.id} on date (Local): ${dateOnlySelectedLocal.toIso8601String()} -> (UTC): ${completionTimeUtc.toIso8601String()}");

    bool isAlreadyDone = habit.completionDates.any((doneDateUtc) {
        final doneDateLocal = doneDateUtc.toLocal();
        return DateUtils.isSameDay(doneDateLocal, dateOnlySelectedLocal);
    });

    setState(() => _isCompletingHabit = true);

    try {
      if (isAlreadyDone) {
        debugPrint("Calling API to UNCOMPLETE habit ${habit.id} for date (UTC): ${completionTimeUtc.toIso8601String()}");
        // await _habitApiService.uncompleteHabit(habit.id, completedAt: completionTimeUtc); 
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Chức năng bỏ tick chưa cài đặt')),
           );
        }
      } else {
        debugPrint("Calling API to COMPLETE habit ${habit.id} for date (UTC): ${completionTimeUtc.toIso8601String()}");
        await _habitApiService.completeHabit(habit.id, completedAt: completionTimeUtc);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Đã hoàn thành ngày ${_formatDate(dateOnlySelectedLocal)}')),
           );
        }
      }

      if (mounted) {
        await loadHabits(); // Gọi hàm public
      }

    } catch (e) {
      if (mounted) {
        debugPrint('Lỗi khi gọi API complete/uncomplete: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi ${isAlreadyDone ? "bỏ" : "đánh dấu"} hoàn thành: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompletingHabit = false);
      }
    }
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM', 'vi_VN').format(date.toLocal());


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
    final List<DateTime> doneDatesUtc = habit.completionDates;
    final DateTime todayLocal = DateUtils.dateOnly(DateTime.now());

    final bool isDoneToday = doneDatesUtc.any((doneDateUtc) {
        final doneDateLocal = doneDateUtc.toLocal();
        return DateUtils.isSameDay(doneDateLocal, todayLocal);
    });

    DateTime startOfWeek = todayLocal.subtract(Duration(days: todayLocal.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));


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
              // Nút check
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _isCompletingHabit ? null : () => _completeHabitForDate(habit, todayLocal),
                child: Ink(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDoneToday ? Colors.green : Colors.grey[600]!, width: 2,
                    ),
                    color: isDoneToday ? Colors.green.withOpacity(0.2) : Colors.transparent,
                  ),
                  child: Center(
                     child: _isCompletingHabit && !isDoneToday
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pink))
                        : (isDoneToday ? const Icon(Icons.check, color: Colors.green, size: 24) : null),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Icon
              Container(
                 width: 50, height: 50,
                 decoration: BoxDecoration(
                   color: Color(int.tryParse(habit.category.color?.replaceFirst('#', '0xFF') ?? '') ?? 0xFF808080),
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Icon(IconUtils.getIconData(habit.category.icon ?? ''), color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              // Tên và category
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(habit.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(habit.category.name ?? 'Không có danh mục', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                ]),
              ),
              // Nút options
              IconButton(
                onPressed: () => _showHabitOptions(context, habit),
                icon: Icon(Icons.more_vert, color: Colors.grey[400]),
              ),
            ]),
            const SizedBox(height: 16),
            // Lịch tuần
            EasyDateTimeLine(
              initialDate: todayLocal,
              locale: 'vi_VN',
              headerProps: const EasyHeaderProps(showHeader: false),
              dayProps: const EasyDayProps(
                inactiveDayStyle: DayStyle( decoration: BoxDecoration( color: Colors.transparent,) ),
                dayStructure: DayStructure.dayStrDayNum,
                activeDayStyle: DayStyle( decoration: BoxDecoration(color: Colors.transparent) ),
                width: 42, height: 55,
              ),
              itemBuilder: (context, dateLocal, isSelected, isTodayNullable) {
                  final DateTime dateDtLocal = DateUtils.dateOnly(dateLocal);
                   final bool isToday = isTodayNullable == true;

                  if (dateDtLocal.isBefore(startOfWeek) || dateDtLocal.isAfter(endOfWeek)) {
                    return const SizedBox.shrink();
                  }
                  bool isDone = doneDatesUtc.any((doneDateUtc) {
                      final doneDateLocal = doneDateUtc.toLocal();
                      return DateUtils.isSameDay(doneDateLocal, dateDtLocal);
                  });

                  Color bgColor = Colors.transparent;
                  Color dayNumColor = Colors.white;
                  Color dayStrColor = Colors.white70;
                  FontWeight dayNumWeight = FontWeight.normal;
                  BoxBorder? border;

                  if (isDone) {
                    bgColor = Colors.green.withOpacity(0.3);
                    dayNumColor = Colors.green[200]!;
                    dayStrColor = Colors.green[200]!;
                    dayNumWeight = FontWeight.bold;
                  }
                  if (isToday) {
                     if (!isDone) {
                        bgColor = Colors.redAccent.withOpacity(0.3);
                        dayNumColor = Colors.red[100]!;
                        dayStrColor = Colors.red[100]!;
                     }
                     border = Border.all(color: Colors.white70, width: 1.5);
                     dayNumWeight = FontWeight.bold;
                  }

                  return InkWell(
                     onTap: _isCompletingHabit ? null : () => _completeHabitForDate(habit, dateDtLocal),
                     borderRadius: BorderRadius.circular(10),
                     child: Container(
                       width: 42, height: 55,
                       decoration: BoxDecoration(
                         color: bgColor, borderRadius: BorderRadius.circular(10), border: border,
                       ),
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Text(
                             DateFormat('E', 'vi_VN').format(dateDtLocal).toUpperCase(),
                             style: TextStyle( color: dayStrColor, fontSize: 10, fontWeight: FontWeight.w500,),
                           ),
                           const SizedBox(height: 5),
                           Text(
                             dateDtLocal.day.toString(),
                             style: TextStyle( color: dayNumColor, fontWeight: dayNumWeight, fontSize: 14,),
                           ),
                         ],
                       ),
                     ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    } // Kết thúc _buildHabitCard

} // Kết thúc HabitsScreenState