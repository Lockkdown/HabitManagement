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
import '../widgets/touch_ripple_wrapper.dart';

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
  Set<int> _completedHabits = {}; // Track completed habits for today

  @override
  void initState() {
    super.initState();
    _loadHabitsForNewDate();
  }

  DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _loadHabits() {
    setState(() {
      _habitsFuture = _api.getHabitsDueToday(widget.userId, selectedDate: _selectedDate);
      // Don't clear completed habits - keep them for UI state
      // Only clear if we're changing to a different date
    });
  }

  void _loadHabitsForNewDate() {
    setState(() {
      _habitsFuture = _api.getHabitsDueToday(widget.userId, selectedDate: _selectedDate);
      // Clear completed habits when changing date to prevent showing wrong checkmarks
      _completedHabits.clear();
    });
  }

  /// Complete a habit for selected date (only if selected date is today)
  Future<void> _completeHabit(HabitModel habit) async {
    // Only allow completion if selected date is today
    if (!_isSelectedDateToday()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ có thể hoàn thành thói quen trong ngày hôm nay'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      setState(() {
        _completedHabits.add(habit.id);
      });

      // Call API to complete habit with selected date
      await _habitApiService.completeHabit(
        habit.id,
        completedAt: _selectedDate,
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

  /// Check if habit is completed on selected date
  bool _isHabitCompletedToday(HabitModel habit) {
    // Use selected date instead of today's date
    final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    
    return habit.completionDates.any((date) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      return dateOnly.isAtSameMomentAs(selectedDateOnly);
    }) || (_completedHabits.contains(habit.id) && _isSelectedDateToday());
  }

  /// Check if selected date is today
  bool _isSelectedDateToday() {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return selectedDateOnly.isAtSameMomentAs(todayOnly);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime startOfWeek =
            _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));

    return SafeArea(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Additional top spacing to avoid overlap with phone screen elements
            const SizedBox(height: 8),
            // Title Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'Lịch trình Thói quen',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Header với nút "Hôm nay" ============================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TouchRippleWrapper(
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                      _weekOffset = 0; // Reset về tuần hiện tại
                    });
                    _loadHabitsForNewDate();
                  },
                  borderRadius: BorderRadius.circular(20),
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
                      icon: const Icon(LucideIcons.calendar, color: Colors.white),
                      onPressed: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Colors.pink,
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF2A2A2A),
                                  onSurface: Colors.white,
                                ),
                                dialogBackgroundColor: const Color(0xFF1A1A1A),
                              ),
                              child: child!,
                            );
                          },
                        );
                        
                        if (pickedDate != null && pickedDate != _selectedDate) {
                          setState(() {
                            _selectedDate = pickedDate;
                            // Calculate week offset based on selected date
                            final today = DateTime.now();
                            final startOfCurrentWeek = today.subtract(Duration(days: today.weekday - 1));
                            final startOfSelectedWeek = pickedDate.subtract(Duration(days: pickedDate.weekday - 1));
                            _weekOffset = startOfSelectedWeek.difference(startOfCurrentWeek).inDays ~/ 7;
                          });
                          _loadHabitsForNewDate();
                        }
                      },
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TouchRippleWrapper(
              onHorizontalDragEnd: (DragEndDetails details) {
                // Swipe left = next week, Swipe right = previous week
                if (details.primaryVelocity! > 0) {
                  // Swipe right - previous week
                  setState(() {
                    final today = DateTime.now();
                    _weekOffset--;
                    final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
                    final newStart = startOfThisWeek.add(Duration(days: _weekOffset * 7));
                    _selectedDate = newStart;
                  });
                  _loadHabitsForNewDate();
                } else if (details.primaryVelocity! < 0) {
                  // Swipe left - next week
                  setState(() {
                    final today = DateTime.now();
                    _weekOffset++;
                    final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
                    final newStart = startOfThisWeek.add(Duration(days: _weekOffset * 7));
                    _selectedDate = newStart;
                  });
                  _loadHabitsForNewDate();
                }
              },
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(), // Disable ListView scrolling
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
                      _loadHabitsForNewDate();
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
      )
    );
  }
}
