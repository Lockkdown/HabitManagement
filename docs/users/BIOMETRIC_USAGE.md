# 📱 Hướng dẫn Sử dụng Sinh trắc học

## 🎯 Tổng quan

Chức năng sinh trắc học cho phép bạn đăng nhập nhanh chóng bằng vân tay hoặc khuôn mặt thay vì nhập mật khẩu.

---

## ✅ Đã triển khai

### Backend (.NET 9.0)
- ✅ `POST /api/auth/refresh` - Endpoint refresh access token
- ✅ `RefreshTokenAsync()` - Method xử lý refresh token (JWT)
- ✅ `RefreshTokenRequest` DTO
- ✅ JWT Refresh Token với expiration 7 ngày

### Frontend (Flutter)
- ✅ `BiometricService` - Quản lý xác thực sinh trắc học
- ✅ `AuthProvider.biometricLogin()` - Đăng nhập bằng sinh trắc học
- ✅ `AuthProvider.enableBiometric()` - Bật sinh trắc học
- ✅ `AuthProvider.disableBiometric()` - Tắt sinh trắc học
- ✅ `StorageService` - Lưu trạng thái biometric enabled
- ✅ `AppInitializer` - Tự động kiểm tra và đăng nhập sinh trắc học khi mở app

### Android
- ✅ MainActivity → FlutterFragmentActivity
- ✅ Permission USE_BIOMETRIC
- ✅ Theme AppCompat.DayNight
- ✅ Dependencies: local_auth ^3.0.0, local_auth_android ^2.0.0

---

## 🚀 Cách sử dụng

### Bước 1: Đăng ký và đăng nhập lần đầu

1. Mở app và đăng ký tài khoản mới
2. Đăng nhập bằng email + mật khẩu

### Bước 2: Bật sinh trắc học (Cần implement UI)

**[TODO]** Cần thêm UI để người dùng bật/tắt sinh trắc học:

```dart
// Trong Settings Screen hoặc sau khi đăng nhập thành công
final authNotifier = ref.read(authProvider.notifier);

// Bật sinh trắc học
final success = await authNotifier.enableBiometric();

if (success) {
  // Hiển thị thông báo "Đã bật sinh trắc học"
} else {
  // Hiển thị thông báo "Thiết bị không hỗ trợ hoặc chưa đăng ký sinh trắc học"
}
```

### Bước 3: Đăng nhập lần sau

1. Mở app
2. App tự động kiểm tra:
   - Có refresh token?
   - Sinh trắc học đã được bật?
3. Nếu cả 2 điều kiện đúng → Hiển thị prompt sinh trắc học
4. Quét vân tay hoặc khuôn mặt
5. Đăng nhập thành công → Chuyển đến Home Screen

---

## 🔧 Cấu hình Backend

### Environment Variables (.env)

Đảm bảo file `.env` trong `backend/` có các biến sau:

```env
# JWT Configuration
JWT_SECRET_KEY=<32+ ký tự bảo mật>
JWT_ISSUER=HabitManagementAPI
JWT_AUDIENCE=HabitManagementClient
JWT_ACCESS_TOKEN_EXPIRATION_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRATION_DAYS=7
```

**Lưu ý**: Refresh token có expiration 7 ngày. Sau 7 ngày, người dùng phải đăng nhập lại bằng mật khẩu.

---

## 📱 Kiểm thử trên thiết bị thật

### Android

1. **Chuẩn bị thiết bị**:
   - Android 7.0+ (API 24+)
   - Đã đăng ký vân tay hoặc khuôn mặt trong Settings

2. **Chạy app**:
```bash
cd frontend
flutter run -d <device_id>
```

3. **Test flow**:
   - Đăng nhập lần đầu bằng email/password
   - Bật sinh trắc học (nếu đã có UI)
   - Đóng app
   - Mở lại app → Prompt sinh trắc học xuất hiện
   - Quét vân tay → Đăng nhập thành công

### Emulator (Không khuyến nghị)

Emulator Android có thể không hỗ trợ đầy đủ sinh trắc học. Nên test trên thiết bị thật.

---

## ⚠️ Xử lý lỗi

| Tình huống | Xử lý |
|-----------|-------|
| Thiết bị không hỗ trợ sinh trắc học | `enableBiometric()` trả về `false` |
| Chưa đăng ký sinh trắc học | `enableBiometric()` trả về `false` |
| Xác thực thất bại | Quay lại Login Screen |
| Refresh token hết hạn | Quay lại Login Screen |
| Người dùng hủy xác thực | Quay lại Login Screen |

---

## 📋 TODO - Các tính năng cần bổ sung

