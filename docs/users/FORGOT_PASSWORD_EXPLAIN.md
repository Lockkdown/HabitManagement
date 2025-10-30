# 🔐 Giải thích Chi tiết Flow Forgot Password

## 📋 Mục lục
1. [Packages cần thiết](#packages-cần-thiết)
2. [Flow Hoạt động](#flow-hoạt-động)
3. [Frontend Files](#frontend-files)
4. [Backend Files](#backend-files)
5. [Email Service](#email-service)

---

## 📦 Packages cần thiết

### Frontend (Flutter)
- **http** ^1.5.0 - Gọi API
- **flutter_dotenv** ^5.2.1 - Load .env
- **flutter_riverpod** ^3.0.3 - State management

### Backend (.NET)
- **Microsoft.AspNetCore.Identity.EntityFrameworkCore** 9.0.10 - GeneratePasswordResetTokenAsync, ResetPasswordAsync
- **SendGrid** 9.29.3 - Gửi email reset password
- **Microsoft.Extensions.Caching.Memory** 9.0.10 - Lưu cache token mapping

---

## 🔄 Flow Hoạt động

```
1. User nhập email ở ForgotPasswordScreen
   ↓
2. Gọi API POST /api/auth/forgot-password
   ↓
3. Backend:
   - FindByEmailAsync() → Tìm user
   - GeneratePasswordResetTokenAsync() → Tạo token
   - Lưu token vào cache (24h)
   - SendPasswordResetWithLinkAsync() → Gửi email
   - Return tokenId
   ↓
4. Frontend navigate to WaitingVerificationScreen
   ↓
5. Frontend polling API GET /api/auth/check-token-status?tokenId=...
   (Mỗi 2 giây)
   ↓
6. User click link trong email
   ↓
7. Browser gọi GET /api/auth/verify-reset-token?tokenId=...
   ↓
8. Backend VerifyResetToken():
   - Tìm token trong cache
   - Update IsVerified = true
   - Return HTML page (success/failed)
   ↓
9. Frontend polling nhận được isVerified = true
   ↓
10. Frontend navigate to ResetPasswordScreen
    ↓
11. User nhập mật khẩu mới
    ↓
12. Gọi API POST /api/auth/reset-password
    ↓
13. Backend ResetPasswordAsync():
    - FindByEmailAsync() → Tìm user
    - ResetPasswordAsync() → Đặt lại mật khẩu
    - Return success/error
    ↓
14. Frontend navigate to LoginScreen
```

---

## 📁 Frontend Files

### 1. ForgotPasswordScreen (Nhập email)
```dart
// screens/forgot_password_screen.dart
- User nhập email
- Gọi authApiService.forgotPassword(email)
- Nhận tokenId
- Navigate to WaitingVerificationScreen
```

### 2. WaitingVerificationScreen (Polling)
```dart
// screens/waiting_verification_screen.dart
- Polling mỗi 2 giây: checkTokenStatus(tokenId)
- Khi isVerified = true → Navigate to ResetPasswordScreen
- Gửi token đã verify
```

### 3. ResetPasswordScreen (Nhập mật khẩu mới)
```dart
// screens/reset_password_screen.dart
- User nhập mật khẩu mới + confirm
- Gọi authApiService.resetPassword(email, token, password)
- Thành công → Navigate to LoginScreen
```

### 4. AuthApiService Methods
```dart
// api/auth_api_service.dart

// Method 1: Gửi yêu cầu quên mật khẩu
Future<String> forgotPassword({required String email}) async {
  POST /api/auth/forgot-password
  Body: {"email": "john@example.com"}
  Return: tokenId
}

// Method 2: Check token status
Future<Map<String, dynamic>> checkTokenStatus({required String tokenId}) async {
  GET /api/auth/check-token-status?tokenId=...
  Return: {isVerified, token, message}
}

// Method 3: Reset password
Future<String> resetPassword({
  required String email,
  required String token,
  required String newPassword,
  required String confirmPassword,
}) async {
  POST /api/auth/reset-password
  Body: {email, token, newPassword, confirmPassword}
  Return: message
}
```

---

## 🔧 Backend Files

### 1. AuthController Endpoints

```csharp
// controllers/AuthController.cs

// Endpoint 1: Forgot Password
[HttpPost("forgot-password")]
public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDto dto)
{
  var tokenId = await _authService.ForgotPasswordAsync(dto);
  return Ok(new { message = "...", tokenId });
}

// Endpoint 2: Verify Reset Token (User click link)
[HttpGet("verify-reset-token")]
public IActionResult VerifyResetToken([FromQuery] string tokenId)
{
  var success = _authService.VerifyResetToken(tokenId);
  return Content(html, "text/html");  // Return HTML page
}

// Endpoint 3: Check Token Status (Polling)
[HttpGet("check-token-status")]
public IActionResult CheckTokenStatus([FromQuery] string tokenId)
{
  var status = _authService.CheckTokenStatus(tokenId);
  return Ok(status);  // {isVerified, token, message}
}

// Endpoint 4: Reset Password
[HttpPost("reset-password")]
public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto dto)
{
  var (success, errors) = await _authService.ResetPasswordAsync(dto);
  return success ? Ok(...) : BadRequest(...);
}
```

### 2. AuthService Methods

```csharp
// services/AuthService.cs

// Method 1: ForgotPasswordAsync
public async Task<string?> ForgotPasswordAsync(ForgotPasswordDto dto)
{
  1. FindByEmailAsync(dto.Email) → Tìm user
  2. GeneratePasswordResetTokenAsync(user) → Tạo token
  3. Lưu vào cache: _cache.Set(cacheKey, tokenData, 24h)
  4. SendPasswordResetWithLinkAsync() → Gửi email
  5. Return tokenId
}

// Method 2: VerifyResetToken
public bool VerifyResetToken(string tokenId)
{
  1. Tìm token trong cache
  2. Update IsVerified = true
  3. Lưu lại vào cache
  4. Return true/false
}

// Method 3: CheckTokenStatus
public TokenStatusResponse CheckTokenStatus(string tokenId)
{
  1. Tìm token trong cache
  2. Check IsVerified
  3. Return {isVerified, token, message}
}

// Method 4: ResetPasswordAsync
public async Task<(bool, string[])> ResetPasswordAsync(ResetPasswordDto dto)
{
  1. FindByEmailAsync(dto.Email) → Tìm user
  2. ResetPasswordAsync(user, token, newPassword) → Đặt lại mật khẩu
  3. Return (success, errors)
}
```

### 3. DTOs

```csharp
// Models/DTOs/ForgotPasswordDto.cs
public class ForgotPasswordDto
{
  [Required]
  [EmailAddress]
  public string Email { get; set; }
}

// Models/DTOs/ResetPasswordDto.cs
public class ResetPasswordDto
{
  [Required]
  [EmailAddress]
  public string Email { get; set; }

  [Required]
  public string Token { get; set; }

  [Required]
  [MinLength(6)]
  public string NewPassword { get; set; }

  [Required]
  public string ConfirmPassword { get; set; }
}

// Models/Responses/TokenStatusResponse.cs
public class TokenStatusResponse
{
  public bool IsVerified { get; set; }
  public string? Token { get; set; }
  public string Message { get; set; }
}
```

---

## 📧 Email Service

### SendGrid Integration

```csharp
// services/EmailService.cs

public async Task SendPasswordResetWithLinkAsync(
  string email, 
  string fullName, 
  string verifyLink)
{
  // Tạo email content
  var subject = "Đặt lại mật khẩu - Habit Management";
  var htmlContent = $@"
    <h2>Xin chào {fullName},</h2>
    <p>Bạn đã yêu cầu đặt lại mật khẩu.</p>
    <p>
      <a href='{verifyLink}' style='background-color: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;'>
        Xác nhận và đặt lại mật khẩu
      </a>
    </p>
    <p>Link này sẽ hết hạn sau 24 giờ.</p>
  ";

  // Gửi email bằng SendGrid
  var from = new EmailAddress(
    Environment.GetEnvironmentVariable("SENDGRID_FROM_EMAIL"),
    Environment.GetEnvironmentVariable("SENDGRID_FROM_NAME")
  );
  var to = new EmailAddress(email, fullName);
  var msg = new SendGridMessage()
  {
    From = from,
    Subject = subject,
    HtmlContent = htmlContent
  };
  msg.AddTo(to);

  var client = new SendGridClient(
    Environment.GetEnvironmentVariable("SENDGRID_API_KEY")
  );
  await client.SendEmailAsync(msg);
}
```

---

## 🎯 Các hàm có sẵn từ thư viện

| Hàm | Thư viện | Mục đích |
|-----|---------|---------|
| `FindByEmailAsync()` | `UserManager<T>` | Tìm user theo email |
| `GeneratePasswordResetTokenAsync()` | `UserManager<T>` | Tạo token reset password |
| `ResetPasswordAsync()` | `UserManager<T>` | Đặt lại mật khẩu |
| `_cache.Set()` | `IMemoryCache` | Lưu token vào cache |
| `_cache.TryGetValue()` | `IMemoryCache` | Lấy token từ cache |
| `SendEmailAsync()` | `SendGrid` | Gửi email |
| `Timer.periodic()` | `dart:async` | Polling mỗi N giây |

---

## 🔒 Security Considerations

### 1. Token Expiration
- Token lưu trong cache 24 giờ
- Sau 24 giờ, token tự động xóa

### 2. Tránh Leak Thông tin
```csharp
// Nếu email không tồn tại, vẫn return tokenId giả
if (user == null)
{
  return tokenId;  // Attacker không biết email có tồn tại hay không
}
```

### 3. Token Verification
- Token chỉ được dùng 1 lần
- Sau khi verify, token được mark IsVerified = true
- Khi reset password, token được validate

### 4. Password Hashing
```csharp
// UserManager tự động hash password
await _userManager.ResetPasswordAsync(user, token, newPassword);
// Password không bao giờ lưu gốc
```

---

## 📝 Tóm tắt

| Bước | Frontend | Backend |
|------|----------|---------|
| 1 | Nhập email | - |
| 2 | POST /forgot-password | ForgotPasswordAsync() |
| 3 | Nhận tokenId | GeneratePasswordResetTokenAsync() |
| 4 | Polling /check-token-status | CheckTokenStatus() |
| 5 | User click link | VerifyResetToken() |
| 6 | Polling nhận token | IsVerified = true |
| 7 | Nhập mật khẩu mới | - |
| 8 | POST /reset-password | ResetPasswordAsync() |
| 9 | Navigate to login | Mật khẩu đã thay đổi |

---

## 🎓 Khi demo:

**Q: "Flow Forgot Password là gì?"**
A: User nhập email → Backend gửi link verify → User click link → Frontend polling → User nhập mật khẩu mới → Backend reset password

**Q: "Tại sao cần polling?"**
A: Vì user click link ở email (browser), không phải app. App cần polling để biết khi nào user đã click link

**Q: "Token được lưu ở đâu?"**
A: Backend lưu ở cache (24 giờ), Frontend không lưu token, chỉ lưu tokenId

**Q: "Nếu token hết hạn sao?"**
A: Sau 24 giờ, token tự động xóa từ cache. User phải yêu cầu reset password lại

**Q: "Tại sao phải verify token?"**
A: Để chắc chắn user đã kiểm tra email. Nếu không verify, attacker có thể reset password của user khác

---

**Tạo bởi**: Cascade AI
**Ngày**: Oct 30, 2025
**Phiên bản**: 1.0
