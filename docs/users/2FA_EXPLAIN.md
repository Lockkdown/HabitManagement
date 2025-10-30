# 🔐 Giải thích Chi tiết 2FA (Two-Factor Authentication)

## 📦 Định nghĩa & Packages

### 2FA là gì?

**2FA = Xác thực 2 lớp**

```
Lớp 1: Email + Password (cái gì bạn biết)
Lớp 2: OTP Code (cái gì bạn có - từ authenticator app)

❌ Cách cũ: Chỉ email + password
✅ Cách mới: Email + password + OTP (6 chữ số)
```

### Packages

**Frontend**:
- `flutter_riverpod` - State management
- `http` - Gọi API

**Backend**:
- `Otp.NET` 1.4.0 - Tạo & verify TOTP
- `QRCoder` 1.7.0 - Tạo QR Code

---

## 🔄 Flow Hoạt động

### Scenario 1: Setup 2FA (Lần đầu Admin đăng nhập)

```
1. Admin nhập email + password
   ↓
2. Backend verify password → OK
   ↓
3. Backend check: TwoFactorEnabled? YES
   ↓
4. Backend check: TwoFactorSetupCompleted? NO (lần đầu)
   ↓
5. Backend return:
   - requiresTwoFactorSetup = true
   - tempToken (JWT 5 phút)
   - QrCode (Base64 image)
   - secretKey (backup)
   ↓
6. Frontend navigate to Setup2FAScreen
   ↓
7. Show QR Code → Admin scan bằng authenticator app
   ↓
8. Admin nhập OTP (6 chữ số)
   ↓
9. Frontend gọi API verify-2fa-setup
   ↓
10. Backend verify OTP → Thành công
    ↓
11. Backend set: TwoFactorSetupCompleted = true
    ↓
12. Backend return: accessToken + refreshToken
    ↓
13. Frontend navigate to AdminDashboardScreen
```

### Scenario 2: Verify OTP (Lần sau Admin đăng nhập)

```
1. Admin nhập email + password
   ↓
2. Backend verify password → OK
   ↓
3. Backend check: TwoFactorEnabled? YES
   ↓
4. Backend check: TwoFactorSetupCompleted? YES (lần sau)
   ↓
5. Backend return:
   - requiresTwoFactorVerification = true
   - tempToken (JWT 5 phút)
   ↓
6. Frontend navigate to Verify2FAScreen
   ↓
7. Admin nhập OTP từ authenticator app
   ↓
8. Frontend gọi API verify-2fa-login
   ↓
9. Backend verify OTP → Thành công
   ↓
10. Backend return: accessToken + refreshToken
    ↓
11. Frontend navigate to AdminDashboardScreen
```

### Scenario 3: User thường (không có 2FA)

```
1. User nhập email + password
   ↓
2. Backend verify password → OK
   ↓
3. Backend check: TwoFactorEnabled? NO
   ↓
4. Backend return: accessToken + refreshToken (ngay)
   ↓
5. Frontend navigate to HomeScreen
```

---

## 🎯 Frontend Implementation

### Setup2FAScreen - Scan QR & Verify OTP

```dart
class Setup2FAScreen extends ConsumerStatefulWidget {
  final TwoFactorLoginResponseModel twoFactorResponse;

  @override
  ConsumerState<Setup2FAScreen> createState() => _Setup2FAScreenState();
}

class _Setup2FAScreenState extends ConsumerState<Setup2FAScreen> {
  final TextEditingController _otpController = TextEditingController();

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      AppNotification.showError(context, 'OTP phải có 6 chữ số');
      return;
    }

    try {
      // Gọi API verify 2FA setup
      final authResponse = await _authApiService.verifyTwoFactorSetup(
        tempToken: widget.twoFactorResponse.tempToken!,
        otp: _otpController.text.trim(),
      );

      // Lưu tokens + user info
      await _storageService.saveAccessToken(authResponse.accessToken);
      await _storageService.saveRefreshToken(authResponse.refreshToken);
      await _storageService.saveUserInfo(...);

      // Cập nhật auth state
      final authNotifier = ref.read(authProvider.notifier);
      authNotifier.state = AuthState.authenticated(userModel);

      // Navigate to Admin Dashboard
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      AppNotification.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Setup 2FA')),
      body: Column(
        children: [
          // Hiển thị QR Code
          Image.memory(
            base64Decode(widget.twoFactorResponse.qrCode!),
            width: 250,
            height: 250,
          ),
          
          // Secret Key (backup)
          Text('Secret Key: ${widget.twoFactorResponse.secretKey}'),
          
          // Input OTP
          TextField(
            controller: _otpController,
            decoration: InputDecoration(labelText: 'OTP (6 chữ số)'),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          
          ElevatedButton(
            onPressed: _verifyOtp,
            child: Text('Verify OTP'),
          ),
        ],
      ),
    );
  }
}
```

