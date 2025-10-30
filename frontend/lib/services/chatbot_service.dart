import 'dart:math';
import '../api/habit_api_service.dart';
import '../models/habit_model.dart';
import '../models/category_model.dart';
import '../models/chatbot_response_model.dart';

/// Service xử lý logic chatbot cho việc phân tích intent và tạo habit
class ChatbotService {
  final HabitApiService _habitApiService = HabitApiService();
  final Random _random = Random();

  // Intent keywords chỉ cho navigation - không tạo/sửa/xóa thói quen
  final Map<String, List<String>> _intentKeywords = {
    // Các từ khóa cụ thể cho thống kê (ưu tiên cao)
    'open_statistics': [
      'thống kê thói quen', 'xem thống kê', 'thống kê', 'statistics',
      'báo cáo thói quen', 'tiến độ thói quen', 'mở thống kê',
      'cho tôi xem thống kê', 'hiển thị thống kê', 'báo cáo'
    ],
    
    // Các từ khóa cụ thể cho lịch trình hôm nay
    'open_habit_schedule': [
      'thói quen hôm nay', 'lịch hôm nay', 'hôm nay',
      'cho tôi xem thói quen hôm nay', 'xem thói quen hôm nay',
      'lịch trình hôm nay', 'schedule hôm nay', 'lịch trình',
      'lịch thói quen', 'xem lịch', 'mở lịch'
    ],
    
    // Các từ khóa cho xem tất cả thói quen
    'open_all_habits': [
      'tất cả thói quen', 'danh sách thói quen', 'xem tất cả',
      'liệt kê thói quen', 'tất cả habit', 'home', 'trang chủ',
      'toàn bộ thói quen', 'quản lý thói quen', 'thói quen của tôi'
    ],
    
    // Các từ khóa cho cài đặt
    'open_settings': [
      'cài đặt', 'thiết lập', 'tùy chọn', 'mở cài đặt', 
      'settings', 'setting', 'config', 'cấu hình'
    ],
    
    // Các từ khóa cho trợ giúp
    'help': [
      'giúp', 'hướng dẫn', 'help', 'trợ giúp', 
      'cách dùng', 'hỗ trợ', 'làm sao', 'chức năng'
    ],
  };

  // Response templates - chỉ cho navigation
  final Map<String, List<String>> _responseTemplates = {
    'greeting': [
      'Xin chào! Tôi có thể giúp gì cho bạn?',
      'Chào bạn! Bạn cần tôi hỗ trợ gì không?',
      'Tôi đang lắng nghe. Bạn cần giúp đỡ gì?'
    ],
    'help': [
      'Tôi có thể giúp bạn điều hướng đến:\n- Xem thói quen hôm nay\n- Xem thống kê\n- Xem tất cả thói quen\n- Mở cài đặt\nHãy nói hoặc nhập yêu cầu của bạn.',
      'Bạn có thể yêu cầu tôi:\n- "Xem thói quen hôm nay"\n- "Mở thống kê"\n- "Xem tất cả thói quen"\n- "Mở cài đặt"',
      'Một số câu lệnh bạn có thể dùng:\n- "Cho tôi xem lịch hôm nay"\n- "Hiển thị thống kê"\n- "Mở trang chủ"\n- "Vào cài đặt"'
    ],
    'fallback': [
      'Xin lỗi, tôi không hiểu yêu cầu của bạn. Bạn có thể nói rõ hơn được không?',
      'Tôi chưa hiểu ý bạn. Bạn có thể diễn đạt theo cách khác không?',
      'Tôi không chắc mình hiểu đúng. Bạn có thể nói lại được không?',
      'Tôi chỉ có thể giúp bạn điều hướng đến các trang trong ứng dụng. Hãy thử: "Xem thói quen hôm nay" hoặc "Mở thống kê"'
    ]
  };

  /// Phân tích intent từ input của người dùng
  String analyzeIntent(String input) {
    final lowerInput = input.toLowerCase();
    
    // Map để lưu điểm số cho mỗi intent
    Map<String, double> intentScores = {};
    
    for (final entry in _intentKeywords.entries) {
      final intent = entry.key;
      final keywords = entry.value;
      double score = 0.0;
      
      for (final keyword in keywords) {
        final lowerKeyword = keyword.toLowerCase();
        
        if (lowerInput.contains(lowerKeyword)) {
          // Tính điểm dựa trên độ dài và vị trí của từ khóa
          double keywordScore = lowerKeyword.length.toDouble();
          
          // Bonus điểm nếu từ khóa xuất hiện ở đầu câu
          if (lowerInput.startsWith(lowerKeyword)) {
            keywordScore *= 1.5;
          }
          
          // Bonus điểm nếu từ khóa là cụm từ dài (nhiều từ)
          if (lowerKeyword.split(' ').length > 1) {
            keywordScore *= 2.0;
          }
          
          // Bonus điểm nếu từ khóa khớp chính xác (whole word match)
          if (lowerInput.split(' ').contains(lowerKeyword)) {
            keywordScore *= 1.3;
          }
          
          score += keywordScore;
        }
      }
      
      if (score > 0) {
        intentScores[intent] = score;
      }
    }
    
    // Trả về intent có điểm cao nhất
    if (intentScores.isNotEmpty) {
      final bestIntent = intentScores.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      return bestIntent;
    }
    
    return 'fallback';
  }

  /// Phân tích category từ input của người dùng
  /// Lấy response template ngẫu nhiên
  String getRandomResponse(String templateKey, {String? habitName}) {
    final templates = _responseTemplates[templateKey] ?? _responseTemplates['fallback']!;
    String response = templates[_random.nextInt(templates.length)];
    
    if (habitName != null) {
      response = response.replaceAll('{habit_name}', habitName);
    }
    
    return response;
  }

  /// Xử lý input từ người dùng và trả về response - chỉ navigation
  Future<ChatbotResponse> processInput(String input) async {
    if (input.trim().isEmpty) {
      return ChatbotResponse.textOnly(getRandomResponse('fallback'));
    }
    
    final intent = analyzeIntent(input);
    
    switch (intent) {
      case 'open_habit_schedule':
        return ChatbotResponse.withAction(
          message: 'Đang mở lịch trình thói quen hôm nay...',
          actionType: ChatbotActionType.navigateToHabitSchedule,
        );
      
      case 'open_statistics':
        return ChatbotResponse.withAction(
          message: 'Đang mở trang thống kê...',
          actionType: ChatbotActionType.navigateToStatistics,
        );
      
      case 'open_all_habits':
        return ChatbotResponse.withAction(
          message: 'Đang mở trang chủ với tất cả thói quen...',
          actionType: ChatbotActionType.navigateToAllHabits,
        );
      
      case 'open_settings':
        return ChatbotResponse.withAction(
          message: 'Đang mở trang cài đặt...',
          actionType: ChatbotActionType.navigateToSettings,
        );
      
      case 'help':
        return ChatbotResponse.textOnly(getRandomResponse('help'));
      
      default:
        return ChatbotResponse.textOnly(getRandomResponse('fallback'));
    }
  }
}