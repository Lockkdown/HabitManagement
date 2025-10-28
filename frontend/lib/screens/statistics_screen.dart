import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/habit_model.dart';
import '../services/auth_state.dart';
import '../services/auth_provider.dart';
import '../api/statistics_api_service.dart';
import '../api/habit_api_service.dart';
import '../api/habit_completion_api_service.dart';
import '../widgets/habit_calendar_popup.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

/// Màn hình thống kê hiển thị tổng quan và dashboard thói quen
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  final StatisticsApiService _statisticsService = StatisticsApiService();
  final HabitApiService _habitService = HabitApiService();
  final HabitCompletionApiService _completionService = HabitCompletionApiService();
  
  Map<String, dynamic>? _overviewStats;
  List<dynamic>? _heatmapData;
  List<HabitModel>? _habits;
  Map<int, List<dynamic>> _habitCompletions = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }



  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.authenticated) {
        // Fetch overview statistics and heatmap data
        final overview = await _statisticsService.getOverviewStatistics();
        final heatmap = await _statisticsService.getHeatmapData();
        
        // Fetch all habits for the new dashboard
        final habits = await _habitService.getHabits();
        
        // Fetch completion data for each habit
        Map<int, List<dynamic>> completions = {};
        for (final habit in habits) {
          try {
            final habitCompletions = await _completionService.getHabitCompletions(habit.id);
            completions[habit.id] = habitCompletions;
          } catch (e) {
            // If we can't get completions for a habit, use empty list
            completions[habit.id] = [];
          }
        }
        
        setState(() {
          _overviewStats = overview;
          _heatmapData = heatmap;
          _habits = habits;
          _habitCompletions = completions;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF667EEA),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đang tải thống kê...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
                ? _buildErrorWidget()
                : RefreshIndicator(
                    onRefresh: _loadStatistics,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Giảm padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20), // Giảm từ 24 xuống 20
                          _buildOverviewSection(),
                          const SizedBox(height: 24), // Giảm từ 32 xuống 24
                          _buildHabitDashboard(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thống kê',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Theo dõi tiến trình thói quen của bạn',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildOverviewSection() {
    if (_overviewStats == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = _overviewStats!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced header with subtitle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng quan',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hiệu suất thói quen của bạn',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            // Today's date badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667EEA),
                    const Color(0xFF764BA2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                DateFormat('dd/MM').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Enhanced stats grid with fixed aspect ratio
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12, // Giảm từ 16 xuống 12
          mainAxisSpacing: 12, // Giảm từ 16 xuống 12
          childAspectRatio: 1.5, // Tăng từ 1.4 lên 1.5 để tạo thêm không gian
          children: [
            _buildEnhancedStatCard(
              title: 'Hoàn thành',
              value: '${stats['completionRate']}%',
              icon: Icons.check_circle_outline,
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
              ),
              isDark: isDark,
            ),
            _buildEnhancedStatCard(
              title: 'Streak hiện tại',
              value: '${stats['currentStreak']}',
              subtitle: 'ngày',
              icon: Icons.local_fire_department_outlined,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFFFF8F00)],
              ),
              isDark: isDark,
            ),
            _buildEnhancedStatCard(
              title: 'Streak dài nhất',
              value: '${stats['longestStreak']}',
              subtitle: 'ngày',
              icon: Icons.emoji_events_outlined,
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFF8E24AA)],
              ),
              isDark: isDark,
            ),
            _buildEnhancedStatCard(
              title: 'Tổng thói quen',
              value: '${stats['totalHabits']}',
              icon: Icons.track_changes_outlined,
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              ),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildEnhancedActivityCard(stats, isDark),
      ],
    );
  }

  Widget _buildEnhancedStatCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Gradient gradient,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isDark 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E1E1E),
                  const Color(0xFF2A2A2A),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => HapticFeedback.lightImpact(),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(12), // Giảm từ 16 xuống 12
            height: 80, // Thêm height cố định để kiểm soát kích thước
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min, // Thêm để giảm chiều cao
              children: [
                // Icon with gradient background
                Container(
                  padding: const EdgeInsets.all(6), // Giảm từ 8 xuống 6
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(10), // Giảm từ 12 xuống 10
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 16, // Giảm từ 18 xuống 16
                  ),
                ),
                const SizedBox(height: 6), // Giảm từ 8 xuống 6
                // Value and title
                Expanded( // Thay Flexible bằng Expanded
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Thêm để giảm chiều cao
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 20, // Giảm từ 22 xuống 20
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 10, // Giảm từ 11 xuống 10
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1, // Giảm từ 2 xuống 1
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 9, // Giảm từ 10 xuống 9
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedActivityCard(Map<String, dynamic> stats, bool isDark) {
    final activeDays = stats['activeDaysInMonth'];
    final totalDays = stats['daysInMonth'];
    final percentage = (activeDays / totalDays * 100).round();
    
    return Container(
      width: double.infinity,
      decoration: _buildActivityCardDecoration(isDark),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActivityCardHeader(percentage, isDark),
            const SizedBox(height: 20),
            _buildActivityCardProgress(activeDays, totalDays, isDark),
            const SizedBox(height: 16),
            _buildActivityProgressBar(activeDays, totalDays, isDark),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildActivityCardDecoration(bool isDark) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: isDark 
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1E1E), Color(0xFF2A2A2A)],
            )
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
      boxShadow: [
        BoxShadow(
          color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ],
    );
  }

  Widget _buildActivityCardHeader(int percentage, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.calendar_today_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoạt động tháng này',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Theo dõi tiến độ hàng ngày',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCardProgress(int activeDays, int totalDays, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$activeDays',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -1.5,
                height: 1,
              ),
            ),
            Text(
              'ngày hoạt động',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        Text(
          'của $totalDays ngày',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityProgressBar(int activeDays, int totalDays, bool isDark) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: activeDays / totalDays,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitDashboard() {
    // Use actual habits data instead of heatmap data
    if (_habits == null || _habits!.isEmpty) {
      return _buildEmptyState();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard thói quen',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Theo dõi tiến độ từng thói quen',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            // Habits count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667EEA),
                    const Color(0xFF764BA2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '${_habits!.length} thói quen',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Habits list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _habits!.length,
          itemBuilder: (context, index) {
            final habit = _habits![index];
            final completions = _habitCompletions[habit.id] ?? [];
            return _buildNewHabitCard(habit, completions, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildNewHabitCard(HabitModel habit, List<dynamic> completions, bool isDark) {
    // Calculate habit duration and completion data
    final now = DateTime.now();
    final startDate = habit.startDate;
    final endDate = habit.endDate;
    
    // Create completion map for quick lookup
    final completionMap = <String, bool>{};
    for (final completion in completions) {
      final date = DateTime.parse(completion['completedAt']).toLocal();
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      completionMap[dateKey] = true;
    }
    
    // Generate tile data based on habit frequency
    final tileData = _generateFrequencyBasedTiles(habit, completionMap, now);
    
    // Calculate completion percentage
    final completedCount = tileData.where((tile) => tile['isCompleted'] == true).length;
    final completionRate = tileData.isEmpty ? 0 : (completedCount / tileData.length * 100).round();
    
    // Get habit color (use a default color scheme if not available)
    final habitColor = _getHabitColor(habit.category.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isDark 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E1E1E),
                  const Color(0xFF2A2A2A),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            // Show habit calendar popup
            HapticFeedback.lightImpact();
            _showHabitCalendarPopup(habit, completions, habitColor);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon, name, description, and completion rate
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            habitColor.withOpacity(0.2),
                            habitColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: habitColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getHabitIcon(habit.category.name),
                        color: habitColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (habit.description?.isNotEmpty == true)
                            Text(
                              habit.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // Completion rate badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            habitColor,
                            habitColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: habitColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$completionRate%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Tile-based grid for habit progress
                _buildHabitTileGrid(tileData, habitColor, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Generate tiles for all days in current month
  List<Map<String, dynamic>> _generateFrequencyBasedTiles(
    HabitModel habit, 
    Map<String, bool> completionMap, 
    DateTime now
  ) {
    final tileData = <Map<String, dynamic>>[];
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // Get days in current month
    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
    
    // Always show all days in current month regardless of frequency
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(currentYear, currentMonth, day);
      if (date.isAfter(now)) {
        // For future dates, show as not completed and not applicable
        tileData.add({
          'date': date,
          'isCompleted': false,
          'hasHabit': false, // Future dates don't have habits yet
        });
        continue;
      }
      
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // Check if this date should have this habit based on frequency
      bool hasHabitOnThisDate = _shouldHaveHabitOnDate(habit, date);
      
      // Only mark as completed if the habit should exist on this date AND it's completed
      bool isCompleted = hasHabitOnThisDate && (completionMap[dateKey] ?? false);
      
      tileData.add({
        'date': date,
        'isCompleted': isCompleted,
        'hasHabit': hasHabitOnThisDate,
      });
    }
    
    return tileData;
  }
  
  // Check if habit should exist on a specific date based on frequency
  bool _shouldHaveHabitOnDate(HabitModel habit, DateTime date) {
    // Check if date is before habit start date
    if (date.isBefore(DateUtils.dateOnly(habit.startDate))) {
      return false;
    }
    
    // Check if date is after habit end date (if exists)
    if (habit.endDate != null && date.isAfter(DateUtils.dateOnly(habit.endDate!))) {
      return false;
    }
    
    switch (habit.frequency.toLowerCase()) {
      case 'daily':
      case 'hàng ngày':
        return true; // Daily habits apply to all days
        
      case 'weekly':
      case 'hàng tuần':
        final selectedDays = _getSelectedWeekdays(habit);
        return selectedDays.contains(date.weekday);
        
      case 'monthly':
      case 'hàng tháng':
        final selectedDaysOfMonth = _getSelectedDaysOfMonth(habit);
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

  Widget _buildHabitTileGrid(List<Map<String, dynamic>> tileData, Color habitColor, bool isDark) {
    if (tileData.isEmpty) return const SizedBox.shrink();
    
    // Heatmap style: nhiều cột hơn để tạo hiệu ứng dày đặc
    final totalTiles = tileData.length;
    int columns;
    
    // Tăng số cột để tạo heatmap dày đặc như GitHub
    if (totalTiles <= 14) {
      columns = 14; // 2 tuần
    } else if (totalTiles <= 21) {
      columns = 21; // 3 tuần  
    } else {
      columns = (totalTiles / 4).ceil().clamp(14, 31); // Tối đa 31 cột cho tháng
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF0F0F0F).withOpacity(0.3)
            : Colors.grey.shade50.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.03)
              : Colors.grey.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heatmap grid với ô nhỏ và dày đặc
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 1.0, // Khoảng cách rõ ràng giữa các ô vuông
              mainAxisSpacing: 1.0,
              childAspectRatio: 1.0,
            ),
            itemCount: totalTiles,
            itemBuilder: (context, index) {
              final tile = tileData[index];
              final isCompleted = tile['isCompleted'] == true;
              final hasHabit = tile['hasHabit'] == true;
              final date = tile['date'] as DateTime;
              final isToday = DateUtils.isSameDay(date, DateTime.now());
              final isFuture = date.isAfter(DateTime.now());
              
              // Heatmap color logic - màu sáng dễ nhìn hơn
              Color tileColor;
              
              if (isFuture) {
                // Future dates - màu xám nhạt
                tileColor = isDark 
                    ? Colors.grey[800]!
                    : Colors.grey[200]!;
              } else if (isCompleted) {
                // Completed - màu sáng của habit
                tileColor = habitColor.withOpacity(0.9);
              } else if (hasHabit) {
                // Has habit but not completed - màu xám trung bình
                tileColor = isDark 
                    ? Colors.grey[700]!
                    : Colors.grey[300]!;
              } else {
                // No habit - màu xám nhạt nhất
                tileColor = isDark 
                    ? Colors.grey[850]!
                    : Colors.grey[100]!;
              }
              
              return Tooltip(
                message: '${DateFormat('dd/MM').format(date)}\n${_getTooltipMessage(isCompleted, hasHabit, isFuture)}',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3, // Ô vuông rõ ràng 3x3px
                  height: 3,
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(0.5),
                    border: isToday ? Border.all(
                      color: habitColor.withOpacity(0.9),
                      width: 0.5,
                    ) : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  String _getTooltipMessage(bool isCompleted, bool hasHabit, bool isFuture) {
    if (isFuture) {
      return 'Ngày tương lai';
    } else if (isCompleted) {
      return 'Đã hoàn thành';
    } else if (hasHabit) {
      return 'Chưa hoàn thành';
    } else {
      return 'Không có thói quen';
    }
  }

  Color _getHabitColor(String category) {
    // Return colors based on habit category
    switch (category.toLowerCase()) {
      case 'health':
      case 'sức khỏe':
        return const Color(0xFF4CAF50);
      case 'fitness':
      case 'thể dục':
        return const Color(0xFFFF9800);
      case 'study':
      case 'học tập':
        return const Color(0xFF2196F3);
      case 'work':
      case 'công việc':
        return const Color(0xFF9C27B0);
      case 'personal':
      case 'cá nhân':
        return const Color(0xFFE91E63);
      case 'social':
      case 'xã hội':
        return const Color(0xFF00BCD4);
      default:
        return const Color(0xFF667EEA);
    }
  }

  IconData _getHabitIcon(String category) {
    // Return icons based on habit category
    switch (category.toLowerCase()) {
      case 'health':
      case 'sức khỏe':
        return Icons.health_and_safety;
      case 'fitness':
      case 'thể dục':
        return Icons.fitness_center;
      case 'study':
      case 'học tập':
        return Icons.book;
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

  Widget _buildMiniHeatmap(List<dynamic> data, Color color) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        itemBuilder: (context, index) {
          final day = data[index];
          final isCompleted = day['isCompleted'];
          
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: isCompleted 
                  ? color 
                  : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: const Color(0xFF2A2A2A))
            : null,
      ),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có thói quen nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo thói quen đầu tiên để xem thống kê',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Không thể tải dữ liệu thống kê',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadStatistics,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    // Map icon names to IconData
    switch (iconName.toLowerCase()) {
      case 'fitness':
        return Icons.fitness_center;
      case 'book':
        return Icons.book;
      case 'water':
        return Icons.water_drop;
      case 'sleep':
        return Icons.bedtime;
      case 'meditation':
        return Icons.self_improvement;
      case 'work':
        return Icons.work;
      case 'health':
        return Icons.health_and_safety;
      case 'food':
        return Icons.restaurant;
      default:
        return Icons.track_changes;
    }
  }

  /// Hiển thị popup lịch thói quen với biểu tượng ngọn lửa
  void _showHabitCalendarPopup(HabitModel habit, List<dynamic> completions, Color habitColor) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return HabitCalendarPopup(
          habit: habit,
          completions: completions,
          habitColor: habitColor,
        );
      },
    );
  }
}