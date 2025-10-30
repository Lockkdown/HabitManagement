enum ChatbotActionType {
  none,
  navigateToHabitSchedule,  // Mở lịch thói quen hôm nay
  navigateToStatistics,     // Mở thống kê thói quen
  navigateToAllHabits,      // Mở danh mục tất cả thói quen (home_screen)
  navigateToSettings,       // Mở cài đặt
  createHabit,             // Tạo thói quen
  editHabit,               // Sửa thói quen
  deleteHabit,             // Xóa thói quen
}

class ChatbotResponse {
  final String message;
  final ChatbotActionType actionType;
  final Map<String, dynamic>? actionData;

  ChatbotResponse({
    required this.message,
    this.actionType = ChatbotActionType.none,
    this.actionData,
  });

  factory ChatbotResponse.textOnly(String message) {
    return ChatbotResponse(message: message);
  }

  factory ChatbotResponse.withAction({
    required String message,
    required ChatbotActionType actionType,
    Map<String, dynamic>? actionData,
  }) {
    return ChatbotResponse(
      message: message,
      actionType: actionType,
      actionData: actionData,
    );
  }
}