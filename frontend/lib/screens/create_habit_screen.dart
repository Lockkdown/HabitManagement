import 'dart:convert'; // <-- 1. TÔI ĐÃ THÊM DÒNG NÀY
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../models/habit_model.dart';
import '../models/category_model.dart';
import '../api/habit_api_service.dart';
import 'select_category_screen.dart';

class CreateHabitScreen extends ConsumerStatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  ConsumerState<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends ConsumerState<CreateHabitScreen> {
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
  
  // Thêm biến cho ngày trong tuần và ngày trong tháng
  final List<int> _selectedDaysOfWeek = [];
  final List<int> _selectedDaysOfMonth = [];
  
  final HabitApiService _habitApiService = HabitApiService();
  bool _isLoading = false;

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
        title: const Text(
          'Tạo thói quen',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createHabit,
            child: const Text(
              'Tạo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Thông tin chung
            _buildSectionHeader('Thông tin chung', isRequired: true),
            const SizedBox(height: 16),
            
            // Tên thói quen
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên thói quen',
                hintText: 'Nhập tên thói quen',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên thói quen';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Loại thói quen (Danh mục)
            GestureDetector(
              onTap: _selectCategory,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.tag,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCategory?.name ?? 'Chọn danh mục',
                        style: TextStyle(
                          color: _selectedCategory != null 
                              ? Colors.white 
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Ngày bắt đầu
            GestureDetector(
              onTap: _selectStartDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ngày bắt đầu: ${_formatDate(_startDate)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Ngày kết thúc
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ngày kết thúc',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
                Switch(
                  value: _hasEndDate,
                  onChanged: (value) {
                    setState(() {
                      _hasEndDate = value;
                      if (!value) {
                        _endDate = null;
                      }
                    });
                  },
                ),
              ],
            ),
            if (_hasEndDate) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _selectEndDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ngày kết thúc: ${_endDate != null ? _formatDate(_endDate!) : "Chọn ngày"}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            
            // Tần suất
            _buildSectionHeader('Tần suất'),
            const SizedBox(height: 16),
            _buildFrequencySelector(),
            const SizedBox(height: 24),
            
            // Nhắc nhở
            _buildSectionHeader('Nhắc nhở', isOptional: true),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Thêm nhắc nhở',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
                Switch(
                  value: _hasReminder,
                  onChanged: (value) {
                    setState(() {
                      _hasReminder = value;
                    });
                  },
                ),
              ],
            ),
            if (_hasReminder) ...[
              const SizedBox(height: 16),
              _buildReminderSettings(),
            ],
            const SizedBox(height: 24),
            
            // Mô tả
            _buildSectionHeader('Mô tả', isOptional: true),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Nhập mô tả cho thói quen (tùy chọn)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isRequired = false, bool isOptional = false}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Bắt buộc',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        if (isOptional) ...[
          const SizedBox(width: 4),
          Text(
            '(Tùy chọn)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFrequencySelector() {
    return Column(
      children: [
        _buildFrequencyOption('daily', 'Hàng ngày', 'Mỗi ngày'),
        _buildFrequencyOption('weekly', 'Hàng tuần', 'Mỗi tuần'),
        if (_frequency == 'weekly') _buildWeekdaySelector(),
        _buildFrequencyOption('monthly', 'Hàng tháng', 'Mỗi tháng'),
        if (_frequency == 'monthly') _buildMonthDaySelector(),
      ],
    );
  }
  
  // Widget chọn ngày trong tuần
  Widget _buildWeekdaySelector() {
    final weekdays = [
      {'day': 1, 'name': 'Thứ Hai'},
  {'day': 2, 'name': 'Thứ Ba'},
  {'day': 3, 'name': 'Thứ Tư'},
  {'day': 4, 'name': 'Thứ Năm'},
  {'day': 5, 'name': 'Thứ Sáu'}, // <-- Đúng
  {'day': 6, 'name': 'Thứ Bảy'},
  {'day': 7, 'name': 'Chủ Nhật'},
    ];
    
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn ngày trong tuần',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: weekdays.map((day) {
              final isSelected = _selectedDaysOfWeek.contains(day['day']);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDaysOfWeek.remove(day['day']);
                    } else {
                      _selectedDaysOfWeek.add(day['day'] as int);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).primaryColor
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    day['name'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  // Widget chọn ngày trong tháng
  Widget _buildMonthDaySelector() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn ngày trong tháng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(31, (index) {
              final day = index + 1;
              final isSelected = _selectedDaysOfMonth.contains(day);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDaysOfMonth.remove(day);
                    } else {
                      _selectedDaysOfMonth.add(day);
                    }
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).primaryColor
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyOption(String value, String title, String description) {
    final isSelected = _frequency == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _frequency = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _frequency,
              onChanged: (value) {
                setState(() {
                  _frequency = value!;
                });
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSettings() {
    return Column(
      children: [
        // Thời gian nhắc nhở
        GestureDetector(
          onTap: _selectReminderTime,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.clock,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Thời gian: ${_reminderTime != null ? _formatTime(_reminderTime!) : "Chọn giờ"}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Loại nhắc nhở
        Row(
          children: [
            Expanded(
              child: _buildReminderTypeOption('notification', 'Thông báo'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildReminderTypeOption('sound', 'Âm thanh'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReminderTypeOption(String value, String title) {
    final isSelected = _reminderType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _reminderType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _selectCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectCategoryScreen(),
      ),
    );
    
    if (result != null && result is CategoryModel) {
      setState(() {
        _selectedCategory = result;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    
    if (time != null) {
      setState(() {
        _reminderTime = time;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _createHabit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục')),
      );
      return;
    }

    if (_hasReminder && _reminderTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian nhắc nhở')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final habit = CreateHabitModel(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        categoryId: _selectedCategory!.id,
        startDate: _startDate,
        endDate: _hasEndDate ? _endDate : null,
        frequency: _frequency,
        // Thêm daysOfWeek nếu tần suất là weekly
        daysOfWeek: _frequency == 'weekly' && _selectedDaysOfWeek.isNotEmpty 
            ? _selectedDaysOfWeek 
            : null,
        // Thêm daysOfMonth nếu tần suất là monthly
        daysOfMonth: _frequency == 'monthly' && _selectedDaysOfMonth.isNotEmpty 
            ? _selectedDaysOfMonth 
            : null,
        hasReminder: _hasReminder,
        reminderTime: _hasReminder && _reminderTime != null
            ? Duration(hours: _reminderTime!.hour, minutes: _reminderTime!.minute)
            : null,
        reminderType: _hasReminder ? _reminderType : null,
      );

      // ========================================================
      // 2. TÔI ĐÃ THÊM CÁC DÒNG CODE DEBUG NÀY VÀO
      print('----------------------------------------------------');
      print('CHUẨN BỊ GỬI LÊN SERVER (createHabit):');
      print(json.encode(habit.toJson())); // In ra JSON
      print('----------------------------------------------------');
      // ========================================================

      await _habitApiService.createHabit(habit);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo thói quen thành công!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tạo thói quen: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}