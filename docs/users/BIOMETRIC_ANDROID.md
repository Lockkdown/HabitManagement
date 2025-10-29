# 🔐 Chức năng Sinh trắc học (Biometric Login) - Android

**Phiên bản**: local_auth ^3.0.0 (cập nhật mới nhất từ pub.dev)

**Tác giả**: Flutter.dev

**Ngày cập nhật**: Oct 2025

---

## 📋 Mục lục

1. [Tổng quan](#tổng-quan)
2. [Flow hoạt động](#flow-hoạt-động)
3. [Cấu hình Android](#cấu-hình-android)
4. [Triển khai Frontend](#triển-khai-frontend)
5. [Triển khai Backend](#triển-khai-backend)
6. [Xử lý lỗi](#xử-lý-lỗi)
7. [Bảo mật](#bảo-mật)

---

## 🎯 Tổng quan

### Định nghĩa

Sinh trắc học (Biometric Authentication) là phương pháp xác thực người dùng bằng các đặc điểm sinh học độc nhất như:
- **Vân tay** (Fingerprint)
- **Khuôn mặt** (Face Recognition)
- **Mã PIN / Mẫu** (Passcode / Pattern) - fallback

### Lợi ích

- ✅ **Nhanh chóng**: Không cần nhập mật khẩu
- ✅ **An toàn**: Dữ liệu sinh trắc học không rời khỏi thiết bị
- ✅ **Tiện lợi**: Trải nghiệm người dùng tốt hơn
- ✅ **Tuân thủ**: Hỗ trợ các tiêu chuẩn bảo mật hiện đại

### Yêu cầu tối thiểu

- **Android SDK**: API 24+ (Android 7.0)
- **Thiết bị**: Có cảm biến sinh trắc học (vân tay hoặc khuôn mặt)
- **Người dùng**: Đã đăng ký ít nhất 1 phương pháp sinh trắc học trong cài đặt hệ thống

---

## 🔄 Flow hoạt động

### Sơ đồ tổng quát

```
Mở App
  ↓
┌─────────────────────────────────┐
│ Kiểm tra:                       │
│ 1. Có refresh token?            │
│ 2. Biometric enabled?           │
│ 3. Thiết bị hỗ trợ?             │
└─────────────────────────────────┘
  ↓
┌──────────────────┬──────────────────┐
│ Cả 3 đúng        │Thiếu 1 hoặc nhiều│
├──────────────────┼──────────────────┤
│ Hiển thị         │ Hiển thị         │
│ Biometric Prompt │ Login Screen     │
└──────────────────┴──────────────────┘
  ↓
┌──────────────────────────────────┐
│ Người dùng xác thực sinh trắc học│
└──────────────────────────────────┘
  ↓
┌──────────────────┬──────────────────┐
│ Thành công       │ Thất bại / Hủy   │
├──────────────────┼──────────────────┤
│ Gọi API refresh  │ Quay lại Login   │
│ Lưu token        │ Screen           │
│ Chuyển Home      │                  │
└──────────────────┴──────────────────┘
```

### Chi tiết luồng

1. **Khởi động**: App kiểm tra trạng thái đăng nhập
2. **Quyết định**: Nếu có refresh token + biometric enabled → hiển thị biometric prompt
3. **Xác thực**: Người dùng quét vân tay/khuôn mặt
4. **Refresh Token**: Gọi API `/api/auth/refresh` để lấy access token mới
5. **Lưu & Chuyển**: Lưu token, cập nhật state, chuyển đến Home Screen

---

## ⚙️ Cấu hình Android

### 1. Cập nhật MainActivity

**File**: `android/app/src/main/kotlin/com/example/habit_management/MainActivity.kt`

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    // Chỉ cần kế thừa từ FlutterFragmentActivity
}
```

### 2. Cập nhật AndroidManifest.xml

**File**: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.habit_management">

    <!-- Thêm permission sinh trắc học -->
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />

    <application
        android:label="Habit Management"
        android:icon="@mipmap/ic_launcher">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### 3. Cập nhật Theme (styles.xml)

**File**: `android/app/src/main/res/values/styles.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- LaunchTheme phải kế thừa từ Theme.AppCompat -->
    <style name="LaunchTheme" parent="Theme.AppCompat.DayNight">
        <item name="android:windowNoTitle">true</item>
        <item name="android:windowActionBar">false</item>
        <item name="android:windowFullscreen">false</item>
        <item name="android:windowDrawsSystemBarBackgrounds">false</item>
    </style>

    <!-- NormalTheme cũng phải kế thừa từ Theme.AppCompat -->
    <style name="NormalTheme" parent="Theme.AppCompat.DayNight">
        <item name="android:windowNoTitle">true</item>
        <item name="android:windowActionBar">false</item>
        <item name="android:windowFullscreen">false</item>
        <item name="android:windowDrawsSystemBarBackgrounds">false</item>
    </style>
</resources>
```

### 4. Cập nhật pubspec.yaml

**File**: `frontend/pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Biometric authentication
  local_auth: ^3.0.0
  local_auth_android: ^1.0.0
  
  # Secure storage cho refresh token
  flutter_secure_storage: ^9.2.4
  
  # Các dependencies khác
  flutter_riverpod: ^3.0.3
  http: ^1.5.0
```

**Cài đặt**:
```bash
cd frontend
flutter pub get
```

---

## 💻 Triển khai Frontend

### 1. Tạo BiometricService

**File**: `frontend/lib/services/biometric_service.dart`

```dart
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Kiểm tra thiết bị có hỗ trợ sinh trắc học không
  Future<bool> canUseBiometric() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } catch (e) {
      print('Lỗi kiểm tra sinh trắc học: $e');
      return false;
    }
  }

  /// Lấy danh sách sinh trắc học có sẵn trên thiết bị
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();
      return availableBiometrics;
    } catch (e) {
      print('Lỗi lấy danh sách sinh trắc học: $e');
      return [];
    }
  }

  /// Xác thực sinh trắc học (chỉ sinh trắc học)
  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Xác thực để đăng nhập vào Habit Management',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Xác thực sinh trắc học',
            cancelButton: 'Hủy',
            biometricHint: 'Sử dụng vân tay hoặc khuôn mặt để đăng nhập',
          ),
        ],
      );
      return didAuthenticate;
    } catch (e) {
      print('Lỗi xác thực sinh trắc học: $e');
      return false;
    }
  }

  /// Xác thực với fallback (PIN/Pattern)
  Future<bool> authenticateWithFallback() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Xác thực để đăng nhập vào Habit Management',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Xác thực',
            cancelButton: 'Hủy',
            biometricHint: 'Sử dụng vân tay hoặc khuôn mặt',
          ),
        ],
      );
      return didAuthenticate;
    } catch (e) {
      print('Lỗi xác thực: $e');
      return false;
    }
  }
}
```

### 2. Mở rộng StorageService

**File**: `frontend/lib/services/storage_service.dart` (thêm)

```dart
/// Lưu trạng thái bật/tắt sinh trắc học
Future<void> setBiometricEnabled(bool enabled) async {
  await _secureStorage.write(
    key: 'biometric_enabled',
    value: enabled.toString(),
  );
}

