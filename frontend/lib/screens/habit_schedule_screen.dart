// lib/screens/habit_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../api/habit_schedule_api_service.dart';
import '../api/habit_api_service.dart';
import '../models/habit_model.dart';
import '../themes/app_theme.dart';
import '../utils/icon_utils.dart';

class HabitScheduleScreen extends StatefulWidget {
  final String userId;
  const HabitScheduleScreen({super.key, required this.userId});

  @override
  State<HabitScheduleScreen> createState() => _HabitScheduleScreenState();
}

class _HabitScheduleScreenState extends State<HabitScheduleScreen> {
  final HabitScheduleApiService _api = HabitScheduleApiService();
  final HabitApiService _habitApiService = HabitApiService();
  late Future<List<HabitModel>> _habitsFuture;
  DateTime _selectedDate = DateTime.now();
  int _weekOffset = 0; // 0 = tuần hiện tại, -1 = tuần trước, +1 = tuần sau, ...
  String _selectedCategory = 'Tất cả';
  final List<String> _categories = ['Tất cả', 'Sức Khỏe', 'Học Tập', 'Công Việc', 'Khác'];
  Set<int> _completedHabits = {}; // Track completed habits for today

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _loadHabits() {
    setState(() {
      _habitsFuture = _api.getHabitsDueToday(widget.userId, selectedDate: _selectedDate);
    });
  }

  /// Complete a habit for today
  Future<void> _completeHabit(HabitModel habit) async {
    try {
      // Show loading indicator
      setState(() {
        _completedHabits.add(habit.id);
      });

      // Call API to complete habit
      await _habitApiService.completeHabit(
        habit.id,
        completedAt: DateTime.now(),
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã hoàn thành thói quen "${habit.name}"'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Refresh the habits list
      _loadHabits();
    } catch (e) {
      // Remove from completed set if error
      setState(() {
        _completedHabits.remove(habit.id);
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi hoàn thành thói quen: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Check if habit is completed today
  bool _isHabitCompletedToday(HabitModel habit) {
    final today = DateTime.now();
    final DateTime startOfWeek = today
      .add(Duration(days: _weekOffset * 7))
      .subtract(Duration(days: today.weekday - 1));

    final todayOnly = DateTime(today.year, today.month, today.day);
    
    return habit.completionDates.any((date) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      return dateOnly.isAtSameMomentAs(todayOnly);
    }) || _completedHabits.contains(habit.id);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime startOfWeek =
            _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Header với nút "Hôm nay" ============================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {},
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                      _weekOffset = 0; // Reset về tuần hiện tại
                    });
                    _loadHabits();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.pink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Hôm nay',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.list, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.calendar, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),


          // Date selector ==============================================
          Container(
            color: Colors.transparent,
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Nút tuần trước ⟨
                IconButton(
                  icon: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
                  onPressed: () {
                    setState(() {
                      final today = DateTime.now();
                      _weekOffset--;
                      final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
                      final newStart = startOfThisWeek.add(Duration(days: _weekOffset * 7));
                      _selectedDate = newStart;
                    });
                    _loadHabits();
                  },
                ),

                // Danh sách 7 ngày trong tuần
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final date = startOfWeek.add(Duration(days: index));
                      final isSelected = date.day == _selectedDate.day &&
                          date.month == _selectedDate.month &&
                          date.year == _selectedDate.year;
                      final isToday = date.day == DateTime.now().day &&
                          date.month == DateTime.now().month &&
                          date.year == DateTime.now().year;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                          });
                          _loadHabits();
                        },
                        child: Container(
                          width: 50,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.pink : Colors.grey[800],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('E', 'vi').format(date),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isToday ? Colors.white : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    date.day.toString(),
                                    style: TextStyle(
                                      color: isToday
                                          ? Colors.pink
                                          : (isSelected ? Colors.white : Colors.white70),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Nút tuần sau ⟩
                IconButton(
                  icon: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
                  onPressed: () {
                    setState(() {
                      final today = DateTime.now();
                      _weekOffset++;
                      final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
                      final newStart = startOfThisWeek.add(Duration(days: _weekOffset * 7));
                      _selectedDate = newStart;
                    });
                    _loadHabits();
                  },
                ),
              ],
            ),
          ),
          // Category filters =============================================
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.pink : Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Progress section ==
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiến trình',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  '0%',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Progress bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.0, // 0% progress
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Habits list
          Expanded(
        child: FutureBuilder<List<HabitModel>>(
          future: _habitsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.pink));
            } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Lỗi: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không có thói quen nào hôm nay.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
            }

            final habits = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(16),
                        ),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Color(int.parse(habit.category.color.replaceFirst('#', '0xFF'))),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              IconUtils.getIconData(habit.category.icon),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                            habit.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Thói quen',
                            style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Actions
                          Row(
                            children: [
                              // Completion circle
                              GestureDetector(
                                onTap: () => _completeHabit(habit),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _isHabitCompletedToday(habit) 
                                        ? Colors.green 
                                        : Colors.grey[700],
                                    shape: BoxShape.circle,
                                    border: _isHabitCompletedToday(habit)
                                        ? Border.all(color: Colors.green, width: 2)
                                        : null,
                                  ),
                                  child: _isHabitCompletedToday(habit)
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.more_vert,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                        ),
                      );
                    },
            );
          },
        ),
          ),
        ],
      ),
    );
  }
}