### 1. UI Settings để bật/tắt sinh trắc học

**File cần tạo**: `frontend/lib/screens/settings_screen.dart`

```dart
// Thêm Switch để bật/tắt sinh trắc học
SwitchListTile(
  title: const Text('Đăng nhập bằng sinh trắc học'),
  subtitle: const Text('Sử dụng vân tay hoặc khuôn mặt'),
  value: _biometricEnabled,
  onChanged: (value) async {
    if (value) {
      final success = await authNotifier.enableBiometric();
      if (success) {
        setState(() => _biometricEnabled = true);
        // Hiển thị snackbar thành công
      }
    } else {
      await authNotifier.disableBiometric();
      setState(() => _biometricEnabled = false);
    }
  },
)
```

### 2. Dialog hỏi bật sinh trắc học sau khi đăng nhập

**File cần sửa**: `frontend/lib/screens/login_screen.dart`

```dart
// Sau khi đăng nhập thành công
Future<void> _handleLoginSuccess() async {
  final biometricService = BiometricService();
  final canUse = await biometricService.canUseBiometric();
  
  if (canUse) {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bật sinh trắc học?'),
        content: const Text('Sử dụng vân tay/khuôn mặt để đăng nhập nhanh hơn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Có'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      await ref.read(authProvider.notifier).enableBiometric();
    }
  }
}
```

### 3. Kiểm tra thiết bị hỗ trợ sinh trắc học

**Nên thêm vào UI Settings**:

```dart
final biometricService = BiometricService();
final canUse = await biometricService.canUseBiometric();
final availableBiometrics = await biometricService.getAvailableBiometrics();

// Hiển thị:
// - "Thiết bị hỗ trợ: Vân tay" nếu có BiometricType.fingerprint
// - "Thiết bị hỗ trợ: Khuôn mặt" nếu có BiometricType.face
// - "Thiết bị không hỗ trợ" nếu không có gì
```

### 4. Logout xóa trạng thái sinh trắc học

**Đã implement trong `AuthProvider.logout()`**:
```dart
Future<void> logout() async {
  await _storageService.clearAll(); // Đã xóa hết, bao gồm biometric_enabled
  state = AuthState.unauthenticated();
}
```

---

## 🔒 Bảo mật

### Những gì KHÔNG bao giờ lưu trên thiết bị

- ❌ Mật khẩu gốc
- ❌ Access token (sau khi logout)
- ❌ Thông tin nhạy cảm khác

### Những gì được lưu an toàn

- ✅ Refresh Token (JWT, mã hóa trong `flutter_secure_storage`)
- ✅ Trạng thái biometric_enabled (boolean)
- ✅ Thông tin user cơ bản (userId, email, fullName)

### Cơ chế bảo mật

1. **Sinh trắc học không rời khỏi thiết bị**: Dữ liệu vân tay/khuôn mặt không được gửi đến server
2. **Refresh token có thời hạn**: 7 ngày, sau đó phải đăng nhập lại
3. **Access token ngắn hạn**: 30 phút, tự động refresh
4. **Xác thực 2 lớp**: Sinh trắc học + Refresh Token

---

## 🛠️ Debug

### Bật debug logs

Tất cả các service đã có `print()` statements. Xem logs trong console:

```bash
flutter run -d <device_id> --verbose
```

**Các logs quan trọng**:
- `AppInitializer: refreshToken=...` - Kiểm tra có refresh token không
- `AppInitializer: biometricEnabled=...` - Kiểm tra sinh trắc học đã bật chưa
- `AuthProvider: Bắt đầu đăng nhập sinh trắc học` - Bắt đầu flow
- `BiometricService: Kết quả xác thực: ...` - Kết quả xác thực
- `AuthProvider: Đăng nhập sinh trắc học thành công` - Thành công

### Clear data để test lại

```bash
# Android
flutter run --clear

# Hoặc xóa app data trong Settings
```

---

## 📚 Tài liệu liên quan

- **BIOMETRIC_ANDROID.md**: Chi tiết kỹ thuật về triển khai
- **build_auth.md**: Hệ thống xác thực tổng quan
- **README.md**: Hướng dẫn cài đặt và chạy dự án

---

## 🎉 Hoàn thành

Chức năng sinh trắc học đã được triển khai đầy đủ. Chỉ còn thiếu UI để người dùng bật/tắt trong Settings.

**Bước tiếp theo**:
1. Tạo Settings Screen với option bật/tắt sinh trắc học
2. Thêm dialog hỏi bật sinh trắc học sau khi đăng nhập lần đầu
3. Test trên thiết bị Android thật
4. Thêm unit tests cho BiometricService và AuthProvider
