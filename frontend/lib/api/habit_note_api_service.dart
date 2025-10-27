import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/habit_note_model.dart';
import '../services/storage_service.dart';

/// Service để gọi các API endpoints liên quan đến Habit Notes
class HabitNoteApiService {
  /// Lấy base URL từ file .env
  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:5224';
  
  final StorageService _storageService = StorageService();

  /// Lấy access token từ storage
  Future<String?> _getAccessToken() async {
    return await _storageService.getAccessToken();
  }

  /// Tạo headers với authorization và ngrok skip
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAccessToken();
    debugPrint("Token retrieved: ${token != null ? 'EXISTS (${token.length} chars)' : 'NULL'}");
    
    if (token == null) {
      debugPrint("Warning: No access token found for API request.");
      return {
        'Content-Type': 'application/json; charset=UTF-8',
        'ngrok-skip-browser-warning': 'true',
      };
    }
    
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
    };
    
    debugPrint("Headers created: $headers");
    return headers;
  }

  /// Lấy tất cả ghi chú của một thói quen
  Future<List<HabitNoteModel>> getHabitNotes(int habitId) async {
    try {
      debugPrint("Getting habit notes for habit ID: $habitId");
      final response = await http.get(
        Uri.parse('$_baseUrl/api/habitnote/habit/$habitId'),
        headers: await _getHeaders(),
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => HabitNoteModel.fromJson(json)).toList();
      } else {
        debugPrint('Error getting habit notes (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi lấy danh sách ghi chú: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection error getting habit notes: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Lấy ghi chú của một thói quen theo ngày
  Future<HabitNoteModel?> getHabitNoteByDate(int habitId, DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0]; // Chỉ lấy phần ngày
      debugPrint("Getting habit note for habit ID: $habitId, date: $dateString");
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/habitnote/habit/$habitId/date/$dateString'),
        headers: await _getHeaders(),
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return HabitNoteModel.fromJson(data);
      } else if (response.statusCode == 404) {
        // Không có ghi chú cho ngày này
        return null;
      } else {
        debugPrint('Error getting habit note by date (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi lấy ghi chú: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection error getting habit note by date: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Tạo ghi chú mới
  Future<HabitNoteModel> createHabitNote(CreateHabitNoteModel note) async {
    try {
      debugPrint("Creating habit note: ${note.toJson()}");
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/habitnote'),
        headers: await _getHeaders(),
        body: json.encode(note.toJson()),
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 201) {
        return HabitNoteModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        debugPrint('Error creating habit note (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi tạo ghi chú: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection error creating habit note: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Cập nhật ghi chú
  Future<HabitNoteModel> updateHabitNote(int noteId, UpdateHabitNoteModel note) async {
    try {
      debugPrint("Updating habit note ID: $noteId with data: ${note.toJson()}");
      
      final response = await http.put(
        Uri.parse('$_baseUrl/api/habitnote/$noteId'),
        headers: await _getHeaders(),
        body: json.encode(note.toJson()),
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        return HabitNoteModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        debugPrint('Error updating habit note (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi cập nhật ghi chú: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection error updating habit note: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Xóa ghi chú
  Future<void> deleteHabitNote(int noteId) async {
    try {
      debugPrint("Deleting habit note ID: $noteId");
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/habitnote/$noteId'),
        headers: await _getHeaders(),
      );

      debugPrint("Response status: ${response.statusCode}");

      if (response.statusCode != 204) {
        debugPrint('Error deleting habit note (${response.statusCode}): ${response.body}');
        throw Exception('Lỗi khi xóa ghi chú: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection error deleting habit note: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }
}