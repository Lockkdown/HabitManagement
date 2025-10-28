# Hệ thống 2FA và Phân quyền Admin

**Phiên bản**: 1.0 | **Ngày**: 28/10/2025 | **Tác giả**: Cascade AI

---

## 📋 Mục lục

1. [Tổng quan](#tổng-quan)
2. [Flow hoạt động](#flow-hoạt-động)
3. [Cấu trúc Database](#cấu-trúc-database)
4. [Backend Functions](#backend-functions)
5. [Frontend Screens](#frontend-screens)
6. [Thư viện sử dụng](#thư-viện-sử-dụng)

---

## 🔐 Tổng quan

### Phân quyền (Authorization)

**2 loại user**:
- **User thường**: Đăng nhập bình thường (Email + Password), không cần 2FA
- **Admin**: Bắt buộc 2FA, quản lý tài khoản user

### 2FA là gì?

**Two-Factor Authentication** = 2 lớp xác thực:
1. **Lớp 1**: Email + Password (cái bạn biết)
2. **Lớp 2**: OTP 6 số từ Google Authenticator (cái bạn có)

**Công nghệ**: TOTP (RFC 6238), Secret Key 32 ký tự Base32

---

## 🔄 Flow hoạt động

### Flow 1: Tạo Admin Account (Backend)

```
[Backend] Tạo user với role "Admin"
    ↓
[Backend] Tự động tạo Secret Key TOTP (32 ký tự)
    ↓
[Backend] Lưu database:
  - TwoFactorEnabled = true (bắt buộc)
  - TwoFactorSecret = <secret_key>
  - TwoFactorSetupCompleted = false
    ↓
[Backend] Tạo QR Code từ Secret Key
    ↓
[Backend] Gửi email: QR Code + Secret Key
```

### Flow 2: Admin Đăng nhập Lần đầu (Setup 2FA)

```
[Frontend] Admin nhập Email + Password
    ↓
[Backend] Verify email/password ✅
    ↓
[Backend] Kiểm tra:
  - Role = Admin? ✅
  - TwoFactorEnabled = true? ✅
  - TwoFactorSetupCompleted = false? ✅ (lần đầu)
    ↓
[Backend] Trả về:
  - requiresTwoFactorSetup = true
  - tempToken = <temporary_token>
  - qrCode = <base64_image>
    ↓
[Frontend] Navigate → Setup2FAScreen
    ↓
[Admin] Scan QR Code bằng Google Authenticator
    ↓
[Admin] Nhập OTP 6 số từ app
    ↓
[Frontend] Gửi: tempToken + OTP → Backend
    ↓
[Backend] Verify OTP ✅
    ↓
[Backend] Cập nhật: TwoFactorSetupCompleted = true
    ↓
[Backend] Cấp JWT Access Token
    ↓
[Frontend] Navigate → Admin Dashboard ✅
```

### Flow 3: Admin Đăng nhập Lần sau (Verify 2FA)

```
[Frontend] Admin nhập Email + Password
    ↓
[Backend] Verify email/password ✅
    ↓
[Backend] Kiểm tra:
  - Role = Admin? ✅
  - TwoFactorEnabled = true? ✅
  - TwoFactorSetupCompleted = true? ✅
    ↓
[Backend] Trả về:
  - requiresTwoFactorVerification = true
  - tempToken = <temporary_token>
    ↓
[Frontend] Navigate → Login2FAScreen
    ↓
[Admin] Mở Google Authenticator → Lấy OTP
    ↓
[Admin] Nhập OTP 6 số
    ↓
[Frontend] Gửi: tempToken + OTP → Backend
    ↓
[Backend] Verify OTP ✅
    ↓
[Backend] Cấp JWT Access Token
    ↓
[Frontend] Navigate → Admin Dashboard ✅
```

### Flow 4: User Thường Đăng nhập (Không 2FA)

```
[Frontend] User nhập Email + Password
    ↓
[Backend] Verify email/password ✅
    ↓
[Backend] Kiểm tra:
  - Role = User (không phải Admin)
  - TwoFactorEnabled = false
    ↓
[Backend] Cấp JWT Access Token ngay
    ↓
[Frontend] Navigate → HomeScreen ✅
```

---

## 🗄️ Cấu trúc Database

### Thêm cột vào `AspNetUsers` table

```sql
ALTER TABLE AspNetUsers 
ADD 
    TwoFactorSecret NVARCHAR(MAX) NULL,
    TwoFactorEnabled BIT DEFAULT 0,
    TwoFactorSetupCompleted BIT DEFAULT 0;
```

### Mô tả cột

| Cột | Kiểu | Mục đích | Giá trị |
|-----|------|---------|--------|
| `TwoFactorSecret` | NVARCHAR(MAX) | Secret Key TOTP (32 ký tự Base32) | `"JBSWY3DPEHPK3PXP..."` |
| `TwoFactorEnabled` | BIT | Có bật 2FA không? | Admin=1, User=0 |
| `TwoFactorSetupCompleted` | BIT | Admin đã setup 2FA chưa? | Lần đầu=0, Đã setup=1 |

### Migration

```bash
cd backend
dotnet ef migrations add AddTwoFactorToUser
dotnet ef database update
```

---

## 🛠️ Backend Functions

### 1. GenerateTotpSecret() - Tạo Secret Key

```csharp
private string GenerateTotpSecret()
{
    var key = KeyGeneration.GenerateRandomKey(32);
    return Base32Encoding.ToString(key);
}
```

**Mục đích**: Tạo Secret Key 32 ký tự Base32 cho TOTP

---

### 2. GenerateQrCode() - Tạo QR Code

```csharp
private string GenerateQrCode(string secretKey, string email)
{
    var qrGenerator = new QRCodeGenerator();
    var qrCodeData = qrGenerator.CreateQrCode(
        $"otpauth://totp/HabitManagement:{email}?secret={secretKey}&issuer=HabitManagement",
        QRCodeGenerator.ECCLevel.Q
    );
    
    var qrCode = new PngByteQRCode(qrCodeData);
    var qrCodeImage = qrCode.GetGraphic(10);
    
    return Convert.ToBase64String(qrCodeImage);
}
```

**Mục đích**: Tạo QR Code base64 từ Secret Key

---

### 3. VerifyTotp() - Xác minh OTP

```csharp
private bool VerifyTotp(string secretKey, string otp)
{
    try
    {
        var bytes = Base32Encoding.ToBytes(secretKey);
        var totp = new Totp(bytes);
        
        return totp.VerifyTotp(otp, out long timeStepMatched, 
            VerificationWindow.RfcSpecifiedWindow);
    }
    catch
    {
        return false;
    }
}
```

**Mục đích**: Verify OTP 6 số có đúng không

---

### 4. SetupTwoFactor() - Setup 2FA lần đầu

```csharp
public async Task<SetupTwoFactorResponse> SetupTwoFactor(string userId)
{
    var secretKey = GenerateTotpSecret();
    var user = await _userManager.FindByIdAsync(userId);
    
    user.TwoFactorSecret = secretKey;
    await _userManager.UpdateAsync(user);
    
    var qrCode = GenerateQrCode(secretKey, user.Email!);
    
    return new { qrCode, secretKey };
}
```

**Mục đích**: Tạo Secret Key + QR Code cho Admin lần đầu

---

### 5. VerifyTwoFactorSetup() - Verify Setup 2FA

```csharp
public async Task<LoginResponse> VerifyTwoFactorSetup(string tempToken, string otp)
{
    var userId = ValidateTempToken(tempToken);
    var user = await _userManager.FindByIdAsync(userId);
    
    if (!VerifyTotp(user.TwoFactorSecret!, otp))
        throw new UnauthorizedException("Invalid OTP");
    
    user.TwoFactorSetupCompleted = true;
    await _userManager.UpdateAsync(user);
    
    var accessToken = GenerateJwtToken(user);
    return new { accessToken };
}
```

**Mục đích**: Verify OTP → Enable 2FA → Cấp token

---

### 6. LoginAsync() - Đăng nhập (cập nhật)

```csharp
public async Task<LoginResponse?> LoginAsync(LoginDto loginDto)
{
    var user = await _userManager.FindByEmailAsync(loginDto.Email);
    if (user == null) return null;
    
    var result = await _signInManager.CheckPasswordSignInAsync(user, loginDto.Password, false);
    if (!result.Succeeded) return null;
    
    // Kiểm tra 2FA
    if (user.TwoFactorEnabled)
    {
        if (!user.TwoFactorSetupCompleted)
        {
            // Lần đầu: yêu cầu setup
            var tempToken = GenerateTempToken(user.Id);
            var qrCode = GenerateQrCode(user.TwoFactorSecret!, user.Email!);
            
            return new { 
                requiresTwoFactorSetup = true,
                tempToken,
                qrCode
            };
        }
        
        // Lần sau: yêu cầu verify
        var tempToken2 = GenerateTempToken(user.Id);
        return new { 
            requiresTwoFactorVerification = true,
            tempToken = tempToken2
        };
    }
    
    // User thường: cấp token ngay
    var accessToken = GenerateAccessTokenAsync(user);
    return new { accessToken };
}
```

**Mục đích**: Phân biệt Admin/User, Setup/Verify 2FA

---

### 7. VerifyTwoFactorLogin() - Verify OTP lần sau

```csharp
public async Task<LoginResponse> VerifyTwoFactorLogin(string tempToken, string otp)
{
    var userId = ValidateTempToken(tempToken);
    var user = await _userManager.FindByIdAsync(userId);
    
    if (!VerifyTotp(user.TwoFactorSecret!, otp))
        throw new UnauthorizedException("Invalid OTP");
    
    var accessToken = GenerateJwtToken(user);
    return new { accessToken };
}
```

**Mục đích**: Verify OTP lần sau → Cấp token

---

## 📱 Frontend Screens

### 1. LoginScreen (cập nhật)

**Logic**:
- Nhập Email + Password
- Gọi API `/api/auth/login`
- Kiểm tra response:
  - `requiresTwoFactorSetup = true` → Navigate Setup2FAScreen
  - `requiresTwoFactorVerification = true` → Navigate Login2FAScreen
  - Không có 2FA → Navigate HomeScreen

---

### 2. Setup2FAScreen (lần đầu)

**Hiển thị**:
- QR Code (scan bằng Google Authenticator)
- Ô nhập OTP 6 số
- Nút "Xác minh"

**Logic**:
- Gọi API `/api/auth/verify-2fa-setup` với tempToken + OTP
- Verify thành công → Lưu token → Navigate AdminDashboard

---

### 3. Login2FAScreen (lần sau)

**Hiển thị**:
- Ô nhập OTP 6 số
- Nút "Xác minh"

**Logic**:
- Gọi API `/api/auth/verify-2fa-login` với tempToken + OTP
- Verify thành công → Lưu token → Navigate AdminDashboard

---

## 📦 Thư viện sử dụng

### Backend (.NET)

```bash
dotnet add package OtpNet
dotnet add package QRCoder
```

| Package | Phiên bản | Mục đích |
|---------|----------|---------|
| `OtpNet` | 1.4.0 | Tạo + Verify TOTP |
| `QRCoder` | 1.7.0 | Tạo QR Code |

### Frontend (Flutter)

**Không cần thêm package** - Dùng package hiện có:
- `http`: Gọi API
- `flutter_secure_storage`: Lưu token
- `Image.memory()`: Hiển thị QR Code từ base64

---

## 🔒 Security Best Practices

1. **Secret Key**: Lưu an toàn trong database, không bao giờ log
2. **Temporary Token**: Hết hạn sau 5 phút
3. **OTP Verification**: Cho phép ±1 time window (RFC 6238)
4. **One-Time Use**: Lưu timeWindowUsed để tránh replay attack
5. **Rate Limiting**: Giới hạn số lần nhập OTP sai (max 5 lần)
6. **HTTPS Only**: Luôn dùng HTTPS, không HTTP

---

## 📝 Tóm tắt

| Thành phần | Chi tiết |
|-----------|---------|
| **Phân quyền** | Admin (2FA bắt buộc) vs User (không 2FA) |
| **Flow Setup** | Tạo Secret → QR Code → Scan → Verify OTP → Enable |
| **Flow Login** | Email+Pass → Kiểm tra 2FA → Setup/Verify/Direct |
| **Database** | +3 cột: TwoFactorSecret, TwoFactorEnabled, TwoFactorSetupCompleted |
| **Backend** | 7 functions chính (Generate, Verify, Setup, Login) |
| **Frontend** | 3 screens (Login, Setup2FA, Login2FA) |
| **Thư viện** | OtpNet + QRCoder |

---

**Trạng thái**: ✅ Sẵn sàng implement
