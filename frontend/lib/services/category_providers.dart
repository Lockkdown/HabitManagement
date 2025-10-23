// lib/services/category_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart'; // <-- ĐÚNG (dùng dấu :)
import '../api/habit_api_service.dart';
import '../models/category_model.dart';

// 1. Provider để cung cấp HabitApiService
// Điều này giúp dễ dàng test và thay thế
final habitApiServiceProvider = Provider<HabitApiService>((ref) {
  return HabitApiService();
});

// 2. Provider để tải đồng thời cả 2 danh sách danh mục
// Dùng FutureProvider để tự động quản lý các trạng thái loading, data, error
final categoriesProvider = FutureProvider<({
  List<CategoryModel> userCategories,
  List<CategoryModel> defaultCategories
})>((ref) async {

  // Lấy service từ provider ở trên
  final apiService = ref.watch(habitApiServiceProvider);

  // Chạy cả hai lệnh gọi API song song để tải nhanh hơn
  final userCategoriesFuture = apiService.getCategories();
  final defaultCategoriesFuture = apiService.getDefaultCategories();

  // Đợi cả hai hoàn thành
  final (userCategories, defaultCategories) = await (
    userCategoriesFuture,
    defaultCategoriesFuture
  ).wait;

  // Trả về dữ liệu dưới dạng một Record
  return (userCategories: userCategories, defaultCategories: defaultCategories);
});