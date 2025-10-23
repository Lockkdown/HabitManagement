import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../models/category_model.dart';
import '../api/habit_api_service.dart';
import '../utils/icon_utils.dart';

class CreateCategoryScreen extends ConsumerStatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  ConsumerState<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends ConsumerState<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  final HabitApiService _habitApiService = HabitApiService();
  bool _isLoading = false;
  
  // Màu sắc và icon được chọn
  String _selectedColor = '#FF6B6B';
  String _selectedIcon = 'heart';
  
  // Danh sách màu sắc có sẵn
  final List<String> _colors = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD', '#A8A8A8',
    '#FF9F43', '#10AC84', '#5F27CD', '#00D2D3', '#FF6348', '#2ED573', '#FFA502',
    '#FF3838', '#3742FA', '#2F3542', '#FF4757', '#2ED573', '#FFA502', '#FF6348',
  ];
  
  // Danh sách icon có sẵn
  final List<String> _icons = [
    'heart', 'book', 'briefcase', 'dumbbell', 'music', 'home', 'more-horizontal',
    'target', 'star', 'shield', 'zap', 'sun', 'moon', 'coffee', 'car', 'plane',
    'gift', 'smile', 'camera', 'phone', 'mail', 'map', 'compass', 'flag',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo danh mục mới'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createCategory,
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
            // Tên danh mục
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên danh mục',
                hintText: 'Nhập tên danh mục',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên danh mục';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Chọn màu sắc
            _buildSectionHeader('Màu sắc'),
            const SizedBox(height: 16),
            _buildColorSelector(),
            const SizedBox(height: 24),
            
            // Chọn icon
            _buildSectionHeader('Biểu tượng'),
            const SizedBox(height: 16),
            _buildIconSelector(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildColorSelector() {
    return Column(
      children: [
        // Color picker chính
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final color = _colors[index];
                final isSelected = _selectedColor == color;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected 
                          ? Border.all(
                              color: Colors.white,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            LucideIcons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Hiển thị màu đã chọn
        Container(
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
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Màu đã chọn: $_selectedColor',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconSelector() {
    return Column(
      children: [
        // Icon grid
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _icons.length,
              itemBuilder: (context, index) {
                final icon = _icons[index];
                final isSelected = _selectedIcon == icon;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected 
                          ? Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            )
                          : Border.all(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                    ),
                    child: Icon(
                      IconUtils.getIconData(icon),
                      color: isSelected 
                          ? Theme.of(context).primaryColor
                          : Colors.grey[400],
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Hiển thị icon đã chọn
        Container(
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
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  IconUtils.getIconData(_selectedIcon),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biểu tượng đã chọn',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedIcon,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final category = CreateCategoryModel(
        name: _nameController.text.trim(),
        color: _selectedColor,
        icon: _selectedIcon,
      );

      await _habitApiService.createCategory(category);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo danh mục thành công!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tạo danh mục: $e')),
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
