import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'themes/app_theme.dart';
import 'services/auth_provider.dart';
import 'services/auth_state.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

/// Hàm main - Entry point của ứng dụng
void main() async {
  // Đảm bảo Flutter bindings được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // Load file .env
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: Không thể load file .env: $e');
  }

  // Chạy app với ProviderScope (Riverpod)
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// Widget gốc của ứng dụng
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Management',
      debugShowCheckedModeBanner: false,
      
      // Localization support (để DatePicker và các widget khác hỗ trợ tiếng Việt)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'), // Tiếng Việt
        Locale('en', 'US'), // Tiếng Anh
      ],
      locale: const Locale('vi', 'VN'), // Mặc định tiếng Việt
      
      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Mặc định Light mode
      
      // Màn hình khởi động
      home: const AppInitializer(),
    );
  }
}

/// Widget khởi tạo app, kiểm tra trạng thái đăng nhập
class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Chờ một chút để hiển thị splash screen
    Future.delayed(const Duration(seconds: 2), () {
      // AuthProvider sẽ tự động check auth status khi được khởi tạo
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Hiển thị màn hình tương ứng với trạng thái
    return switch (authState.status) {
      AuthStatus.initial || AuthStatus.loading =>
        // Đang kiểm tra hoặc đang loading - hiển thị splash
        const SplashScreen(),
        
      AuthStatus.authenticated =>
        // Đã đăng nhập - chuyển đến home
        const HomeScreen(),
        
      AuthStatus.unauthenticated =>
        // Chưa đăng nhập - chuyển đến login
        const LoginScreen(),
    };
  }
}
