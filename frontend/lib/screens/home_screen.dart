// home_screen.dart

import 'edit_habit_screen.dart';

import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart'; // For debugPrint

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lucide_flutter/lucide_flutter.dart';

import 'package:easy_date_timeline/easy_date_timeline.dart';

import 'package:intl/intl.dart';                 // <-- THÊM IMPORT

import 'package:intl/date_symbol_data_local.dart';

import '../services/auth_provider.dart';

import '../models/habit_model.dart';

import '../api/habit_api_service.dart';

import '../utils/icon_utils.dart';

import 'create_habit_screen.dart';

// import 'edit_habit_screen.dart'; // (TODO)



class HomeScreen extends ConsumerStatefulWidget {

  const HomeScreen({super.key});



  @override

  ConsumerState<HomeScreen> createState() => _HomeScreenState();

}



class _HomeScreenState extends ConsumerState<HomeScreen> {

  int _selectedIndex = 1;

  final HabitApiService _habitApiService = HabitApiService();

  List<HabitModel> _habits = [];

  bool _isLoading = true;

  bool _isCompletingHabit = false;



  @override

  void initState() {

    super.initState();

    initializeDateFormatting('vi_VN', null).then((_) => _loadHabits());

  }



  Future<void> _loadHabits() async {

    try {

      if (!mounted) return;

      setState(() => _isLoading = true);

      final habits = await _habitApiService.getHabits();

      if (!mounted) return;

      setState(() {

        _habits = habits;

        _isLoading = false;

      });

    } catch (e, stackTrace) {

      if (!mounted) return;

      setState(() => _isLoading = false);

      debugPrint('Lỗi khi tải thói quen: $e\n$stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Lỗi khi tải thói quen: $e')),

      );

    }

  }

