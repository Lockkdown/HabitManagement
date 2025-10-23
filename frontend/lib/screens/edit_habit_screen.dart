// lib/screens/edit_habit_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../models/habit_model.dart'; // Import HabitModel
import '../models/category_model.dart';
import '../api/habit_api_service.dart';
import 'select_category_screen.dart';

// 1. Đổi tên class
class EditHabitScreen extends ConsumerStatefulWidget {
  // 2. Thêm tham số habit
  final HabitModel habit;

  const EditHabitScreen({super.key, required this.habit}); // Sửa constructor

  @override
  ConsumerState<EditHabitScreen> createState() => _EditHabitScreenState();
}

// 1. Đổi tên class State
class _EditHabitScreenState extends ConsumerState<EditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  CategoryModel? _selectedCategory;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _hasEndDate = false;
  String _frequency = 'daily';
  bool _hasReminder = false;
  TimeOfDay? _reminderTime;
  String _reminderType = 'notification';

  final HabitApiService _habitApiService = HabitApiService();
  bool _isLoading = false;

  // 3. Thêm initState để điền dữ liệu cũ
  @override
  void initState() {
    super.initState();
    // Lấy dữ liệu từ widget.habit và điền vào form
    _nameController.text = widget.habit.name;
    _descriptionController.text = widget.habit.description ?? '';
    _selectedCategory = widget.habit.category;
    _startDate = widget.habit.startDate;
    _endDate = widget.habit.endDate;
    _hasEndDate = widget.habit.endDate != null;
    _frequency = widget.habit.frequency;
    _hasReminder = widget.habit.hasReminder;
    if (widget.habit.reminderTime != null) {
      // Chuyển Duration thành TimeOfDay
      final totalMinutes = widget.habit.reminderTime!.inMinutes;
      final hour = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    }
    _reminderType = widget.habit.reminderType ?? 'notification';
  }


  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 5. Đổi tiêu đề
        title: const Text('Chỉnh sửa thói quen'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            // 4. Gọi hàm _updateHabit
            onPressed: _isLoading ? null : _updateHabit,
            child: const Text(
              // 5. Đổi chữ nút
              'Lưu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- CÁC PHẦN FORM GIỮ NGUYÊN NHƯ CREATE ---
            _buildSectionHeader('Thông tin chung', isRequired: true),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên thói quen', hintText: 'Nhập tên thói quen'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Vui lòng nhập tên thói quen';
                return null;
              },
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _selectCategory,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(LucideIcons.tag, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedCategory?.name ?? 'Chọn danh mục',
                      style: TextStyle(color: _selectedCategory != null ? Colors.white : Colors.grey[600]),
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, color: Colors.grey[600]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _selectStartDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(LucideIcons.calendar, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Ngày bắt đầu: ${_formatDate(_startDate)}', style: const TextStyle(color: Colors.white))),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text('Ngày kết thúc', style: TextStyle(fontSize: 16, color: Colors.grey[300]))),
              Switch(value: _hasEndDate, onChanged: (value) => setState(() { _hasEndDate = value; if (!value) _endDate = null; })),
            ]),
            if (_hasEndDate) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _selectEndDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(LucideIcons.calendar, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Ngày kết thúc: ${_endDate != null ? _formatDate(_endDate!) : "Chọn ngày"}', style: const TextStyle(color: Colors.white))),
                  ]),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildSectionHeader('Tần suất'),
            const SizedBox(height: 16),
            _buildFrequencySelector(),
            const SizedBox(height: 24),
            _buildSectionHeader('Nhắc nhở', isOptional: true),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text('Thêm nhắc nhở', style: TextStyle(fontSize: 16, color: Colors.grey[300]))),
              Switch(value: _hasReminder, onChanged: (value) => setState(() => _hasReminder = value)),
            ]),
            if (_hasReminder) ...[
              const SizedBox(height: 16),
              _buildReminderSettings(),
            ],
            const SizedBox(height: 24),
            _buildSectionHeader('Mô tả', isOptional: true),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Mô tả', hintText: 'Nhập mô tả cho thói quen (tùy chọn)'),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
             // --- KẾT THÚC CÁC PHẦN FORM GIỮ NGUYÊN ---
          ],
        ),
      ),
    );
  }

  // --- CÁC HÀM BUILD WIDGET PHỤ GIỮ NGUYÊN ---
  Widget _buildSectionHeader(String title, {bool isRequired = false, bool isOptional = false}) {
    // Giữ nguyên code
     return Row(children: [
       Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
       if (isRequired) ...[
         const SizedBox(width: 4),
         Container(
           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
           decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
           child: const Text('Bắt buộc', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
         ),
       ],
       if (isOptional) ...[
         const SizedBox(width: 4),
         Text('(Tùy chọn)', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
       ],
     ]);
  }
  Widget _buildFrequencySelector() {
    // Giữ nguyên code
    return Column(children: [
      _buildFrequencyOption('daily', 'Hàng ngày', 'Mỗi ngày'),
      _buildFrequencyOption('weekly', 'Hàng tuần', 'Mỗi tuần'),
      _buildFrequencyOption('monthly', 'Hàng tháng', 'Mỗi tháng'),
    ]);
  }
  Widget _buildFrequencyOption(String value, String title, String description) {
    // Giữ nguyên code
     final isSelected = _frequency == value;
     return GestureDetector(
       onTap: () => setState(() => _frequency = value),
       child: Container(
         margin: const EdgeInsets.only(bottom: 8),
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Theme.of(context).cardColor,
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.3)),
         ),
         child: Row(children: [
           Radio<String>(value: value, groupValue: _frequency, onChanged: (v) => setState(() => _frequency = v!)),
           const SizedBox(width: 12),
           Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
             Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
             Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
           ])),
         ]),
       ),
     );
  }
   Widget _buildReminderSettings() {
    // Giữ nguyên code
     return Column(children: [
       GestureDetector(
         onTap: _selectReminderTime,
         child: Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
             color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12),
             border: Border.all(color: Colors.grey.withOpacity(0.3)),
           ),
           child: Row(children: [
             Icon(LucideIcons.clock, color: Colors.grey[600]), const SizedBox(width: 12),
             Expanded(child: Text('Thời gian: ${_reminderTime != null ? _formatTime(_reminderTime!) : "Chọn giờ"}', style: const TextStyle(color: Colors.white))),
           ]),
         ),
       ),
       const SizedBox(height: 16),
       Row(children: [
         Expanded(child: _buildReminderTypeOption('notification', 'Thông báo')),
         const SizedBox(width: 16),
         Expanded(child: _buildReminderTypeOption('sound', 'Âm thanh')),
       ]),
     ]);
   }
   Widget _buildReminderTypeOption(String value, String title) {
    // Giữ nguyên code
     final isSelected = _reminderType == value;
     return GestureDetector(
       onTap: () => setState(() => _reminderType = value),
       child: Container(
         padding: const EdgeInsets.all(12),
         decoration: BoxDecoration(
           color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Theme.of(context).cardColor,
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.3)),
         ),
         child: Text(title, textAlign: TextAlign.center, style: TextStyle(
           color: isSelected ? Theme.of(context).primaryColor : Colors.white,
           fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
         )),
       ),
     );
   }
   // --- KẾT THÚC CÁC HÀM BUILD WIDGET PHỤ ---

   // --- CÁC HÀM XỬ LÝ SỰ KIỆN GIỮ NGUYÊN ---
   Future<void> _selectCategory() async {
     final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectCategoryScreen()));
     if (result != null && result is CategoryModel) {
       setState(() => _selectedCategory = result);
     }
   }
   Future<void> _selectStartDate() async {
     final date = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2100)); // Cho phép chọn ngày quá khứ
     if (date != null) setState(() => _startDate = date);
   }
   Future<void> _selectEndDate() async {
     final date = await showDatePicker(context: context, initialDate: _endDate ?? _startDate.add(const Duration(days: 30)), firstDate: _startDate, lastDate: DateTime(2101));
     if (date != null) setState(() => _endDate = date);
   }
   Future<void> _selectReminderTime() async {
     final time = await showTimePicker(context: context, initialTime: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0));
     if (time != null) setState(() => _reminderTime = time);
   }
   String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
   String _formatTime(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
   // --- KẾT THÚC CÁC HÀM XỬ LÝ SỰ KIỆN ---

   // 4. Đổi tên hàm thành _updateHabit và gọi API update
   Future<void> _updateHabit() async {
     if (!_formKey.currentState!.validate()) return;
     if (_selectedCategory == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục')));
       return;
     }
     if (_hasReminder && _reminderTime == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn thời gian nhắc nhở')));
       return;
     }

     setState(() => _isLoading = true);

     try {
       // Tạo đối tượng DTO để gửi đi (có thể bạn cần tạo UpdateHabitDto riêng)
       final habitUpdateData = CreateHabitModel( // Tạm dùng CreateHabitModel, nên tạo UpdateHabitDto
         name: _nameController.text.trim(),
         description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
         categoryId: _selectedCategory!.id,
         startDate: _startDate,
         endDate: _hasEndDate ? _endDate : null,
         frequency: _frequency,
         hasReminder: _hasReminder,
         reminderTime: _hasReminder && _reminderTime != null
             ? Duration(hours: _reminderTime!.hour, minutes: _reminderTime!.minute)
             : null,
         reminderType: _hasReminder ? _reminderType : null,
         // Các trường khác như customFrequency nếu cần
       );

       // *** Gọi API updateHabit ***
       // Bạn cần thêm hàm updateHabit(int id, CreateHabitModel data) vào HabitApiService
       await _habitApiService.updateHabit(widget.habit.id, habitUpdateData);

       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Cập nhật thói quen thành công!')),
         );
         Navigator.pop(context, true); // Trả về true để HomeScreen tải lại
       }
     } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Lỗi khi cập nhật thói quen: $e')),
         );
       }
     } finally {
       if (mounted) {
         setState(() => _isLoading = false);
       }
     }
   }
}