// lib/screens/select_category_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../models/category_model.dart';
import '../utils/icon_utils.dart';
import 'create_category_screen.dart';
import '../services/category_providers.dart'; // Đảm bảo đường dẫn này đúng
import '../api/habit_api_service.dart';     // Import HabitApiService

class SelectCategoryScreen extends ConsumerStatefulWidget {
  const SelectCategoryScreen({super.key});

  @override
  ConsumerState<SelectCategoryScreen> createState() =>
      _SelectCategoryScreenState();
}

class _SelectCategoryScreenState extends ConsumerState<SelectCategoryScreen> {
  bool _showDefaultOnly = true;
  bool _isProcessingSelection = false; // State loading khi chọn mặc định

  // --- HÀM XỬ LÝ KHI CHỌN DANH MỤC ---
  Future<void> _handleCategorySelection(CategoryModel category) async {
    // *** QUAN TRỌNG: Điều chỉnh điều kiện này cho đúng ***
    // Giả sử: ID âm LÀ danh mục mặc định VÀ KHÔNG phải danh mục người dùng tự tạo
    final bool isTrulyDefaultCategory = category.id < 0; // Hoặc dùng trường isDefault nếu có

    if (isTrulyDefaultCategory && mounted) {
      setState(() => _isProcessingSelection = true); // Bắt đầu loading
      try {
        // Lấy service API thông qua Riverpod provider
        final apiService = ref.read(habitApiServiceProvider); // Đảm bảo provider này tồn tại

        // Tạo DTO để gửi lên API createCategory
        // Lưu ý: CreateCategoryModel cần có constructor nhận đủ thông tin
        final createDto = CreateCategoryModel(
          name: category.name,
          color: category.color,
          icon: category.icon,
        );

        // Gọi API để tạo bản sao danh mục này cho user hiện tại
        final newCategory = await apiService.createCategory(createDto);

        // Nếu thành công, trả về danh mục MỚI với ID hợp lệ
        if (mounted) {
           Navigator.pop(context, newCategory); // Trả về category mới tạo
        }

      } catch (e) {
        // Nếu lỗi, hiển thị thông báo
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi sao chép danh mục: $e')),
          );
        }
      } finally {
         if (mounted) {
            setState(() => _isProcessingSelection = false); // Kết thúc loading
         }
      }
    } else {
      // Nếu là "Danh mục của tôi" (ID dương), trả về như cũ
      Navigator.pop(context, category);
    }
  }
  // --- KẾT THÚC HÀM XỬ LÝ ---

  @override
  Widget build(BuildContext context) {
    final categoriesAsyncValue = ref.watch(categoriesProvider);

    return Stack( // Bọc Scaffold bằng Stack để có loading overlay
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Chọn danh mục'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              TextButton(
                // Disable nút khi đang xử lý
                onPressed: _isProcessingSelection ? null : () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateCategoryScreen()),
                  );
                  if (result == true) {
                    ref.invalidate(categoriesProvider); // Tải lại cả 2 danh sách
                  }
                },
                child: const Text(
                  'Tạo mới',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          body: categoriesAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Lỗi khi tải danh mục: $error')),
            data: (categoriesData) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildToggleButton(
                            'Danh mục mặc định',
                            _showDefaultOnly,
                            // Disable nút khi đang xử lý
                            _isProcessingSelection ? null : () => setState(() => _showDefaultOnly = true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildToggleButton(
                            'Danh mục của tôi',
                            !_showDefaultOnly,
                            // Disable nút khi đang xử lý
                            _isProcessingSelection ? null : () => setState(() => _showDefaultOnly = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _showDefaultOnly
                        ? _buildDefaultCategoriesList(categoriesData.defaultCategories)
                        : _buildUserCategoriesList(categoriesData.userCategories),
                  ),
                ],
              );
            },
          ),
        ),
        // Lớp phủ loading
        if (_isProcessingSelection)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback? onTap) { // Sửa thành VoidCallback?
    return GestureDetector(
      onTap: onTap, // onTap có thể null
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (onTap != null ? Theme.of(context).primaryColor : Colors.grey) // Màu xám khi disable
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (onTap != null ? Theme.of(context).primaryColor : Colors.grey)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          text, textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultCategoriesList(List<CategoryModel> defaultCategories) {
    if (defaultCategories.isEmpty) return const Center(child: Text('Không có danh mục mặc định'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: defaultCategories.length,
      itemBuilder: (context, index) => _buildCategoryCard(defaultCategories[index], isUserCategory: false),
    );
  }

  Widget _buildUserCategoriesList(List<CategoryModel> userCategories) {
    if (userCategories.isEmpty) {
       return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
         Icon(LucideIcons.folderPlus, size: 80, color: Colors.grey[400]),
         const SizedBox(height: 16),
         Text('Chưa có danh mục nào', style: TextStyle(fontSize: 18, color: Colors.grey[400], fontWeight: FontWeight.w500)),
         const SizedBox(height: 8),
         Text('Nhấn "Tạo mới" để tạo danh mục đầu tiên', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
       ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: userCategories.length,
      itemBuilder: (context, index) => _buildCategoryCard(userCategories[index], isUserCategory: true),
    );
  }

  // Sửa _buildCategoryCard để gọi hàm xử lý mới
  Widget _buildCategoryCard(CategoryModel category, {required bool isUserCategory}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(IconUtils.getIconData(category.icon), color: Colors.white, size: 24),
        ),
        title: Text(category.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: Text('${category.habitCount} thói quen', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        trailing: isUserCategory 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // FIX: Ẩn nút xóa cho danh mục "Không có danh mục"
                if (category.name != 'Không có danh mục')
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
                    onPressed: _isProcessingSelection ? null : () => _confirmDeleteCategory(category),
                  ),
                const Icon(LucideIcons.chevronRight),
              ],
            )
          : const Icon(LucideIcons.chevronRight),
        enabled: !_isProcessingSelection, // Disable khi đang xử lý
        onTap: _isProcessingSelection ? null : () {
            // Gọi hàm xử lý mới
            _handleCategorySelection(category);
        },
      ),
    );
  }

  // Hàm confirm và xóa category
  Future<void> _confirmDeleteCategory(CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa danh mục "${category.name}"?\n\nLưu ý: Các thói quen thuộc danh mục này sẽ không bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final apiService = ref.read(habitApiServiceProvider);
        await apiService.deleteCategory(category.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã xóa danh mục "${category.name}"')),
          );
          // Refresh lại danh sách
          ref.invalidate(categoriesProvider);
        }
      } catch (e) {
        if (mounted) {
          // Parse error message từ Exception
          String errorMessage = e.toString();
          if (errorMessage.contains('Exception:')) {
            errorMessage = errorMessage.replaceFirst('Exception:', '').trim();
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}