// lib/screens/habit_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../api/habit_schedule_api_service.dart';
import '../api/habit_api_service.dart';
import '../models/habit_model.dart';
import '../models/category_model.dart';
import '../utils/icon_utils.dart';
import '../widgets/touch_ripple_wrapper.dart';

class HabitScheduleScreen extends StatefulWidget {
  final String userId;
  final bool showTitle; // Control hiển thị title
  const HabitScheduleScreen({
    super.key, 
    required this.userId,
    this.showTitle = true, // Mặc định hiển thị title
  });

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
  late PageController _pageController; // Controller cho animation
  
  // Category filter
  int? _selectedCategoryId; // null = "Tất cả"
  String? _selectedCategoryName; // Tên category được chọn (for filtering)

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1000); // Start ở giữa để có thể swipe 2 chiều
    _loadHabitsForNewDate();
  }

  /// Lấy danh sách categories DUY NHẤT từ habits hiện tại
  /// FIX: Merge categories theo TÊN (không phải ID) để tránh duplicate
  List<CategoryModel> _getUniqueCategoriesFromHabits(List<HabitModel> habits) {
    final Map<String, CategoryModel> categoryMap = {}; // Key = category.name
    for (final habit in habits) {
      // Chỉ giữ lại category đầu tiên với tên này
      if (!categoryMap.containsKey(habit.category.name)) {
        categoryMap[habit.category.name] = habit.category;
      }
    }
    return categoryMap.values.toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _loadHabitsForNewDate() {
    debugPrint('===== _loadHabitsForNewDate =====');
    debugPrint('Selected Date: $_selectedDate');
    debugPrint('Is Today: ${_isSelectedDateToday()}');
    debugPrint('Before clear - _completedHabits: $_completedHabits');
    
    setState(() {
      _habitsFuture = _api.getHabitsDueToday(widget.userId, selectedDate: _selectedDate);
      // FIX: ALWAYS clear _completedHabits khi load ngày mới
      // Vì completionDates từ API sẽ handle việc hiển thị tick
      _completedHabits.clear();
      debugPrint('After clear - _completedHabits: $_completedHabits');
    });
  }

  /// Complete a habit for selected date (only if selected date is today)
  Future<void> _completeHabit(HabitModel habit) async {
    debugPrint('===== _completeHabit START =====');
    debugPrint('Habit ID: ${habit.id}, Name: ${habit.name}');
    debugPrint('Selected Date: $_selectedDate');
    debugPrint('Is Today: ${_isSelectedDateToday()}');
    debugPrint('Current _completedHabits: $_completedHabits');
    
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
      // Show loading indicator - Add to completed set for immediate UI feedback
      setState(() {
        _completedHabits.add(habit.id);
      });
      debugPrint('Added to _completedHabits: ${habit.id}');

      // Call API to complete habit with selected date
      // FIX CRITICAL: Gửi ngày cố định 12:00 UTC để tránh timezone issue
      final completionDate = DateTime.utc(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        12, 0, 0, // 12:00 UTC (giữa ngày)
      );
      debugPrint('Calling API completeHabit...');
      debugPrint('Local date: $_selectedDate');
      debugPrint('UTC date (12:00): $completionDate');
      await _habitApiService.completeHabit(
        habit.id,
        completedAt: completionDate,
      );
      debugPrint('API completeHabit SUCCESS');

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

      // FIX: Reload ngay lập tức để lấy completionDates mới từ backend
      debugPrint('Reloading habits after complete...');
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        // FIX: Không clear _completedHabits khi reload cùng ngày
        setState(() {
          _habitsFuture = _api.getHabitsDueToday(widget.userId, selectedDate: _selectedDate);
        });
        debugPrint('Habits reloaded');
      }
    } catch (e) {
      debugPrint('ERROR in _completeHabit: $e');
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
    debugPrint('===== _completeHabit END =====');
  }

  /// Check if habit is completed on selected date
  bool _isHabitCompletedToday(HabitModel habit) {
    // Use selected date instead of today's date
    final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    
    // Check trong completionDates từ API
    final isCompletedFromAPI = habit.completionDates.any((dateUtc) {
      // Convert UTC to local date
      final dateLocal = dateUtc.toLocal();
      final dateOnly = DateTime(dateLocal.year, dateLocal.month, dateLocal.day);
      final matched = dateOnly.isAtSameMomentAs(selectedDateOnly);
      return matched;
    });
    
    // FIX: Nếu đã completed từ API, return true ngay
    if (isCompletedFromAPI) {
      return true;
    }
    
    // Nếu chưa có trong API, check _completedHabits (chỉ cho immediate feedback khi vừa tick)
    // CHỈ áp dụng cho hôm nay
    if (_completedHabits.contains(habit.id) && _isSelectedDateToday()) {
      return true;
    }
    
    return false;
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
    return SafeArea(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Additional top spacing to avoid overlap with phone screen elements
            if (widget.showTitle) const SizedBox(height: 8),
            // Title Section - chỉ hiển thị nếu showTitle = true
            if (widget.showTitle)
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
                    // Animate về page giữa (1000)
                    _pageController.animateToPage(
                      1000,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
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


          // Date selector với animation ==============================================
          Container(
            color: Colors.transparent,
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (pageIndex) {
                // Tính toán week offset từ page index
                final offset = pageIndex - 1000;
                if (offset != _weekOffset) {
                  setState(() {
                    final today = DateTime.now();
                    _weekOffset = offset;
                    final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
                    final newStart = startOfThisWeek.add(Duration(days: _weekOffset * 7));
                    _selectedDate = newStart;
                  });
                  _loadHabitsForNewDate();
                }
              },
              itemBuilder: (context, pageIndex) {
                final offset = pageIndex - 1000;
                final today = DateTime.now();
                final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
                final weekStart = startOfThisWeek.add(Duration(days: offset * 7));

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Tính width động cho mỗi ngày để luôn hiển thị đủ 7 ngày
                    final spacing = 8.0;
                    final totalSpacing = spacing * 6; // 6 khoảng cách giữa 7 items
                    final itemWidth = (constraints.maxWidth - totalSpacing) / 7;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final date = weekStart.add(Duration(days: index));
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            width: itemWidth,
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
                      }),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Category selector ==============================================
          FutureBuilder<List<HabitModel>>(
            future: _habitsFuture,
            builder: (context, snapshot) {
              // Chỉ hiển thị khi có data
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              // Lấy unique categories từ habits
              final uniqueCategories = _getUniqueCategoriesFromHabits(snapshot.data!);
              
              // Nếu chỉ có 1 category, không hiển thị selector
              if (uniqueCategories.length <= 1) {
                return const SizedBox.shrink();
              }

              return Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: uniqueCategories.length + 1, // +1 cho "Tất cả"
                  itemBuilder: (context, index) {
                  if (index == 0) {
                    // "Tất cả" option
                    final isSelected = _selectedCategoryId == null;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = null;
                          _selectedCategoryName = null; // Clear filter
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.pink : Colors.grey[800],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected ? Colors.pink : Colors.grey[700]!,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.layoutGrid,
                              color: isSelected ? Colors.white : Colors.grey[400],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tất cả',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[400],
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final category = uniqueCategories[index - 1];
                  final isSelected = _selectedCategoryId == category.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = category.id;
                        _selectedCategoryName = category.name; // Lưu tên để filter
                      });
                      debugPrint('Selected category ID: ${category.id}, Name: ${category.name}');
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(int.parse(category.color.replaceFirst('#', '0xFF')))
                            : Colors.grey[800],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected
                              ? Color(int.parse(category.color.replaceFirst('#', '0xFF')))
                              : Colors.grey[700]!,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            IconUtils.getIconData(category.icon),
                            color: isSelected ? Colors.white : Colors.grey[400],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[400],
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Progress section (dynamic) ==
          FutureBuilder<List<HabitModel>>(
            future: _habitsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tiến trình',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '0/0 hoàn thành',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Filter habits theo selected category NAME (not ID)
              final allHabits = snapshot.data!;
              final habits = _selectedCategoryName == null
                  ? allHabits
                  : allHabits.where((h) => h.category.name == _selectedCategoryName).toList();

              // Calculate completed habits
              final todayLocal = DateUtils.dateOnly(DateTime.now());
              final completedCount = habits.where((habit) {
                return habit.completionDates.any((dateUtc) {
                  final dateLocal = dateUtc.toLocal();
                  return DateUtils.isSameDay(dateLocal, todayLocal);
                });
              }).length;

              final totalCount = habits.length;
              final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tiến trình',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$completedCount/$totalCount hoàn thành',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.pink,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
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

            // Filter habits theo selected category NAME (not ID)
            final allHabits = snapshot.data!;
            final habits = _selectedCategoryName == null
                ? allHabits
                : allHabits.where((h) => h.category.name == _selectedCategoryName).toList();

            if (habits.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.inbox, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text(
                      'Không có thói quen nào\ntrong danh mục này',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

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
                                    color: Color(int.parse(habit.category.color.replaceFirst('#', '0xFF'))),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    habit.category.name,
                                    style: const TextStyle(
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
      ),
    );
  }
}
