import 'category_model.dart';
import 'habit_schedule_model.dart'; // Đảm bảo bạn có import này nếu HabitModel dùng HabitSchedule

// ==========================================================
// 1. HABIT MODEL (Model để nhận và hiển thị)
// ==========================================================
class HabitModel {
  final int id;
  final String name;
  final String? description;
  final CategoryModel category; // Đảm bảo CategoryModel được import và định nghĩa đúng
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
  final List<DateTime> completionDates;
  final HabitSchedule? habitSchedule; // Đảm bảo HabitSchedule được import và định nghĩa đúng

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
    this.completionDates = const [],
    this.habitSchedule,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
     // Thêm log để debug parsing
     // print('Parsing HabitModel from JSON: $json');
     try {
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
              ? _parseDuration(json['reminderTime'] as String) // Dùng hàm parse duration
              : null,
          reminderType: json['reminderType'] as String?,
          isActive: json['isActive'] as bool,
          weeklyCompletions: json['weeklyCompletions'] as int? ?? 0,
          monthlyCompletions: json['monthlyCompletions'] as int? ?? 0,
          createdAt: DateTime.parse(json['createdAt'] as String),

          completionDates: (json['completionDates'] as List<dynamic>?)
              ?.map((dateString) => DateTime.parse(dateString as String))
              .toList() ?? [],

          habitSchedule: json['habitSchedule'] != null
              ? HabitSchedule.fromJson(json['habitSchedule'] as Map<String, dynamic>) // Parse schedule
              : null,
        );
     } catch (e) {
        print('Error parsing HabitModel: $e');
        print('Problematic JSON: $json');
        rethrow; // Ném lại lỗi để biết rõ hơn
     }
  }

  // Hàm toJson này thường không cần thiết cho HabitModel (chỉ dùng để nhận dữ liệu)
  // Nhưng nếu cần, đảm bảo nó map đúng, bao gồm cả HabitScheduleDto
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.toJson(), // Giả sử CategoryModel có toJson()
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'frequency': frequency,
      'hasReminder': hasReminder,
       // Chuyển Duration thành string "HH:mm:ss" nếu cần gửi đi
      'reminderTime': reminderTime == null ? null :
          "${reminderTime!.inHours.toString().padLeft(2, '0')}:"
          "${(reminderTime!.inMinutes % 60).toString().padLeft(2, '0')}:"
          "${(reminderTime!.inSeconds % 60).toString().padLeft(2, '0')}",
      'reminderType': reminderType,
      'isActive': isActive,
      'weeklyCompletions': weeklyCompletions,
      'monthlyCompletions': monthlyCompletions,
      'createdAt': createdAt.toIso8601String(),
      'completionDates': completionDates.map((d) => d.toIso8601String()).toList(),
       // Map HabitSchedule sang JSON nếu có
      'habitSchedule': habitSchedule?.toJson(), // Giả sử HabitSchedule có toJson()
    };
  }

  // Hàm parse Duration từ chuỗi "HH:mm:ss" hoặc "HH:mm"
  static Duration _parseDuration(String durationString) {
     final parts = durationString.split(':');
     int hours = 0;
     int minutes = 0;
     int seconds = 0;
     if (parts.length >= 2) {
       hours = int.tryParse(parts[0]) ?? 0;
       minutes = int.tryParse(parts[1]) ?? 0;
       if (parts.length >= 3) {
          seconds = int.tryParse(parts[2]) ?? 0;
       }
     }
     return Duration(hours: hours, minutes: minutes, seconds: seconds);
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
    List<DateTime>? completionDates,
    HabitSchedule? habitSchedule,
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
      completionDates: completionDates ?? this.completionDates,
      habitSchedule: habitSchedule ?? this.habitSchedule,
    );
  }
}

// ==========================================================
// 2. CREATE HABIT MODEL (Dùng cho API Tạo Mới)
//    (Hàm toJson giữ nguyên, gửi List<int> trực tiếp)
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
  final List<int>? daysOfWeek; // Gửi List<int>
  final List<int>? daysOfMonth; // Gửi List<int>
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
      // FIX: Gửi chỉ phần date (yyyy-MM-dd) để tránh lỗi timezone
      'startDate': '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'endDate': endDate == null ? null : '${endDate!.year.toString().padLeft(4, '0')}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}',
      'frequency': frequency,
      'hasReminder': hasReminder,
      'reminderType': reminderType,
    };

    if (reminderTime != null) {
      // Gửi TimeSpan dưới dạng chuỗi "HH:mm:ss"
      data['reminderTime'] =
          "${reminderTime!.inHours.toString().padLeft(2, '0')}:"
          "${(reminderTime!.inMinutes % 60).toString().padLeft(2, '0')}:"
          "${(reminderTime!.inSeconds % 60).toString().padLeft(2, '0')}";
    }

    if (customFrequencyValue != null) {
      data['customFrequencyValue'] = customFrequencyValue;
    }

    if (customFrequencyUnit != null) {
      data['customFrequencyUnit'] = customFrequencyUnit;
    }

    // Gửi trực tiếp List<int>
    if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
      data['daysOfWeek'] = daysOfWeek;
    }

    if (daysOfMonth != null && daysOfMonth!.isNotEmpty) {
      data['daysOfMonth'] = daysOfMonth;
    }

    return data;
  }
}

