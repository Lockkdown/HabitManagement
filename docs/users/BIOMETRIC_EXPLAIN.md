# 🔐 Giải thích Chi tiết Chức năng Sinh Trắc học (Biometric)

## 📋 Mục lục
1. [Định nghĩa & Packages](#định-nghĩa--packages)
2. [Flow Hoạt động](#flow-hoạt-động)
3. [Frontend Implementation](#frontend-implementation)
4. [Backend Implementation](#backend-implementation)
5. [Security Considerations](#security-considerations)

---

## 📦 Định nghĩa & Packages

### Sinh Trắc học là gì?

**Sinh trắc học (Biometric)** = Xác thực dùng **vân tay** hoặc **khuôn mặt** thay vì nhập password

```
❌ Cách cũ: Email + Password
✅ Cách mới: Vân tay / Khuôn mặt (Quick Login)
```

### Frontend Packages

| Package | Phiên bản | Mục đích |
|---------|----------|---------|
| **local_auth** | ^3.0.0 | ✅ **Gọi API sinh trắc học** |
| **local_auth_android** | ^2.0.0 | ✅ **Android-specific implementation** |
| **flutter_secure_storage** | ^9.2.4 | Lưu refresh token |

### Backend Packages

**Không cần package đặc biệt!**
- Backend chỉ cần verify **refresh token** (JWT)
- Sinh trắc học là việc của **frontend** (xác thực với OS)

---

## 🔄 Flow Hoạt động

### 📊 Diagram Tổng Quát

```
┌─────────────────────────────────────────────────────────────────┐
│                    FRONTEND (Flutter)                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. App khởi động (SplashScreen)                                │
│     ↓                                                             │
│  2. Check: Có refresh token + biometric enabled?                │
│     ↓                                                             │
│  3. Nếu YES → Show "Đăng nhập bằng vân tay" button             │
│     ↓                                                             │
│  4. User nhấn button → Gọi BiometricService.authenticate()      │
│     ↓                                                             │
│  5. OS hiển thị dialog xác thực (vân tay/khuôn mặt)            │
│     ↓                                                             │
│  6. User quét vân tay / khuôn mặt                              │
│     ↓                                                             │
│  7. OS verify → Return true/false                               │
│     ↓                                                             │
│  8. Nếu true → Gọi API refresh token                           │
│     ↓                                                             │
│  9. Backend verify refresh token → Return access token mới      │
│     ↓                                                             │
│  10. Frontend lưu access token mới                              │
│      ↓                                                             │
│  11. Navigate to HomeScreen                                     │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎯 Frontend Implementation

### Step 1: BiometricService - Gọi OS API

**File**: `services/biometric_service.dart`

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
      return false;
    }
  }

  /// Lấy danh sách sinh trắc học có sẵn
  /// VD: [BiometricType.fingerprint, BiometricType.face]
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();
      return availableBiometrics;
    } catch (e) {
      return [];
    }
  }

  /// Xác thực sinh trắc học (chỉ sinh trắc học, không cho phép PIN)
  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Xác thực để đăng nhập vào Habit Management',
        biometricOnly: true,  // ← Chỉ sinh trắc học, không PIN
        persistAcrossBackgrounding: true,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Xác thực sinh trắc học',
            cancelButton: 'Hủy',
          ),
        ],
      );
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// Xác thực với fallback (cho phép PIN nếu sinh trắc học thất bại)
  Future<bool> authenticateWithFallback() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Xác thực để đăng nhập vào Habit Management',
        biometricOnly: false,  // ← Cho phép PIN fallback
        persistAcrossBackgrounding: true,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Xác thực',
            cancelButton: 'Hủy',
          ),
        ],
      );
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// Kiểm tra có sinh trắc học nào được đăng ký không
  Future<bool> hasBiometricEnrolled() async {
    try {
      final List<BiometricType> availableBiometrics =
          await getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
```

**Giải thích**:
- `LocalAuthentication` - Class từ `local_auth` package
- `canCheckBiometrics` - Check xem thiết bị có cảm biến sinh trắc học
- `authenticate()` - Gọi OS dialog để xác thực
- `biometricOnly: true` - Chỉ dùng sinh trắc học (không PIN)

---

### Step 2: StorageService - Lưu trạng thái Biometric

**File**: `services/storage_service.dart` (Lines 100-112)

```dart
/// Lưu trạng thái bật/tắt sinh trắc học
Future<void> setBiometricEnabled(bool enabled) async {
  await _storage.write(
    key: _biometricEnabledKey,
    value: enabled.toString(),
  );
}

/// Kiểm tra xem sinh trắc học đã được bật chưa
Future<bool> isBiometricEnabled() async {
  final value = await _storage.read(key: _biometricEnabledKey);
  return value == 'true';
}
```

**Giải thích**:
- `_biometricEnabledKey = 'biometric_enabled'` - Key lưu trạng thái
- Lưu vào `FlutterSecureStorage` (encrypted)
- Trả về `true/false`

---

### Step 3: AuthProvider - Biometric Login Logic

**File**: `services/auth_provider.dart` (Lines 192-239)

```dart
/// Đăng nhập bằng sinh trắc học
Future<bool> biometricLogin() async {
  try {
    print('AuthProvider: Bắt đầu đăng nhập sinh trắc học');
    
    // Bước 1: Kiểm tra có refresh token không
    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken == null) {
      print('AuthProvider: Không có refresh token');
      return false;
    }

    // Bước 2: Xác thực sinh trắc học
    final biometricService = BiometricService();
    final isAuthenticated = await biometricService.authenticate();
    
    if (!isAuthenticated) {
      print('AuthProvider: Xác thực sinh trắc học thất bại');
      state = AuthState.unauthenticated(
        errorMessage: 'Xác thực sinh trắc học thất bại',
      );
      return false;
    }

    // Bước 3: Gọi API refresh token
    print('AuthProvider: Gọi API refresh token');
    final authResponse = await _authApiService.refreshToken(refreshToken);

    // Bước 4: Lưu access token mới
    await _storageService.saveAccessToken(authResponse.accessToken);
    
    // Cập nhật refresh token nếu có token mới từ server
    if (authResponse.refreshToken.isNotEmpty) {
      await _storageService.saveRefreshToken(authResponse.refreshToken);
    }

    // Bước 5: Cập nhật state
    state = AuthState.authenticated(authResponse.user);
    print('AuthProvider: Đăng nhập sinh trắc học thành công');
    return true;
  } catch (e) {
    print('AuthProvider: Lỗi đăng nhập sinh trắc học: $e');
    state = AuthState.unauthenticated(
      errorMessage: 'Lỗi: ${e.toString()}',
    );
    return false;
  }
}

/// Bật sinh trắc học (sau khi đăng nhập thành công)
Future<bool> enableBiometric() async {
  try {
    final biometricService = BiometricService();
    
    // Kiểm tra thiết bị có hỗ trợ không
    final canUseBiometric = await biometricService.canUseBiometric();
    if (!canUseBiometric) {
      print('AuthProvider: Thiết bị không hỗ trợ sinh trắc học');
      return false;
    }

    // Kiểm tra có sinh trắc học nào được đăng ký không
    final hasBiometric = await biometricService.hasBiometricEnrolled();
    if (!hasBiometric) {
      print('AuthProvider: Chưa đăng ký sinh trắc học trong cài đặt');
      return false;
    }

    // Lưu trạng thái
    await _storageService.setBiometricEnabled(true);
    print('AuthProvider: Đã bật sinh trắc học');
    return true;
  } catch (e) {
    print('AuthProvider: Lỗi bật sinh trắc học: $e');
    return false;
  }
}

/// Tắt sinh trắc học
Future<void> disableBiometric() async {
  try {
    await _storageService.setBiometricEnabled(false);
    print('AuthProvider: Đã tắt sinh trắc học');
  } catch (e) {
    print('AuthProvider: Lỗi tắt sinh trắc học: $e');
  }
}
```

**Giải thích từng bước**:

| Bước | Giải thích |
|------|-----------|
| 1 | Lấy refresh token từ storage |
| 2 | Gọi `biometricService.authenticate()` → OS dialog |
| 3 | Nếu xác thực thành công → Gọi API refresh token |
| 4 | Backend verify refresh token → Return access token mới |
| 5 | Lưu access token mới + cập nhật state |

---

### Step 4: LoginScreen - UI & Logic

**File**: `screens/login_screen.dart` (Lines 44-154)

```dart
class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _biometricEnabled = false;
  bool _isQuickLogin = false;
  String? _savedUsername;

  @override
  void initState() {
    super.initState();
    _checkLoginMode();
  }

  /// Kiểm tra chế độ đăng nhập (Quick Login hay Full Login)
  Future<void> _checkLoginMode() async {
    final storageService = StorageService();
    
    // Kiểm tra có refresh token không
    final refreshToken = await storageService.getRefreshToken();
    
    // Kiểm tra có username không
    final username = await storageService.getUsername();
    
    // Kiểm tra sinh trắc học có bật không
    final biometricEnabled = await storageService.isBiometricEnabled();
    
    if (mounted) {
      setState(() {
        // Quick Login nếu có refresh token VÀ có username
        _isQuickLogin = refreshToken != null && username != null;
        _savedUsername = username;
        _biometricEnabled = biometricEnabled;
      });
    }
  }

  /// Xử lý đăng nhập bằng sinh trắc học
  Future<void> _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi biometricLogin từ AuthProvider
      final success = await ref.read(authProvider.notifier).biometricLogin();

      if (!mounted) return;

      if (success) {
        AppNotification.showSuccess(context, 'Đăng nhập thành công!');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        AppNotification.showError(context, 'Đăng nhập thất bại');
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nếu Quick Login + Biometric enabled → Show biometric button
    if (_isQuickLogin && _biometricEnabled) {
      return Scaffold(
        body: Column(
          children: [
            Text('Xin chào, $_savedUsername'),
            ElevatedButton(
              onPressed: _handleBiometricLogin,
              child: Text('Đăng nhập bằng vân tay'),
            ),
            TextButton(
              onPressed: _switchToFullLogin,
              child: Text('Đăng nhập tài khoản khác'),
            ),
          ],
        ),
      );
    }
    
    // Nếu Full Login → Show email + password fields
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: !_obscurePassword,
            ),
            ElevatedButton(
              onPressed: _handleLogin,
              child: Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔧 Backend Implementation

### Backend không cần gì đặc biệt!

**Tại sao?**
- Sinh trắc học là **frontend-only** feature
- Backend chỉ cần verify **refresh token** (JWT)
- Không cần thêm package hoặc logic

### Endpoint Refresh Token

**File**: `controllers/AuthController.cs`

```csharp
[HttpPost("refresh-token")]
public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
{
    try {
        var response = await _authService.RefreshTokenAsync(request.RefreshToken);
        return Ok(response);
    } catch (Exception ex) {
        return Unauthorized(new { message = "Refresh token không hợp lệ" });
    }
}
```

**Frontend gọi**:
```dart
final authResponse = await _authApiService.refreshToken(refreshToken);
```

---

## 🎯 Các Scenarios

### Scenario 1: User đăng nhập lần đầu (Full Login)

```
1. User nhập email + password
2. Backend verify → Return access token + refresh token
3. Frontend lưu tokens
4. Frontend hiển thị: "Bật sinh trắc học?"
5. User nhấn "Bật"
6. Frontend check thiết bị có hỗ trợ + có sinh trắc học đăng ký
7. Frontend lưu: biometric_enabled = true
8. Navigate to HomeScreen
```

### Scenario 2: User quay lại app (Quick Login)

```
1. App khởi động
2. Check: Có refresh token? YES
3. Check: Có username? YES
4. Check: biometric_enabled? YES
5. Show: "Xin chào, [username]"
6. Show: "Đăng nhập bằng vân tay" button
7. User nhấn button
8. BiometricService.authenticate() → OS dialog
9. User quét vân tay
10. OS verify → Return true
11. Frontend gọi API refresh token
12. Backend verify refresh token → Return access token mới
13. Frontend lưu access token mới
14. Navigate to HomeScreen
```

### Scenario 3: Sinh trắc học thất bại

```
1. User quét vân tay
2. OS verify → Return false (vân tay sai)
3. BiometricService.authenticate() → Return false
4. Frontend show error: "Xác thực sinh trắc học thất bại"
5. User có thể:
   - Thử lại
   - Đăng nhập bằng email + password
```

---

## 🛡️ Security Considerations

### 1. Refresh Token là chìa khóa

```dart
// Refresh token được lưu ở storage (encrypted)
final refreshToken = await _storageService.getRefreshToken();

// Nếu refresh token bị leak → Attacker có thể đăng nhập
// Vì vậy refresh token phải được bảo vệ tốt
```

### 2. Sinh trắc học không thay thế password

```
❌ KHÔNG: Lưu password ở storage
✅ LÀM: Lưu refresh token (JWT) ở storage

Sinh trắc học chỉ là cách để:
- Unlock device
- Verify user là chủ device
- Gọi API refresh token
```

### 3. Biometric chỉ hoạt động trên device

```dart
// Sinh trắc học không thể hoạt động trên web
// Chỉ hoạt động trên mobile (Android/iOS)

// Kiểm tra thiết bị có hỗ trợ
final canUseBiometric = await biometricService.canUseBiometric();
if (!canUseBiometric) {
  // Không hỗ trợ → Disable biometric feature
}
```

### 4. Fallback mechanism

```dart
// Nếu sinh trắc học thất bại → User có thể dùng PIN/Pattern
final isAuthenticated = await biometricService.authenticateWithFallback();
```

---

## 📊 So sánh: Full Login vs Quick Login

| Thuộc tính | Full Login | Quick Login |
|-----------|-----------|-----------|
| **Lần đầu** | ✅ Bắt buộc | ❌ Không có |
| **Lần sau** | ❌ Không cần | ✅ Nếu bật |
| **Input** | Email + Password | Vân tay / Khuôn mặt |
| **Lưu ở storage** | Không | Refresh token (encrypted) |
| **Backend call** | POST /login | POST /refresh-token |
| **Thời gian** | Lâu | Nhanh (chỉ refresh token) |

---

## 🎓 Khi demo:

**Q: "Sinh trắc học là gì?"**
A: Xác thực dùng vân tay/khuôn mặt thay vì nhập password

**Q: "Tại sao cần sinh trắc học?"**
A: Nhanh hơn, tiện hơn, bảo mật hơn (không cần nhập password)

**Q: "Nếu sinh trắc học thất bại sao?"**
A: User có thể dùng PIN/Pattern hoặc đăng nhập bằng email + password

**Q: "Backend cần gì?"**
A: Không cần gì đặc biệt - chỉ verify refresh token (JWT)

**Q: "Refresh token được lưu ở đâu?"**
A: FlutterSecureStorage (encrypted) - an toàn

**Q: "Nếu refresh token bị leak sao?"**
A: Attacker có thể đăng nhập - vì vậy phải bảo vệ tốt

---

## 📝 Tóm tắt

| Khái niệm | Giải thích |
|----------|-----------|
| **Sinh trắc học** | Xác thực bằng vân tay / khuôn mặt |
| **Quick Login** | Đăng nhập nhanh dùng sinh trắc học |
| **Full Login** | Đăng nhập thường dùng email + password |
| **Refresh token** | Dùng để lấy access token mới |
| **BiometricService** | Gọi OS API để xác thực |
| **StorageService** | Lưu refresh token (encrypted) |
| **AuthProvider** | Quản lý logic đăng nhập |

---

**Tạo bởi**: Cascade AI
**Ngày**: Oct 30, 2025
**Phiên bản**: 1.0