/// Kiểm tra sinh trắc học có được bật không
Future<bool> isBiometricEnabled() async {
  final value = await _secureStorage.read(key: 'biometric_enabled');
  return value == 'true';
}

/// Xóa trạng thái sinh trắc học
Future<void> removeBiometricEnabled() async {
  await _secureStorage.delete(key: 'biometric_enabled');
}
```

### 3. Mở rộng AuthProvider

**File**: `frontend/lib/services/auth_provider.dart` (thêm)

```dart
/// Đăng nhập bằng sinh trắc học
Future<bool> biometricLogin() async {
  try {
    // Kiểm tra refresh token
    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken == null) {
      return false;
    }

    // Xác thực sinh trắc học
    final biometricService = BiometricService();
    final isAuthenticated = await biometricService.authenticate();
    if (!isAuthenticated) {
      state = AuthState.unauthenticated(
        errorMessage: 'Xác thực sinh trắc học thất bại',
      );
      return false;
    }

    // Gọi API refresh token
    final authResponse = await _authApiService.refreshToken(refreshToken);
    await _storageService.saveAccessToken(authResponse.accessToken);
    state = AuthState.authenticated(authResponse.user);
    return true;
  } catch (e) {
    state = AuthState.unauthenticated(errorMessage: e.toString());
    return false;
  }
}