### Verify2FAScreen - Verify OTP (Lần sau)

```dart
class Verify2FAScreen extends ConsumerStatefulWidget {
  final String tempToken;

  @override
  ConsumerState<Verify2FAScreen> createState() => _Verify2FAScreenState();
}

class _Verify2FAScreenState extends ConsumerState<Verify2FAScreen> {
  final TextEditingController _otpController = TextEditingController();

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      AppNotification.showError(context, 'OTP phải có 6 chữ số');
      return;
    }

    try {
      // Gọi API verify 2FA login
      final authResponse = await _authApiService.verifyTwoFactorLogin(
        tempToken: widget.tempToken,
        otp: _otpController.text.trim(),
      );

      // Lưu tokens + user info
      await _storageService.saveAccessToken(authResponse.accessToken);
      await _storageService.saveRefreshToken(authResponse.refreshToken);
      await _storageService.saveUserInfo(...);

      // Cập nhật auth state
      final authNotifier = ref.read(authProvider.notifier);
      authNotifier.state = AuthState.authenticated(userModel);

      // Navigate to Admin Dashboard
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      AppNotification.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify 2FA')),
      body: Column(
        children: [
          Text('Nhập OTP từ authenticator app'),
          TextField(
            controller: _otpController,
            decoration: InputDecoration(labelText: 'OTP (6 chữ số)'),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          ElevatedButton(
            onPressed: _verifyOtp,
            child: Text('Verify OTP'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🔧 Backend Implementation

### CreateAdminAsync - Tạo Admin với 2FA

```csharp
public async Task<(bool Success, string[] Errors, string? SecretKey, string? QrCode)> 
  CreateAdminAsync(CreateAdminDto createAdminDto)
{
  var user = new User
  {
    UserName = createAdminDto.Email,
    Email = createAdminDto.Email,
    FullName = createAdminDto.FullName,
    EmailConfirmed = true,           // ← Auto-confirmed
    TwoFactorEnabled = true,         // ← Bắt buộc 2FA
    TwoFactorSetupCompleted = false  // ← Chưa setup
  };

  // Tạo Secret Key TOTP
  var secretKey = GenerateTotpSecret();
  user.TwoFactorSecret = secretKey;

  // Tạo user
  var result = await _userManager.CreateAsync(user, createAdminDto.Password);
  if (!result.Succeeded)
    return (false, result.Errors.Select(e => e.Description).ToArray(), null, null);

  // Gán role Admin
  await _userManager.AddToRoleAsync(user, "Admin");

  // Tạo QR Code
  var qrCode = GenerateQrCode(secretKey, user.Email!);

  return (true, Array.Empty<string>(), secretKey, qrCode);
}
```

### LoginWithTwoFactorAsync - Xử lý Login

```csharp
public async Task<TwoFactorLoginResponseDto?> LoginWithTwoFactorAsync(LoginDto loginDto)
{
  // Tìm user
  var user = await _userManager.FindByEmailAsync(loginDto.Email);
  if (user == null)
    throw new Exception("Email hoặc mật khẩu không đúng");

  // Verify password
  var result = await _signInManager.CheckPasswordSignInAsync(user, loginDto.Password, false);
  if (!result.Succeeded)
    throw new Exception("Email hoặc mật khẩu không đúng");

  // Check 2FA
  if (user.TwoFactorEnabled)
  {
    // Lần đầu: Setup 2FA
    if (!user.TwoFactorSetupCompleted)
    {
      var tempToken = GenerateTempToken(user.Id);
      var qrCode = GenerateQrCode(user.TwoFactorSecret!, user.Email!);

      return new TwoFactorLoginResponseDto
      {
        RequiresTwoFactorSetup = true,
        TempToken = tempToken,
        QrCode = qrCode,
        SecretKey = user.TwoFactorSecret
      };
    }

    // Lần sau: Verify OTP
    var tempToken2 = GenerateTempToken(user.Id);
    return new TwoFactorLoginResponseDto
    {
      RequiresTwoFactorVerification = true,
      TempToken = tempToken2
    };
  }

  // User thường: Không cần 2FA
  var accessToken = await GenerateAccessTokenAsync(user);
  var refreshToken = await GenerateRefreshTokenAsync(user);

  return new TwoFactorLoginResponseDto
  {
    AccessToken = accessToken,
    RefreshToken = refreshToken,
    User = new AuthResponseDto { ... }
  };
}
```

### VerifyTwoFactorSetupAsync - Verify OTP Setup

```csharp
public async Task<AuthResponseDto?> VerifyTwoFactorSetupAsync(VerifyTwoFactorDto verifyDto)
{
  try
  {
    // Validate temp token
    var userId = ValidateTempToken(verifyDto.TempToken);
    var user = await _userManager.FindByIdAsync(userId);
    if (user == null) return null;

    // Verify OTP
    if (!VerifyTotp(user.TwoFactorSecret!, verifyDto.Otp))
      return null;

    // Setup hoàn tất
    user.TwoFactorSetupCompleted = true;
    await _userManager.UpdateAsync(user);

    // Cấp token
    var accessToken = await GenerateAccessTokenAsync(user);
    var refreshToken = await GenerateRefreshTokenAsync(user);

    return new AuthResponseDto
    {
      UserId = user.Id,
      Username = user.UserName!,
      Email = user.Email!,
      AccessToken = accessToken,
      RefreshToken = refreshToken
    };
  }
  catch { return null; }
}
```

### VerifyTwoFactorLoginAsync - Verify OTP Login

```csharp
public async Task<AuthResponseDto?> VerifyTwoFactorLoginAsync(VerifyTwoFactorDto verifyDto)
{
  try
  {
    // Validate temp token
    var userId = ValidateTempToken(verifyDto.TempToken);
    var user = await _userManager.FindByIdAsync(userId);
    if (user == null) return null;

    // Verify OTP
    if (!VerifyTotp(user.TwoFactorSecret!, verifyDto.Otp))
      return null;

    // Cấp token
    var accessToken = await GenerateAccessTokenAsync(user);
    var refreshToken = await GenerateRefreshTokenAsync(user);

    return new AuthResponseDto
    {
      UserId = user.Id,
      Username = user.UserName!,
      Email = user.Email!,
      AccessToken = accessToken,
      RefreshToken = refreshToken
    };
  }
  catch { return null; }
}
```

---

## 🔑 TOTP & QR Code

### TOTP (Time-based One-Time Password)

```csharp
// Tạo Secret Key TOTP (32 ký tự Base32)
private string GenerateTotpSecret()
{
  var key = KeyGeneration.GenerateRandomKey(32);
  return Base32Encoding.ToString(key);
}