// --- HÀM MỚI ĐỂ XỬ LÝ TICK ---

  Future<void> _completeHabitForDate(HabitModel habit, DateTime selectedDate) async {

    if (_isCompletingHabit) return; // Chặn bấm liên tục



    final DateTime today = DateUtils.dateOnly(DateTime.now());

    final DateTime dateOnlySelected = DateUtils.dateOnly(selectedDate);



    // 1. Không cho tick ngày tương lai

    if (dateOnlySelected.isAfter(today)) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Không thể đánh dấu cho ngày tương lai')),

      );

      return;

    }



    // 2. Kiểm tra xem ngày này đã hoàn thành chưa

    bool isAlreadyDone = habit.completionDates.any((doneDate) =>

        DateUtils.isSameDay(doneDate, dateOnlySelected));



    // --- LOGIC BỎ TICK (NẾU CÓ API) ---

    // if (isAlreadyDone) {

    //   // TODO: Gọi API uncompleteHabit(habit.id, dateOnlySelected)

    //   // ... (code xử lý bỏ tick tương tự như thêm tick) ...

    //   debugPrint("Đã tick rồi, tạm thời không làm gì (hoặc gọi API bỏ tick)");

    //   return;

    // }



    // --- LOGIC THÊM TICK (NẾU CHƯA TICK) ---

     if (isAlreadyDone) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Đã hoàn thành vào ngày này')),

        );

       return; // Không làm gì nếu đã hoàn thành

     }





    // 3. Kiểm tra tần suất

    bool canComplete = false;

    String errorMessage = '';



    switch (habit.frequency.toLowerCase()) { // Chuyển sang chữ thường để so sánh an toàn

      case 'daily':

        canComplete = true; // Luôn cho phép với daily (nếu chưa tick)

        break;

      case 'weekly':

        // Chỉ cho phép tick vào đúng thứ trong tuần

        if (dateOnlySelected.weekday != habit.startDate.weekday) {

          final correctWeekday = DateFormat('EEEE', 'vi_VN').format(habit.startDate);

          errorMessage = 'Chỉ có thể hoàn thành vào thứ $correctWeekday hàng tuần';

        } else {

          // Kiểm tra xem đã tick lần nào trong tuần chứa ngày được chọn chưa

          DateTime startOfWeekSelected = DateUtils.addDaysToDate(dateOnlySelected, 1 - dateOnlySelected.weekday);

          DateTime endOfWeekSelected = DateUtils.addDaysToDate(startOfWeekSelected, 6);

          bool completedThisWeekAlready = habit.completionDates.any((d) =>

              !d.isBefore(startOfWeekSelected) && !d.isAfter(endOfWeekSelected));

          if (completedThisWeekAlready) {

            errorMessage = 'Đã hoàn thành trong tuần này';

          } else {

            canComplete = true;

          }

        }

        break;

      case 'monthly':

        // Chỉ cho phép tick vào đúng ngày trong tháng

        if (dateOnlySelected.day != habit.startDate.day) {

           errorMessage = 'Chỉ có thể hoàn thành vào ngày ${habit.startDate.day} hàng tháng';

        } else {

          // Kiểm tra xem đã tick lần nào trong tháng chứa ngày được chọn chưa

           bool completedThisMonthAlready = habit.completionDates.any((d) =>

               d.year == dateOnlySelected.year && d.month == dateOnlySelected.month);

           if (completedThisMonthAlready) {

             errorMessage = 'Đã hoàn thành trong tháng này';

           } else {

              canComplete = true;

           }

        }

        break;

      default:

         errorMessage = 'Tần suất "${habit.frequency}" không được hỗ trợ';

         break;

    }



    // 4. Hiển thị lỗi nếu không được phép tick

    if (!canComplete) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text(errorMessage)),

      );

      return;

    }



    // 5. Gọi API để đánh dấu hoàn thành

    setState(() => _isCompletingHabit = true);

    try {

      await _habitApiService.completeHabit(habit.id, completedAt: dateOnlySelected);

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

           SnackBar(content: Text('Đã hoàn thành ngày ${_formatDate(dateOnlySelected)}')),

        );

        _loadHabits(); // Tải lại để cập nhật UI lịch

      }

    } catch (e) {

       if (mounted) {

         debugPrint('Lỗi khi tick completeHabit: $e');

         ScaffoldMessenger.of(context).showSnackBar(

           SnackBar(content: Text('Lỗi khi đánh dấu hoàn thành: $e')),

         );

       }

    } finally {

       if (mounted) {

          setState(() => _isCompletingHabit = false);

       }

    }

  }



  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  // --- KẾT THÚC HÀM MỚI ---

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text('Habit Management'),

        backgroundColor: Colors.transparent, elevation: 0,

        actions: [

          IconButton(

            icon: const Icon(LucideIcons.logOut),

            onPressed: () async {

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

              if (confirm == true) await ref.read(authProvider.notifier).logout();

            },

          ),

        ],

      ),

      body: _buildBody(),

      bottomNavigationBar: _buildBottomNavigationBar(),

      floatingActionButton: _selectedIndex == 1

          ? FloatingActionButton(

              onPressed: () async {

                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateHabitScreen()));

                if (result == true) _loadHabits();

              },

              child: const Icon(LucideIcons.plus),

            )

          : null,

    );

  }



  Widget _buildBody() {

    switch (_selectedIndex) {

      case 0: return _buildTodayScreen();

      case 1: return _buildHabitsScreen();

      case 2: return _buildTasksScreen();

      case 3: return _buildStatisticsScreen();

      default: return _buildHabitsScreen();

    }

  }



  Widget _buildTodayScreen() {

    return const Center(child: Text('Hôm nay', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));

  }



  Widget _buildHabitsScreen() {

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_habits.isEmpty) {

      return Center(

        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

          Icon(LucideIcons.target, size: 80, color: Colors.grey[400]),

          const SizedBox(height: 16),

          Text('Không có thói quen nào đang hoạt động', style: TextStyle(fontSize: 18, color: Colors.grey[400], fontWeight: FontWeight.w500)),

          const SizedBox(height: 8),

          Text('Nhấn nút + để tạo thói quen mới', style: TextStyle(fontSize: 14, color: Colors.grey[500])),

        ]),

      );

    }

    return ListView.builder(

      padding: const EdgeInsets.all(16),

      itemCount: _habits.length,

      itemBuilder: (context, index) => _buildHabitCard(_habits[index]),

    );

  }



  Widget _buildHabitCard(HabitModel habit) {

    final List<DateTime> doneDates = habit.completionDates;

    final DateTime today = DateUtils.dateOnly(DateTime.now());

    DateTime startOfWeek = DateUtils.addDaysToDate(today, 1 - today.weekday);

    DateTime endOfWeek = DateUtils.addDaysToDate(startOfWeek, 6);



    return Card(

      color: Colors.grey[850],

      margin: const EdgeInsets.only(bottom: 16),

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(children: [

              Container(

                width: 50, height: 50,

                decoration: BoxDecoration(

                  color: Color(int.parse(habit.category.color.replaceFirst('#', '0xFF'))),

                  borderRadius: BorderRadius.circular(12),

                ),

                child: Icon(IconUtils.getIconData(habit.category.icon), color: Colors.white, size: 24),

              ),

              const SizedBox(width: 16),

              Expanded(

                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  Text(habit.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),

                  const SizedBox(height: 4),

                  Text(habit.category.name, style: TextStyle(fontSize: 14, color: Colors.grey[400])),

                ]),

              ),

              IconButton(

                onPressed: () => _showHabitOptions(context, habit),

                icon: Icon(Icons.more_vert, color: Colors.grey[400]),

              ),

            ]),

            const SizedBox(height: 16),

            EasyDateTimeLine(

              initialDate: today,

              locale: 'vi_VN',

              headerProps: const EasyHeaderProps(showHeader: false),

              dayProps: const EasyDayProps(

                // inactiveDayStyle KHÔNG CÓ width/height

                inactiveDayStyle: DayStyle(), // Chỉ cần DayStyle() rỗng hoặc bỏ hẳn

                dayStructure: DayStructure.dayStrDayNum,

                activeDayStyle: DayStyle(decoration: BoxDecoration(color: Colors.transparent)),

                width: 38, // width/height thuộc về EasyDayProps

                height: 52,

              ),

              onDateChange: (selectedDate) {

                debugPrint('Ngày được chọn: $selectedDate');

              },

              itemBuilder: (context, date, isSelected, isToday) {

                 // Ép kiểu lại DateTime cho chắc

                final DateTime dateDt = date;



                if (dateDt.isBefore(startOfWeek) || dateDt.isAfter(endOfWeek)) {

                  return const SizedBox.shrink();

                }



                bool isDone = doneDates.any((doneDate) =>

                    DateUtils.isSameDay(doneDate, dateDt)); // Dùng isSameDay cho an toàn



                Color bgColor = Colors.transparent;

                Color textColor = Colors.white70;



                // 1. SỬA LỖI BOOLEAN: Dùng `isToday == true`

                if (isDone) {

                  bgColor = Colors.green;

                  textColor = Colors.white;

                } else if (isToday == true) { // Explicitly check for true

                  bgColor = Colors.red;

                  textColor = Colors.white;

                }



                return Container(

                  width: 38, height: 52,

                  decoration: BoxDecoration(

                    color: bgColor,

                    borderRadius: BorderRadius.circular(bgColor == Colors.transparent ? 0 : 20),

                  ),

                  child: Column(

                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [

                      Text(

                        EasyDateFormatter.shortDayName(dateDt, 'vi_VN').toUpperCase(),

                        style: const TextStyle(color: Colors.white54, fontSize: 12),

                      ),

                      const SizedBox(height: 4),

                      Text(

                        dateDt.day.toString(),

                        style: TextStyle(

                          color: textColor,

                          // 2. SỬA LỖI BOOLEAN: Dùng `isToday == true`

                          fontWeight: (isDone || (isToday == true)) ? FontWeight.bold : FontWeight.normal,

                          fontSize: 16,

                        ),

                      ),

                    ],

                  ),

                );

              },

            ),

          ],

        ),

      ),

    );

  }



  void _showHabitOptions(BuildContext context, HabitModel habit) {

    showModalBottomSheet(

      context: context, backgroundColor: Colors.grey[900],

      builder: (ctx) => Wrap(children: [

        ListTile(

          leading: const Icon(LucideIcons.pencil, color: Colors.white70),

          title: const Text('Chỉnh sửa', style: TextStyle(color: Colors.white)),

          onTap: () async {

              Navigator.pop(ctx); // Đóng bottom sheet

              final result = await Navigator.push(

                context,

               MaterialPageRoute(

       // Bỏ dòng cũ: builder: (context) => const CreateHabitScreen(),

                builder: (context) => EditHabitScreen(habit: habit), // <-- SỬA LẠI DÒNG NÀY

    ),

  );

  if (result == true) {

    _loadHabits(); // Tải lại nếu có chỉnh sửa

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

                await _habitApiService.deleteHabit(habit.id); // TODO: Add deleteHabit in service

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xóa thói quen: ${habit.name}')));

                _loadHabits();

              } catch (e) {

                if (!mounted) return;

                debugPrint('Lỗi khi xóa thói quen: $e'); // Log error

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa thói quen: $e')));

              }

            },

          ),

        ],

      ),

    );

  }



  Widget _buildTasksScreen() {

    return const Center(child: Text('Nhiệm vụ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));

  }



  Widget _buildStatisticsScreen() {

    return const Center(child: Text('Thống kê', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));

  }



  Widget _buildBottomNavigationBar() {

    return BottomNavigationBar(

      currentIndex: _selectedIndex,

      onTap: (index) => setState(() => _selectedIndex = index),

      type: BottomNavigationBarType.fixed,

      items: const [

        BottomNavigationBarItem(icon: Icon(LucideIcons.calendar), label: 'Hôm nay'),

        BottomNavigationBarItem(icon: Icon(LucideIcons.target), label: 'Thói quen'),

        BottomNavigationBarItem(icon: Icon(Icons.check_box), label: 'Nhiệm vụ'),

        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Thống kê'),

      ],

    );

  }

}