/// Bật sinh trắc học
Future<bool> enableBiometric() async {
  try {
    final biometricService = BiometricService();
    final canUseBiometric = await biometricService.canUseBiometric();
    if (!canUseBiometric) {
      return false;
    }
    await _storageService.setBiometricEnabled(true);
    return true;
  } catch (e) {
    return false;
  }
}

/// Tắt sinh trắc học
Future<void> disableBiometric() async {
  try {
    await _storageService.setBiometricEnabled(false);
  } catch (e) {
    print('Lỗi tắt sinh trắc học: $e');
  }
}
```

### 4. Cập nhật Splash Screen

**File**: `frontend/lib/screens/splash_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_provider.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeApp(context, ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (authState.status == AuthStatus.authenticated) {
              return const HomeScreen();
            } else {
              return const LoginScreen();
            }
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Đang tải...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _initializeApp(BuildContext context, WidgetRef ref) async {
    final authNotifier = ref.read(authProvider.notifier);
    final storageService = ref.read(storageServiceProvider);

    try {
      final refreshToken = await storageService.getRefreshToken();
      final biometricEnabled = await storageService.isBiometricEnabled();

      if (refreshToken != null && biometricEnabled) {
        await authNotifier.biometricLogin();
      } else {
        await authNotifier._checkAuthStatus();
      }
    } catch (e) {
      print('Lỗi khởi tạo: $e');
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }
}
```

---

## 🔧 Triển khai Backend

### Thêm Endpoint Refresh Token

**File**: `backend/Controllers/AuthController.cs`

```csharp
[HttpPost("refresh")]
public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
{
    try
    {
        if (string.IsNullOrEmpty(request.RefreshToken))
        {
            return BadRequest(new { message = "Refresh token không được để trống" });
        }

        var authResponse = await _authService.RefreshTokenAsync(request.RefreshToken);
        return Ok(authResponse);
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Lỗi refresh token");
        return StatusCode(500, new { message = "Có lỗi xảy ra" });
    }
}
```

### Thêm Method trong AuthService

**File**: `backend/Services/AuthService.cs`

```csharp
public async Task<AuthResponseDto> RefreshTokenAsync(string refreshToken)
{
    var principal = _jwtTokenService.GetPrincipalFromExpiredToken(refreshToken);
    if (principal == null)
        throw new Exception("Refresh token không hợp lệ");

    var userId = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    var user = await _userManager.FindByIdAsync(userId);
    if (user == null)
        throw new Exception("User không tồn tại");

    var newAccessToken = _jwtTokenService.GenerateAccessToken(user);
    var newRefreshToken = _jwtTokenService.GenerateRefreshToken();

    return new AuthResponseDto
    {
        AccessToken = newAccessToken,
        RefreshToken = newRefreshToken,
        User = new UserDto
        {
            UserId = user.Id,
            Username = user.UserName,
            Email = user.Email,
            FullName = user.FullName,
            ThemePreference = user.ThemePreference,
            LanguageCode = user.LanguageCode,
        }
    };
}
```

### Thêm DTO

**File**: `backend/Models/Dtos/RefreshTokenRequest.cs`

```csharp
public class RefreshTokenRequest
{
    public string RefreshToken { get; set; }
}
```

---

## ⚠️ Xử lý lỗi

| Lỗi | Nguyên nhân | Giải pháp |
|-----|-----------|----------|
| `noBiometricHardware` | Thiết bị không có cảm biến | Hiển thị login screen |
| `noBiometricEnrolled` | Chưa đăng ký sinh trắc học | Hướng dẫn đăng ký |
| `biometricLockout` | Xác thực thất bại quá nhiều | Chờ hoặc dùng PIN |
| `userCanceled` | Người dùng hủy | Quay lại login screen |

---

## 🔒 Bảo mật

- ✅ Refresh token lưu trong `flutter_secure_storage` (mã hóa)
- ✅ Access token có thời gian hết hạn ngắn (30 phút)
- ✅ Dữ liệu sinh trắc học không rời khỏi thiết bị
- ✅ Xác thực 2 lớp: Sinh trắc học + Refresh Token
