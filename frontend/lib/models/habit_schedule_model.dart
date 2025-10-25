// lib/models/habit_schedule_model.dart

class HabitSchedule {
  final int id;
  final int habitId;
  final String frequencyType; // "Daily", "Weekly", "Monthly"
  final int frequencyValue; // ví dụ: 1 = mỗi ngày, 3 = cách 3 ngày
  final String daysOfWeek; // "Mon,Wed,Fri"
  final int dayOfMonth; // 15
  final bool isActive;

  HabitSchedule({
    required this.id,
    required this.habitId,
    required this.frequencyType,
    required this.frequencyValue,
    required this.daysOfWeek,
    required this.dayOfMonth,
    required this.isActive,
  });

  factory HabitSchedule.fromJson(Map<String, dynamic> json) {
    return HabitSchedule(
      id: json['id'] ?? 0,
      habitId: json['habitId'] ?? 0,
      frequencyType: json['frequencyType'] ?? '',
      frequencyValue: json['frequencyValue'] ?? 1,
      daysOfWeek: json['daysOfWeek'] ?? '',
      dayOfMonth: json['dayOfMonth'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'frequencyType': frequencyType,
      'frequencyValue': frequencyValue,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
      'isActive': isActive,
    };
  }
}
