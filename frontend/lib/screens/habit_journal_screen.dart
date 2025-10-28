import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../models/habit_model.dart';
import '../models/habit_note_model.dart';
import '../api/habit_note_api_service.dart';

/// Màn hình Nhật ký thói quen
class HabitJournalScreen extends ConsumerStatefulWidget {
  final HabitModel habit;

  const HabitJournalScreen({
    super.key,
    required this.habit,
  });

  @override
  ConsumerState<HabitJournalScreen> createState() => _HabitJournalScreenState();
}

class _HabitJournalScreenState extends ConsumerState<HabitJournalScreen> {
  final HabitNoteApiService _apiService = HabitNoteApiService();
  final TextEditingController _contentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<HabitNoteModel> _notes = [];
  bool _isLoading = true;
  bool _isSaving = false;
  int? _selectedMood;
  DateTime _selectedDate = DateTime.now();
  HabitNoteModel? _editingNote;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Tải danh sách ghi chú
  Future<void> _loadNotes() async {
    try {
      setState(() => _isLoading = true);
      final notes = await _apiService.getHabitNotes(widget.habit.id);
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải ghi chú: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Lưu ghi chú mới hoặc cập nhật ghi chú hiện có
  Future<void> _saveNote() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung ghi chú'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);

      if (_editingNote != null) {
        // Cập nhật ghi chú hiện có
        final updatedNote = await _apiService.updateHabitNote(
          _editingNote!.id,
          UpdateHabitNoteModel(
            content: _contentController.text.trim(),
            mood: _selectedMood,
          ),
        );
        
        setState(() {
          final index = _notes.indexWhere((note) => note.id == _editingNote!.id);
          if (index != -1) {
            _notes[index] = updatedNote;
          }
        });
      } else {
        // Tạo ghi chú mới
        final newNote = await _apiService.createHabitNote(
          CreateHabitNoteModel(
            habitId: widget.habit.id,
            date: _selectedDate,
            content: _contentController.text.trim(),
            mood: _selectedMood,
          ),
        );
        
        setState(() {
          _notes.insert(0, newNote);
        });
      }

      // Reset form
      _resetForm();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingNote != null ? 'Đã cập nhật ghi chú' : 'Đã lưu ghi chú'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu ghi chú: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Xóa ghi chú
  Future<void> _deleteNote(HabitNoteModel note) async {
    try {
      await _apiService.deleteHabitNote(note.id);
      setState(() {
        _notes.removeWhere((n) => n.id == note.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa ghi chú'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa ghi chú: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Chỉnh sửa ghi chú
  void _editNote(HabitNoteModel note) {
    setState(() {
      _editingNote = note;
      _contentController.text = note.content;
      _selectedMood = note.mood;
      _selectedDate = note.date;
    });
    
    // Cuộn lên đầu để hiển thị form
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Reset form
  void _resetForm() {
    setState(() {
      _editingNote = null;
      _contentController.clear();
      _selectedMood = null;
      _selectedDate = DateTime.now();
    });
  }

  /// Chọn ngày
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.grey[800]!,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhật ký thói quen'),
            Text(
              widget.habit.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Form nhập ghi chú
          _buildNoteForm(),
          
          // Danh sách ghi chú
          Expanded(
            child: _buildNotesList(),
          ),
        ],
      ),
    );
  }

  /// Xây dựng form nhập ghi chú
  Widget _buildNoteForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                _editingNote != null ? LucideIcons.pencil : LucideIcons.plus,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                _editingNote != null ? 'Chỉnh sửa ghi chú' : 'Thêm ghi chú mới',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_editingNote != null)
                TextButton(
                  onPressed: _resetForm,
                  child: const Text('Hủy'),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Chọn ngày
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.calendar, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd/MM/yyyy - EEEE', 'vi').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  Icon(LucideIcons.chevronDown, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Nội dung ghi chú
          TextField(
            controller: _contentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Nhập nội dung ghi chú...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              filled: true,
              fillColor: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Chọn cảm xúc
          const Text(
            'Cảm xúc (tùy chọn)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final mood = index + 1;
              final isSelected = _selectedMood == mood;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMood = isSelected ? null : mood;
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected 
                        ? Theme.of(context).primaryColor.withOpacity(0.2)
                        : Colors.grey[800],
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600]!,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                    HabitNoteModel.getMoodEmoji(mood) ?? '',
                    style: const TextStyle(fontSize: 24),
                  ),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 16),
          
          // Nút lưu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _editingNote != null ? 'Cập nhật' : 'Lưu ghi chú',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Xây dựng danh sách ghi chú
  Widget _buildNotesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.bookOpen,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có ghi chú nào',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thêm ghi chú đầu tiên cho thói quen này',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return _buildNoteCard(note);
      },
    );
  }

  /// Xây dựng card ghi chú
  Widget _buildNoteCard(HabitNoteModel note) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với ngày và menu
            Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy - EEEE', 'vi').format(note.date),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (note.mood != null) ...[
                  Text(
                    note.moodEmoji ?? '',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                ],
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                  color: Colors.grey[800],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editNote(note);
                    } else if (value == 'delete') {
                      _showDeleteDialog(note);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(LucideIcons.pencil, size: 16, color: Colors.white70),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Nội dung ghi chú
            Text(
              note.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Thời gian tạo
            Row(
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  'Tạo lúc ${DateFormat('HH:mm dd/MM/yyyy').format(note.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Hiển thị dialog xác nhận xóa
  void _showDeleteDialog(HabitNoteModel note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa ghi chú này?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNote(note);
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}