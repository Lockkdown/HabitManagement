import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit_model.dart';

/// Popup hiển thị lịch thói quen với biểu tượng ngọn lửa cho các ngày hoàn thành
class HabitCalendarPopup extends StatefulWidget {
  final HabitModel habit;
  final List<dynamic> completions;
  final Color habitColor;

  const HabitCalendarPopup({
    super.key,
    required this.habit,
    required this.completions,
    required this.habitColor,
  });

  @override
  State<HabitCalendarPopup> createState() => _HabitCalendarPopupState();
}

class _HabitCalendarPopupState extends State<HabitCalendarPopup> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: screenHeight * 0.85, // Sử dụng 85% chiều cao màn hình
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isDark),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCalendar(isDark),
                    _buildLegend(isDark),
                  ],
                ),
              ),
            ),
            _buildCloseButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Giảm padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.habitColor,
            widget.habitColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Giảm padding
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10), // Giảm border radius
                ),
                child: Icon(
                  _getHabitIcon(widget.habit.category.name),
                  color: Colors.white,
                  size: 20, // Giảm size icon
                ),
              ),
              const SizedBox(width: 12), // Giảm spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.habit.name,
                      style: const TextStyle(
                        fontSize: 18, // Giảm font size
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (widget.habit.description?.isNotEmpty == true)
                      Text(
                        widget.habit.description!,
                        style: TextStyle(
                          fontSize: 12, // Giảm font size
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 1, // Giảm maxLines
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Giảm spacing
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                  });
                },
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20), // Giảm size
                padding: const EdgeInsets.all(8), // Giảm padding
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32), // Giảm constraints
              ),
              Text(
                DateFormat('MMMM yyyy', 'vi_VN').format(_currentMonth),
                style: const TextStyle(
                  fontSize: 16, // Giảm font size
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                  });
                },
                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20), // Giảm size
                padding: const EdgeInsets.all(8), // Giảm padding
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32), // Giảm constraints
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Giảm padding
      child: Column(
        children: [
          // Days of week header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                .map((day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12), // Giảm spacing
          // Calendar grid
          _buildCalendarGrid(isDark),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(bool isDark) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    // Create completion map for quick lookup
    final completionMap = <String, bool>{};
    for (final completion in widget.completions) {
      final date = DateTime.parse(completion['completedAt']).toLocal();
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      completionMap[dateKey] = true;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        crossAxisSpacing: 3, // Giảm spacing
        mainAxisSpacing: 3, // Giảm spacing
      ),
      itemCount: 42, // 6 weeks * 7 days
      itemBuilder: (context, index) {
        final dayOffset = index - (firstWeekday - 1);
        
        if (dayOffset < 0 || dayOffset >= daysInMonth) {
          // Empty cells for days outside current month
          return const SizedBox.shrink();
        }
        
        final day = dayOffset + 1;
        final date = DateTime(_currentMonth.year, _currentMonth.month, day);
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final isCompleted = completionMap[dateKey] ?? false;
        final isToday = DateUtils.isSameDay(date, DateTime.now());
        final isFuture = date.isAfter(DateTime.now());
        final hasHabit = _shouldHaveHabitOnDate(date);

        return _buildDayCell(
          day: day,
          isCompleted: isCompleted,
          isToday: isToday,
          isFuture: isFuture,
          hasHabit: hasHabit,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildDayCell({
    required int day,
    required bool isCompleted,
    required bool isToday,
    required bool isFuture,
    required bool hasHabit,
    required bool isDark,
  }) {
    Color backgroundColor;
    Color textColor;
    
    if (isFuture) {
      backgroundColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
      textColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;
    } else if (isToday) {
      backgroundColor = widget.habitColor.withOpacity(0.2);
      textColor = widget.habitColor;
    } else {
      backgroundColor = isDark ? Colors.grey[850]! : Colors.grey[50]!;
      textColor = isDark ? Colors.white : Colors.black87;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(
          color: widget.habitColor,
          width: 2,
        ) : null,
      ),
      child: Stack(
        children: [
          // Day number
          Center(
            child: Text(
              day.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          // Fire icon for completed days
          if (isCompleted && hasHabit)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: widget.habitColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: widget.habitColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Giảm padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chú thích:',
            style: TextStyle(
              fontSize: 13, // Giảm font size
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6), // Giảm spacing
          Row(
            children: [
              _buildLegendItem(
                icon: Icons.local_fire_department,
                color: widget.habitColor,
                text: 'Đã hoàn thành',
                isDark: isDark,
              ),
              const SizedBox(width: 12), // Giảm spacing
              _buildLegendItem(
                icon: Icons.circle_outlined,
                color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                text: 'Chưa hoàn thành',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required IconData icon,
    required Color color,
    required String text,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Giảm padding
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.habitColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12), // Giảm padding
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Đóng',
            style: TextStyle(
              fontSize: 15, // Giảm font size
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldHaveHabitOnDate(DateTime date) {
    // Check if date is before habit start date or after end date
    if (date.isBefore(DateUtils.dateOnly(widget.habit.startDate))) return false;
    if (widget.habit.endDate != null && date.isAfter(DateUtils.dateOnly(widget.habit.endDate!))) return false;
    
    // Check frequency
    switch (widget.habit.frequency.toLowerCase()) {
      case 'daily':
      case 'hàng ngày':
        return true; // Daily habits apply to all days
        
      case 'weekly':
      case 'hàng tuần':
        final selectedDays = _getSelectedWeekdays(widget.habit);
        return selectedDays.contains(date.weekday);
        
      case 'monthly':
      case 'hàng tháng':
        final selectedDaysOfMonth = _getSelectedDaysOfMonth(widget.habit);
        return selectedDaysOfMonth.contains(date.day);
        
      default:
        return true; // Default to daily behavior
    }
  }

  // Get selected weekdays for weekly habits
  List<int> _getSelectedWeekdays(HabitModel habit) {
    // Try to get from habit schedule if available
    if (habit.habitSchedule != null && habit.habitSchedule!.daysOfWeek.isNotEmpty) {
      final daysString = habit.habitSchedule!.daysOfWeek;
      final weekdays = <int>[];
      
      // Parse days like "Mon,Wed,Fri" or "1,3,5"
      final daysList = daysString.split(',');
      for (final day in daysList) {
        final trimmedDay = day.trim();
        // Try to parse as number first (1=Monday, 7=Sunday)
        final dayNum = int.tryParse(trimmedDay);
        if (dayNum != null && dayNum >= 1 && dayNum <= 7) {
          weekdays.add(dayNum);
        } else {
          // Parse day names
          switch (trimmedDay.toLowerCase()) {
            case 'mon':
            case 'monday':
            case 'thứ hai':
              weekdays.add(1);
              break;
            case 'tue':
            case 'tuesday':
            case 'thứ ba':
              weekdays.add(2);
              break;
            case 'wed':
            case 'wednesday':
            case 'thứ tư':
              weekdays.add(3);
              break;
            case 'thu':
            case 'thursday':
            case 'thứ năm':
              weekdays.add(4);
              break;
            case 'fri':
            case 'friday':
            case 'thứ sáu':
              weekdays.add(5);
              break;
            case 'sat':
            case 'saturday':
            case 'thứ bảy':
              weekdays.add(6);
              break;
            case 'sun':
            case 'sunday':
            case 'chủ nhật':
              weekdays.add(7);
              break;
          }
        }
      }
      return weekdays;
    }
    
    // Default to all weekdays if no specific days are set
    return [1, 2, 3, 4, 5, 6, 7];
  }

  // Get selected days of month for monthly habits
  List<int> _getSelectedDaysOfMonth(HabitModel habit) {
    // Try to get from habit schedule if available
    if (habit.habitSchedule != null && habit.habitSchedule!.dayOfMonth > 0) {
      return [habit.habitSchedule!.dayOfMonth];
    }
    
    // Default to first day of month if no specific day is set
    return [1];
  }

  IconData _getHabitIcon(String category) {
    switch (category.toLowerCase()) {
      case 'health':
      case 'sức khỏe':
        return Icons.favorite;
      case 'fitness':
      case 'thể dục':
        return Icons.fitness_center;
      case 'study':
      case 'học tập':
        return Icons.school;
      case 'work':
      case 'công việc':
        return Icons.work;
      case 'personal':
      case 'cá nhân':
        return Icons.person;
      case 'social':
      case 'xã hội':
        return Icons.people;
      default:
        return Icons.track_changes;
    }
  }
}