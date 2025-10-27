/// Model đại diện cho ghi chú nhật ký thói quen
class HabitNoteModel {
  /// ID duy nhất của ghi chú
  final int id;

  /// ID của thói quen liên kết
  final int habitId;

  /// Tên thói quen
  final String habitName;

  /// Ngày ghi chú
  final DateTime date;

  /// Nội dung ghi chú
  final String content;

  /// Mức độ cảm xúc (1-5)
  /// 1: Rất buồn, 2: Buồn, 3: Bình thường, 4: Vui, 5: Rất vui
  final int? mood;

  /// Biểu tượng cảm xúc tương ứng
  final String? moodEmoji;

  /// Thời điểm tạo ghi chú
  final DateTime createdAt;

  /// Thời điểm cập nhật cuối cùng
  final DateTime updatedAt;

  /// Khởi tạo HabitNoteModel
  HabitNoteModel({
    required this.id,
    required this.habitId,
    required this.habitName,
    required this.date,
    required this.content,
    this.mood,
    this.moodEmoji,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Tạo HabitNoteModel từ JSON
  factory HabitNoteModel.fromJson(Map<String, dynamic> json) {
    return HabitNoteModel(
      id: json['id'] as int,
      habitId: json['habitId'] as int,
      habitName: json['habitName'] as String,
      date: DateTime.parse(json['date'] as String),
      content: json['content'] as String,
      mood: json['mood'] as int?,
      moodEmoji: json['moodEmoji'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Chuyển HabitNoteModel thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'habitName': habitName,
      'date': date.toIso8601String(),
      'content': content,
      'mood': mood,
      'moodEmoji': moodEmoji,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Tạo bản sao của HabitNoteModel với các giá trị được cập nhật
  HabitNoteModel copyWith({
    int? id,
    int? habitId,
    String? habitName,
    DateTime? date,
    String? content,
    int? mood,
    String? moodEmoji,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitNoteModel(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      habitName: habitName ?? this.habitName,
      date: date ?? this.date,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Lấy emoji cảm xúc từ mức độ
  static String? getMoodEmoji(int? mood) {
    switch (mood) {
      case 1:
        return '😢'; // Rất buồn
      case 2:
        return '😞'; // Buồn
      case 3:
        return '😐'; // Bình thường
      case 4:
        return '😊'; // Vui
      case 5:
        return '😄'; // Rất vui
      default:
        return null;
    }
  }

  /// Lấy tên cảm xúc từ mức độ
  static String? getMoodName(int? mood) {
    switch (mood) {
      case 1:
        return 'Rất buồn';
      case 2:
        return 'Buồn';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Vui';
      case 5:
        return 'Rất vui';
      default:
        return null;
    }
  }
}

/// Model để tạo ghi chú mới
class CreateHabitNoteModel {
  /// ID của thói quen
  final int habitId;

  /// Ngày ghi chú
  final DateTime date;

  /// Nội dung ghi chú
  final String content;

  /// Mức độ cảm xúc (1-5)
  final int? mood;

  /// Khởi tạo CreateHabitNoteModel
  CreateHabitNoteModel({
    required this.habitId,
    required this.date,
    required this.content,
    this.mood,
  });

  /// Chuyển CreateHabitNoteModel thành JSON
  Map<String, dynamic> toJson() {
    return {
      'habitId': habitId,
      'date': date.toIso8601String(),
      'content': content,
      'mood': mood,
    };
  }
}

/// Model để cập nhật ghi chú
class UpdateHabitNoteModel {
  /// Nội dung ghi chú mới
  final String? content;

  /// Mức độ cảm xúc mới (1-5)
  final int? mood;

  /// Khởi tạo UpdateHabitNoteModel
  UpdateHabitNoteModel({
    this.content,
    this.mood,
  });

  /// Chuyển UpdateHabitNoteModel thành JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (content != null) {
      data['content'] = content;
    }
    
    if (mood != null) {
      data['mood'] = mood;
    }
    
    return data;
  }
}