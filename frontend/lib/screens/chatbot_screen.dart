import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../services/chatbot_service.dart';
import '../services/storage_service.dart';
import '../models/chatbot_response_model.dart';
import '../screens/statistics_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/habit_schedule_screen.dart';
import '../screens/home_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final List<ChatMessage> _messages = [];
  
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';
  
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _textController = TextEditingController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _addWelcomeMessage();
    
    // Add listener to text controller for send button state
    _textController.addListener(() {
      setState(() {
        // This will trigger rebuild of send button when text changes
      });
    });
  }

  void _initSpeech() async {
    try {
      _speech = stt.SpeechToText();
      _speechEnabled = await _speech.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
          setState(() {
            _isListening = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi nhận diện giọng nói: ${error.errorMsg}')),
          );
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
      
      print('Speech initialized: $_speechEnabled');
      
      if (!_speechEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể khởi tạo tính năng nhận diện giọng nói')),
        );
      }
    } catch (e) {
      print('Error initializing speech: $e');
      _speechEnabled = false;
    }
    
    setState(() {});
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      text: 'Xin chào! Tôi là trợ lý AI của bạn. Tôi có thể giúp bạn điều hướng:\n\n'
          '• Xem thói quen hôm nay\n'
          '• Xem tất cả thói quen\n'
          '• Mở thống kê\n'
          '• Mở cài đặt\n\n'
          'Bạn có thể nói hoặc gõ tin nhắn để tương tác với tôi!',
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.insert(0, welcomeMessage);
    });
  }

  void _handleSendPressed(String text) async {
    if (text.trim().isEmpty) return;
    
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, userMessage);
    });

    // Clear the text field
    _textController.clear();

    // Process the message with chatbot service
    await _processUserMessage(text);
  }

  Future<void> _processUserMessage(String userInput) async {
    try {
      // Show typing indicator
      _addTypingMessage();

      // Process the input
      final response = await _chatbotService.processInput(userInput);

      // Remove typing indicator
      _removeTypingMessage();

      // Add bot response
      final botMessage = ChatMessage(
        text: response.message,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.insert(0, botMessage);
      });
      
      // Xử lý navigation action nếu có
      if (response.actionType != null) {
        await _handleNavigationAction(response.actionType!, response.actionData);
      }

    } catch (e) {
      _removeTypingMessage();
      
      final errorMessage = ChatMessage(
        text: 'Xin lỗi, tôi gặp lỗi khi xử lý yêu cầu của bạn. Vui lòng thử lại.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.insert(0, errorMessage);
      });
    }
  }
  
  Future<void> _handleNavigationAction(ChatbotActionType actionType, Map<String, dynamic>? actionData) async {
    // Delay một chút để user có thể đọc message
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    switch (actionType) {
      case ChatbotActionType.navigateToAllHabits:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
        
      case ChatbotActionType.navigateToStatistics:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const StatisticsScreen()),
        );
        break;
        
      case ChatbotActionType.navigateToSettings:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
        
      case ChatbotActionType.navigateToHabitSchedule:
        try {
          final storageService = StorageService();
          final userId = await storageService.getUserId();
          if (userId != null) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => HabitScheduleScreen(userId: userId)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể lấy thông tin người dùng')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Có lỗi xảy ra khi mở lịch trình')),
          );
        }
        break;
        
      case ChatbotActionType.none:
        // Không cần làm gì
        break;
        
      default:
        // Các action khác không được hỗ trợ
        break;
    }
  }

  void _addTypingMessage() {
    setState(() {
      _isTyping = true;
    });
  }

  void _removeTypingMessage() {
    setState(() {
      _isTyping = false;
    });
  }

  void _startListening() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cần quyền truy cập microphone để sử dụng tính năng này'),
          ),
        );
        return;
      }

      if (!_speechEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tính năng nhận diện giọng nói chưa sẵn sàng'),
          ),
        );
        return;
      }

      if (!_isListening) {
        setState(() {
          _isListening = true;
          _lastWords = '';
        });
        
        bool available = await _speech.listen(
          onResult: (result) {
            setState(() {
              _lastWords = result.recognizedWords;
            });
            
            if (result.finalResult) {
              _handleSpeechResult(_lastWords);
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          localeId: 'vi_VN', // Vietnamese locale
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );
        
        if (!available) {
          setState(() {
            _isListening = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể bắt đầu nhận diện giọng nói')),
          );
        }
      }
    } catch (e) {
      print('Error starting speech recognition: $e');
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi bắt đầu nhận diện giọng nói: $e')),
      );
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  void _handleSpeechResult(String recognizedWords) {
    if (recognizedWords.isNotEmpty) {
      _handleSendPressed(recognizedWords);
    }
  }

  Widget _buildSpeechButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () {
          print('Speech button tapped. Enabled: $_speechEnabled, Listening: $_isListening');
          if (_speechEnabled) {
            if (_isListening) {
              _stopListening();
            } else {
              _startListening();
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tính năng nhận diện giọng nói chưa sẵn sàng. Hãy thử khởi động lại ứng dụng.'),
              ),
            );
          }
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: !_speechEnabled 
                ? Colors.grey
                : _isListening 
                    ? Colors.red.withOpacity(0.8)
                    : Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: _isListening
                ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            !_speechEnabled 
                ? Icons.mic_off
                : _isListening 
                    ? Icons.mic 
                    : Icons.mic_none,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  // Modern ChatGPT-style speech button
  Widget _buildModernSpeechButton() {
    return GestureDetector(
      onTap: () {
        print('Modern speech button tapped. Enabled: $_speechEnabled, Listening: $_isListening');
        if (_speechEnabled) {
          if (_isListening) {
            _stopListening();
          } else {
            _startListening();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tính năng nhận diện giọng nói chưa sẵn sàng. Hãy thử khởi động lại ứng dụng.'),
            ),
          );
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: !_speechEnabled 
              ? Colors.grey[600]
              : _isListening 
                  ? Colors.red.withOpacity(0.2)
                  : Colors.grey[600],
          borderRadius: BorderRadius.circular(20),
          border: _isListening 
              ? Border.all(color: Colors.red.withOpacity(0.5), width: 2)
              : null,
        ),
        child: Icon(
          !_speechEnabled 
              ? Icons.mic_off
              : _isListening 
                  ? Icons.mic 
                  : Icons.mic_none,
          color: !_speechEnabled 
              ? Colors.grey[400]
              : _isListening 
                  ? Colors.red
                  : Colors.grey[300],
          size: 20,
        ),
      ),
    );
  }

  // Modern ChatGPT-style send button
  Widget _buildModernSendButton() {
    final hasText = _textController.text.trim().isNotEmpty;
    
    return GestureDetector(
      onTap: hasText ? () => _handleSendPressed(_textController.text) : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: hasText ? Colors.white : Colors.grey[600],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.arrow_upward,
          color: hasText ? Colors.black : Colors.grey[400],
          size: 20,
        ),
      ),
    );
  }

  Widget _buildListeningIndicator() {
    if (!_isListening) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Đang nghe...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                if (_lastWords.isNotEmpty)
                  Text(
                    _lastWords,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _stopListening,
            icon: const Icon(Icons.stop, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.smart_toy, size: 16, color: Colors.blue),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? Colors.blue 
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.person, size: 16, color: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue[100],
            child: const Icon(Icons.smart_toy, size: 16, color: Colors.blue),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Đang xử lý',
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trợ lý Thói quen',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _messages.clear();
              });
              _addWelcomeMessage();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới cuộc trò chuyện',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildListeningIndicator(),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == 0) {
                  return _buildTypingIndicator();
                }
                
                final messageIndex = _isTyping ? index - 1 : index;
                final message = _messages[messageIndex];
                return _buildMessageBubble(message);
              },
            ),
          ),
          // ChatGPT-style input bar
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main input container
                  Container(
                    constraints: const BoxConstraints(
                      maxWidth: 768, // Giới hạn chiều rộng như ChatGPT
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.grey[600]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Microphone button
                        Container(
                          margin: const EdgeInsets.only(left: 12),
                          child: _buildModernSpeechButton(),
                        ),
                        // Text input field
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: 52,
                              maxHeight: 120, // Cho phép mở rộng khi text dài
                            ),
                            child: TextField(
                              controller: _textController,
                              maxLines: null, // Cho phép nhiều dòng
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.4,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Nhắn tin cho Trợ lý Thói quen...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              onSubmitted: (text) => _handleSendPressed(text),
                            ),
                          ),
                        ),
                        // Send button
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: _buildModernSendButton(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }
}