import 'category_model.dart';
import 'habit_schedule_model.dart';

class HabitModel {
  final int id;
  final String name;
  final String? description;
  final CategoryModel category;
  final DateTime startDate;
  final DateTime? endDate;
  final String frequency;
  final bool hasReminder;
  final Duration? reminderTime;
  final String? reminderType;
  final bool isActive;
  final int weeklyCompletions;
  final int monthlyCompletions;
  final DateTime createdAt;
  final List<DateTime> completionDates; // <-- 1. ĐÃ THÊM BIẾN MỚI
  final HabitSchedule? habitSchedule; // <-- THÊM FIELD CHO HABIT SCHEDULE

  HabitModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.startDate,
    this.endDate,
    required this.frequency,
    required this.hasReminder,
    this.reminderTime,
    this.reminderType,
    required this.isActive,
    required this.weeklyCompletions,
    required this.monthlyCompletions,
    required this.createdAt,
    this.completionDates = const [], // <-- 2. THÊM VÀO CONSTRUCTOR (với mặc định)
    this.habitSchedule, // <-- SỬA PARAMETER
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      frequency: json['frequency'] as String,
      hasReminder: json['hasReminder'] as bool,
      reminderTime: json['reminderTime'] != null
          ? _parseDuration(json['reminderTime'] as String)
          : null,
      reminderType: json['reminderType'] as String?,
      isActive: json['isActive'] as bool,
      weeklyCompletions: json['weeklyCompletions'] as int? ?? 0,
      monthlyCompletions: json['monthlyCompletions'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      
      // 3. THÊM LOGIC PARSE TỪ JSON
      completionDates: (json['completionDates'] as List<dynamic>?)
          ?.map((dateString) => DateTime.parse(dateString as String))
          .toList() ?? [], // Mặc định là list rỗng nếu API không trả về

      habitSchedule: json['habitSchedule'] != null
        ? HabitSchedule.fromJson(json['habitSchedule'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.toJson(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'frequency': frequency,
      'hasReminder': hasReminder,
      'reminderTime': reminderTime?.toString(),
      'reminderType': reminderType,
      'isActive': isActive,
      'weeklyCompletions': weeklyCompletions,
      'monthlyCompletions': monthlyCompletions,
      'createdAt': createdAt.toIso8601String(),
      // 4. THÊM VÀO TOJSON
      'completionDates': completionDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  static Duration _parseDuration(String durationString) {
    // Parse duration string like "2:30:00" (hours:minutes:seconds)
    final parts = durationString.split(':');
    if (parts.length >= 2) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      return Duration(hours: hours, minutes: minutes);
    }
    return Duration.zero;
  }

  HabitModel copyWith({
    int? id,
    String? name,
    String? description,
    CategoryModel? category,
    DateTime? startDate,
    DateTime? endDate,
    String? frequency,
    bool? hasReminder,
    Duration? reminderTime,
    String? reminderType,
    bool? isActive,
    int? weeklyCompletions,
    int? monthlyCompletions,
    DateTime? createdAt,
    List<DateTime>? completionDates, // <-- 5. THÊM VÀO COPYWITH
    HabitSchedule? habitSchedule, // <-- THÊM HABIT SCHEDULE VÀO COPYWITH
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      frequency: frequency ?? this.frequency,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderType: reminderType ?? this.reminderType,
      isActive: isActive ?? this.isActive,
      weeklyCompletions: weeklyCompletions ?? this.weeklyCompletions,
      monthlyCompletions: monthlyCompletions ?? this.monthlyCompletions,
      createdAt: createdAt ?? this.createdAt,
      completionDates: completionDates ?? this.completionDates, // <-- 5.
      habitSchedule: habitSchedule ?? this.habitSchedule, // <-- THÊM VÀO RETURN
    );
  }
}

// ==========================================================
// CÁC CLASS BÊN DƯỚI KHÔNG THAY ĐỔI
// ==========================================================

class CreateHabitModel {
  final String name;
  final String? description;
  final int categoryId;
  final DateTime startDate;
  final DateTime? endDate;
  final String frequency;
  final int? customFrequencyValue;
  final String? customFrequencyUnit;
  final List<int>? daysOfWeek;
  final List<int>? daysOfMonth;
  final bool hasReminder;
  final Duration? reminderTime;
  final String? reminderType;

  CreateHabitModel({
    required this.name,
    this.description,
    required this.categoryId,
    required this.startDate,
    this.endDate,
    required this.frequency,
    this.customFrequencyValue,
    this.customFrequencyUnit,
    this.daysOfWeek,
    this.daysOfMonth,
    required this.hasReminder,
    this.reminderTime,
    this.reminderType,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'frequency': frequency,
      'hasReminder': hasReminder,
      'reminderType': reminderType,
    };
    
    // Chỉ thêm reminderTime nếu có
    if (reminderTime != null) {
      data['reminderTime'] = reminderTime.toString();
    }
    
    // Chỉ thêm các trường tần suất tùy chỉnh nếu có
    if (customFrequencyValue != null) {
      data['customFrequencyValue'] = customFrequencyValue;
    }
    
    if (customFrequencyUnit != null) {
      data['customFrequencyUnit'] = customFrequencyUnit;
    }
    
    // Thêm daysOfWeek và daysOfMonth nếu có
    if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
      data['daysOfWeek'] = daysOfWeek;
    }
    
    if (daysOfMonth != null && daysOfMonth!.isNotEmpty) {
      data['daysOfMonth'] = daysOfMonth;
    }
    
    return data;
  }
}

class HabitCompletionModel {
  final int id;
  final int habitId;
  final DateTime completedAt;
  final String? notes;

  HabitCompletionModel({
    required this.id,
    required this.habitId,
    required this.completedAt,
    this.notes,
  });

  factory HabitCompletionModel.fromJson(Map<String, dynamic> json) {
    return HabitCompletionModel(
      id: json['id'] as int,
      habitId: json['habitId'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'completedAt': completedAt.toIso8601String(),
      'notes': notes,
    };
  }
}