// ==========================================================
// 3. UPDATE HABIT MODEL (Dùng cho API Cập Nhật)
//    (Hàm toJson đã sửa, gửi List<int> trực tiếp)
// ==========================================================
class UpdateHabitModel {
  // Các trường giống CreateHabitModel nhưng có thể nullable nếu API Update cho phép
  final String? name; // Cho phép null nếu không muốn cập nhật
  final String? description;
  final int? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? frequency;
  final int? customFrequencyValue;
  final String? customFrequencyUnit;
  final List<int>? daysOfWeek; // Gửi List<int>
  final List<int>? daysOfMonth; // Gửi List<int>
  final bool? hasReminder;
  final Duration? reminderTime;
  final String? reminderType;
   final bool? isActive; // Thêm IsActive

  UpdateHabitModel({
    this.name, // Constructor cho phép null
    this.description,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.frequency,
    this.customFrequencyValue,
    this.customFrequencyUnit,
    this.daysOfWeek,
    this.daysOfMonth,
    this.hasReminder,
    this.reminderTime,
    this.reminderType,
    this.isActive, // Thêm vào constructor
  });

  // === HÀM toJson() ĐÃ SỬA ===
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {}; // Khởi tạo rỗng

     // Chỉ thêm các trường có giá trị vào JSON
     if (name != null) data['name'] = name;
     data['description'] = description; // Cho phép gửi null
     if (categoryId != null) data['categoryId'] = categoryId;
     // FIX: Gửi chỉ phần date (yyyy-MM-dd) để tránh lỗi timezone
     if (startDate != null) data['startDate'] = '${startDate!.year.toString().padLeft(4, '0')}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}';
     data['endDate'] = endDate == null ? null : '${endDate!.year.toString().padLeft(4, '0')}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}'; // Cho phép gửi null
     if (frequency != null) data['frequency'] = frequency;
     if (hasReminder != null) data['hasReminder'] = hasReminder;
     data['reminderType'] = reminderType; // Cho phép gửi null
     if (isActive != null) data['isActive'] = isActive; // Thêm isActive


    if (reminderTime != null) {
      // Gửi TimeSpan dưới dạng chuỗi "HH:mm:ss"
      data['reminderTime'] =
          "${reminderTime!.inHours.toString().padLeft(2, '0')}:"
          "${(reminderTime!.inMinutes % 60).toString().padLeft(2, '0')}:"
          "${(reminderTime!.inSeconds % 60).toString().padLeft(2, '0')}";
    } else if (hasReminder == false) {
       // Nếu tắt reminder, có thể cần gửi null hoặc bỏ qua trường reminderTime
       // data['reminderTime'] = null; // Gửi null nếu API yêu cầu
    }


    if (customFrequencyValue != null) {
      data['customFrequencyValue'] = customFrequencyValue;
    }
    if (customFrequencyUnit != null) {
      data['customFrequencyUnit'] = customFrequencyUnit;
    }

    // === GỬI TRỰC TIẾP List<int> ===
    // Thêm kiểm tra null trước khi kiểm tra isNotEmpty
    if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
      data['daysOfWeek'] = daysOfWeek;
    } else if (frequency?.toLowerCase() == 'weekly') {
       // Nếu frequency là weekly nhưng list rỗng, gửi mảng rỗng hoặc null tùy API backend
       data['daysOfWeek'] = []; // Hoặc null nếu backend chấp nhận
    }


    if (daysOfMonth != null && daysOfMonth!.isNotEmpty) {
      data['daysOfMonth'] = daysOfMonth;
    } else if (frequency?.toLowerCase() == 'monthly') {
       // Nếu frequency là monthly nhưng list rỗng, gửi mảng rỗng hoặc null tùy API backend
       data['daysOfMonth'] = []; // Hoặc null nếu backend chấp nhận
    }


    return data;
  }
} // Kết thúc class UpdateHabitModel


// ==========================================================
// 4. HABIT COMPLETION MODEL (Không thay đổi)
// ==========================================================
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
     try {
       return HabitCompletionModel(
         id: json['id'] as int,
         habitId: json['habitId'] as int,
         completedAt: DateTime.parse(json['completedAt'] as String),
         notes: json['notes'] as String?,
       );
     } catch (e) {
        print('Error parsing HabitCompletionModel: $e');
        print('Problematic JSON: $json');
        rethrow;
     }
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