// Verify OTP từ TOTP
private bool VerifyTotp(string secretKey, string otp)
{
  try
  {
    var bytes = Base32Encoding.ToBytes(secretKey);
    var totp = new Totp(bytes);
    
    // Verify OTP (cho phép sai lệch 1 time window)
    return totp.VerifyTotp(
      otp, 
      out long timeStepMatched, 
      VerificationWindow.RfcSpecifiedNetworkDelay
    );
  }
  catch { return false; }
}
```

### QR Code

```csharp
private string GenerateQrCode(string secretKey, string email)
{
  try
  {
    var qrGenerator = new QRCodeGenerator();
    
    // RFC 6238 format
    var otpAuthUrl = $"otpauth://totp/HabitManagement:{email}?secret={secretKey}&issuer=HabitManagement";
    
    var qrCodeData = qrGenerator.CreateQrCode(otpAuthUrl, QRCodeGenerator.ECCLevel.Q);
    var qrCode = new PngByteQRCode(qrCodeData);
    var qrCodeImage = qrCode.GetGraphic(10);
    
    // Convert to Base64
    return Convert.ToBase64String(qrCodeImage);
  }
  catch { return string.Empty; }
}
```

### Temporary Token

```csharp
// Tạo JWT 5 phút
private string GenerateTempToken(string userId)
{
  var secretKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY")!;
  var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
  var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

  var claims = new List<Claim>
  {
    new(ClaimTypes.NameIdentifier, userId),
    new("TokenType", "Temporary")
  };

  var token = new JwtSecurityToken(
    issuer: Environment.GetEnvironmentVariable("JWT_ISSUER"),
    audience: Environment.GetEnvironmentVariable("JWT_AUDIENCE"),
    claims: claims,
    expires: DateTime.UtcNow.AddMinutes(5),
    signingCredentials: credentials
  );

  return new JwtSecurityTokenHandler().WriteToken(token);
}

