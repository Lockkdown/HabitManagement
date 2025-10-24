class CategoryModel {
  final int id;
  final String name;
  final String color;
  final String icon;
  final int habitCount;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.habitCount,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
      habitCount: json['habitCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'habitCount': habitCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    String? color,
    String? icon,
    int? habitCount,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      habitCount: habitCount ?? this.habitCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CreateCategoryModel {
  final String name;
  final String color;
  final String icon;

  CreateCategoryModel({
    required this.name,
    required this.color,
    required this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
      'icon': icon,
    };
  }
}