// Validate temp token
private string ValidateTempToken(string tempToken)
{
  var secretKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY")!;
  var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
  var tokenHandler = new JwtSecurityTokenHandler();

  var validationParameters = new TokenValidationParameters
  {
    ValidateIssuer = true,
    ValidateAudience = true,
    ValidateLifetime = true,
    ValidateIssuerSigningKey = true,
    ValidIssuer = Environment.GetEnvironmentVariable("JWT_ISSUER"),
    ValidAudience = Environment.GetEnvironmentVariable("JWT_AUDIENCE"),
    IssuerSigningKey = key
  };

  var principal = tokenHandler.ValidateToken(tempToken, validationParameters, out SecurityToken validatedToken);
  var userId = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;

  if (string.IsNullOrEmpty(userId))
    throw new Exception("Invalid token");

  return userId;
}
```

---

## 🛡️ Security Considerations

### 1. Admin bắt buộc 2FA

```csharp
// Admin luôn có TwoFactorEnabled = true
TwoFactorEnabled = true;  // ← Bắt buộc
```

### 2. Secret Key được lưu ở database

```csharp
// Mỗi user có secret key riêng
user.TwoFactorSecret = secretKey;
```

### 3. Temporary Token hết hạn 5 phút

```csharp
expires: DateTime.UtcNow.AddMinutes(5)  // ← 5 phút
```

### 4. OTP hết hạn 30 giây

```
TOTP = Time-based OTP
- Mỗi 30 giây → OTP mới
- Cho phép sai lệch 1 time window (±30 giây)
```

### 5. Authenticator Apps

Các app hỗ trợ:
- Google Authenticator
- Microsoft Authenticator
- Authy
- FreeOTP
- Duo Security

---

## 📊 So sánh: Admin vs User

| Thuộc tính | Admin | User |
|-----------|-------|------|
| **2FA** | ✅ Bắt buộc | ❌ Không có |
| **Setup** | Lần đầu đăng nhập | - |
| **Verify** | Mỗi lần đăng nhập | - |
| **QR Code** | Có | - |
| **Secret Key** | Có | - |

---

## 🎓 Khi demo:

**Q: "2FA là gì?"**
A: Xác thực 2 lớp - email + password + OTP từ authenticator app

**Q: "Tại sao Admin bắt buộc 2FA?"**
A: Bảo mật cao hơn - tránh attacker hack tài khoản admin

**Q: "OTP từ đâu?"**
A: Từ authenticator app (Google Authenticator, Microsoft Authenticator, etc.)

**Q: "Secret Key là gì?"**
A: Khóa bí mật để tạo OTP - lưu ở database

**Q: "QR Code dùng để gì?"**
A: Scan bằng authenticator app để thêm 2FA

**Q: "Nếu mất authenticator app sao?"**
A: Có secret key backup - có thể import vào app khác

---

**Tạo bởi**: Cascade AI
**Ngày**: Oct 31, 2025
**Phiên bản**: 1.0
