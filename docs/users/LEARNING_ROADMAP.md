# 📚 Learning Roadmap - Xây dựng lại từ đầu

## Mục tiêu
Học từng chức năng theo thứ tự logic, có thể giải thích từng dòng code khi giảng viên hỏi.

---

## 1️⃣ ĐĂNG KÝ (Register)

### 📦 Packages cần thiết

**Backend (.NET)**:
- ✅ `Microsoft.AspNetCore.Identity.EntityFrameworkCore` (v9.0.10) - ASP.NET Core Identity
- ✅ `Microsoft.AspNetCore.Authentication.JwtBearer` (v9.0.10) - JWT authentication
- ✅ `Microsoft.EntityFrameworkCore` (v9.0.10) - ORM
- ✅ `BCrypt.Net-Next` (v4.0.3) - Password hashing

**Frontend (Flutter)**:
- ✅ `http: ^1.5.0` - HTTP requests
- ✅ `flutter_riverpod: ^3.0.3` - State management
- ✅ `flutter_secure_storage: ^9.2.4` - Secure token storage

### Backend
- [ ] **DTO - RegisterDto.cs**
  - [ ] Tạo class với properties: Email, Username, Password, ConfirmPassword, FullName
  - [ ] Thêm validation attributes (Required, EmailAddress, MinLength)
  - [ ] Hiểu: Tại sao cần DTO? (Validate dữ liệu từ client)

- [ ] **Model - User.cs** (extends IdentityUser)
  - [ ] Hiểu: IdentityUser là gì? (ASP.NET Core Identity)
  - [ ] Thêm custom properties: FullName, DateOfBirth, ThemePreference, LanguageCode
  - [ ] Hiểu: Tại sao extends IdentityUser? (Có sẵn Id, Email, PasswordHash, SecurityStamp...)

- [ ] **Service - AuthService.cs**
  - [ ] Tạo method `RegisterAsync(RegisterDto dto)`
  - [ ] Logic:
    - [ ] Validate email chưa tồn tại
    - [ ] Tạo User object từ DTO
    - [ ] Gọi `userManager.CreateAsync(user, password)` - Hash password
    - [ ] Assign role "User" cho user mới
    - [ ] Gửi email xác thực
    - [ ] Return success/error message
  - [ ] Hiểu: Tại sao dùng UserManager? (ASP.NET Core Identity)

- [ ] **Controller - AuthController.cs**
  - [ ] Tạo endpoint `POST /api/auth/register`
  - [ ] Logic:
    - [ ] Validate ModelState
    - [ ] Gọi `authService.RegisterAsync(dto)`
    - [ ] Return 201 Created hoặc 400 BadRequest
  - [ ] Hiểu: HTTP status codes (201, 400, 500)

### Frontend
- [ ] **Model - user_model.dart**
  - [ ] Tạo class User với properties: id, email, username, fullName, dateOfBirth, themePreference, languageCode
  - [ ] Tạo `fromJson()` factory constructor
  - [ ] Tạo `toJson()` method
  - [ ] Hiểu: Tại sao cần fromJson/toJson? (Serialize/Deserialize JSON)

- [ ] **API Service - auth_api_service.dart**
  - [ ] Tạo method `registerUser(email, username, password, confirmPassword, fullName)`
  - [ ] Logic:
    - [ ] Tạo request body (Map)
    - [ ] Gọi `http.post()` đến `/api/auth/register`
    - [ ] Parse response JSON
    - [ ] Return User object hoặc throw exception
  - [ ] Hiểu: HTTP POST, headers, body

- [ ] **State Management - auth_provider.dart (Riverpod)**
  - [ ] Tạo provider `registerProvider` (FutureProvider)
  - [ ] Logic: Gọi `authApiService.registerUser()`
  - [ ] Hiểu: Riverpod là gì? (State management)

- [ ] **Screen - register_screen.dart**
  - [ ] Tạo UI:
    - [ ] TextFormField: Email, Username, Password, ConfirmPassword, FullName
    - [ ] Button: Register
    - [ ] Validation: Email format, Password match
  - [ ] Logic:
    - [ ] Validate form
    - [ ] Gọi `ref.read(registerProvider)` để register
    - [ ] Show loading/success/error
    - [ ] Navigate to login screen nếu thành công
  - [ ] Hiểu: Form validation, async/await, navigation

---

## 2️⃣ ĐĂNG NHẬP (Login)

### 📦 Packages cần thiết

**Backend (.NET)**:
- ✅ `Microsoft.AspNetCore.Identity.EntityFrameworkCore` (v9.0.10)
- ✅ `Microsoft.AspNetCore.Authentication.JwtBearer` (v9.0.10)
- ✅ `System.IdentityModel.Tokens.Jwt` (v7.0.0) - JWT token generation
- ✅ `Microsoft.IdentityModel.Tokens` (v7.0.0) - Token validation

**Frontend (Flutter)**:
- ✅ `http: ^1.5.0`
- ✅ `flutter_riverpod: ^3.0.3`
- ✅ `flutter_secure_storage: ^9.2.4`

### Backend
- [ ] **DTO - LoginDto.cs**
  - [ ] Properties: Email/Username, Password
  - [ ] Validation attributes

- [ ] **DTO - AuthResponseDto.cs**
  - [ ] Properties: AccessToken, RefreshToken, User (UserDto), ExpiresIn, TokenType
  - [ ] Hiểu: JWT token là gì? (JSON Web Token)

- [ ] **Service - AuthService.cs**
  - [ ] Tạo method `LoginAsync(LoginDto dto)`
  - [ ] Logic:
    - [ ] Tìm user bằng email/username
    - [ ] Validate password bằng `userManager.CheckPasswordAsync()`
    - [ ] Tạo JWT access token (claims: UserId, Email, Role)
    - [ ] Tạo refresh token
    - [ ] Lưu refresh token vào database (AspNetUserTokens)
    - [ ] Return AuthResponseDto
  - [ ] Hiểu: JWT structure (header.payload.signature), claims, expiration

- [ ] **Controller - AuthController.cs**
  - [ ] Tạo endpoint `POST /api/auth/login`
  - [ ] Gọi `authService.LoginAsync(dto)`
  - [ ] Return 200 OK với AuthResponseDto

### Frontend
- [ ] **Model - auth_response_model.dart**
  - [ ] Properties: accessToken, refreshToken, user (User), expiresIn, tokenType
  - [ ] fromJson/toJson

- [ ] **Storage - storage_service.dart**
  - [ ] Tạo method `saveToken(accessToken, refreshToken)`
  - [ ] Dùng `flutter_secure_storage` để lưu token an toàn
  - [ ] Hiểu: Tại sao dùng secure storage? (Bảo mật)

- [ ] **API Service - auth_api_service.dart**
  - [ ] Tạo method `loginUser(email, password)`
  - [ ] Logic: POST đến `/api/auth/login`, parse AuthResponse

- [ ] **State Management - auth_provider.dart**
  - [ ] Tạo provider `loginProvider` (FutureProvider)
  - [ ] Tạo provider `currentUserProvider` (StateProvider)
  - [ ] Logic: Lưu token + user vào state

- [ ] **Screen - login_screen.dart**
  - [ ] UI: Email/Username field, Password field, Login button
  - [ ] Logic:
    - [ ] Validate form
    - [ ] Gọi login provider
    - [ ] Lưu token vào secure storage
    - [ ] Navigate to home screen
  - [ ] Hiểu: Form handling, async operations, navigation

---

## 3️⃣ QUÊN MẬT KHẨU (Forgot Password)

### 📦 Packages cần thiết

**Backend (.NET)**:
- ✅ `Microsoft.AspNetCore.Identity.EntityFrameworkCore` (v9.0.10)
- ✅ `SendGrid` (v9.29.3) - Email service
- ✅ `Microsoft.AspNetCore.WebUtilities` (v9.0.10) - URL encoding

**Frontend (Flutter)**:
- ✅ `http: ^1.5.0`
- ✅ `flutter_riverpod: ^3.0.3`

### Backend
- [ ] **DTO - ForgotPasswordDto.cs**
  - [ ] Property: Email

- [ ] **DTO - ResetPasswordDto.cs**
  - [ ] Properties: Token, NewPassword, ConfirmPassword

- [ ] **DTO - VerifyResetTokenDto.cs**
  - [ ] Property: Token

- [ ] **Service - AuthService.cs**
  - [ ] Tạo method `ForgotPasswordAsync(string email)`
  - [ ] Logic:
    - [ ] Tìm user bằng email
    - [ ] Tạo password reset token: `userManager.GeneratePasswordResetTokenAsync(user)`
    - [ ] Tạo reset link: `https://frontend-url/reset-password?token={token}`
    - [ ] Gửi email với link
    - [ ] Return success message
  - [ ] Hiểu: Password reset token là gì? (Temporary token)

- [ ] **Service - EmailService.cs**
  - [ ] Tạo method `SendPasswordResetEmailAsync(email, resetLink)`
  - [ ] Dùng SendGrid để gửi email
  - [ ] Hiểu: SendGrid integration

- [ ] **Service - AuthService.cs**
  - [ ] Tạo method `VerifyResetTokenAsync(string token)`
  - [ ] Logic: Validate token còn hợp lệ không

- [ ] **Service - AuthService.cs**
  - [ ] Tạo method `ResetPasswordAsync(ResetPasswordDto dto)`
  - [ ] Logic:
    - [ ] Verify token
    - [ ] Reset password: `userManager.ResetPasswordAsync(user, token, newPassword)`
    - [ ] Return success message

- [ ] **Controller - AuthController.cs**
  - [ ] Endpoint `POST /api/auth/forgot-password`
  - [ ] Endpoint `POST /api/auth/verify-reset-token`
  - [ ] Endpoint `POST /api/auth/reset-password`

### Frontend
- [ ] **API Service - auth_api_service.dart**
  - [ ] Method `forgotPassword(email)`
  - [ ] Method `verifyResetToken(token)`
  - [ ] Method `resetPassword(token, newPassword, confirmPassword)`

- [ ] **Screen - reset_password_screen.dart**
  - [ ] UI:
    - [ ] Email field (step 1)
    - [ ] Token field (step 2)
    - [ ] New password fields (step 3)
  - [ ] Logic: Multi-step form, validate token, reset password

- [ ] **Screen - waiting_verification_screen.dart**
  - [ ] UI: Hiển thị "Check your email" message
  - [ ] Logic: Chờ user click link trong email

---

## 4️⃣ SINH TRẮC HỌC (Biometric - Quick Login)

### 📦 Packages cần thiết

**Backend (.NET)**:
- ✅ `Microsoft.AspNetCore.Identity.EntityFrameworkCore` (v9.0.10)

**Frontend (Flutter)**:
- ✅ `local_auth: ^3.0.0` - Biometric authentication
- ✅ `local_auth_android: ^2.0.0` - Android biometric support
- ✅ `flutter_secure_storage: ^9.2.4` - Secure credential storage
- ✅ `http: ^1.5.0`

### Backend
- [ ] **Controller - AuthController.cs**
  - [ ] Endpoint `GET /api/auth/user/{id}` (lấy thông tin user)
  - [ ] Hiểu: Biometric ở frontend, backend chỉ verify token

### Frontend
- [ ] **Service - biometric_service.dart**
  - [ ] Tạo method `isBiometricAvailable()`
  - [ ] Logic: Check device hỗ trợ biometric không
  - [ ] Dùng package `local_auth`

- [ ] **Service - biometric_service.dart**
  - [ ] Tạo method `authenticateWithBiometric()`
  - [ ] Logic:
    - [ ] Gọi `LocalAuthentication.authenticate()`
    - [ ] Show dialog "Scan your fingerprint"
    - [ ] Return true/false
  - [ ] Hiểu: Native platform integration

- [ ] **Storage - storage_service.dart**
  - [ ] Tạo method `saveBiometricCredentials(email, password)`
  - [ ] Lưu email + password (encrypted) vào secure storage
  - [ ] Hiểu: Tại sao encrypt? (Bảo mật)

- [ ] **Screen - login_screen.dart**
  - [ ] Thêm button "Quick Login" (biometric)
  - [ ] Logic:
    - [ ] Check biometric available
    - [ ] Authenticate với biometric
    - [ ] Lấy saved credentials
    - [ ] Tự động login
  - [ ] Hiểu: Conditional rendering, async operations

---

## 5️⃣ 2FA ADMIN (TOTP - Time-based One-Time Password)

### 📦 Packages cần thiết

**Backend (.NET)**:
- ✅ `Microsoft.AspNetCore.Identity.EntityFrameworkCore` (v9.0.10)
- ✅ `Otp.NET` (v1.4.0) - TOTP generation & verification
- ✅ `QRCoder` (v1.7.0) - QR code generation
- ✅ `System.IdentityModel.Tokens.Jwt` (v7.0.0)

**Frontend (Flutter)**:
- ✅ `qr_flutter: ^4.1.0` - QR code display
- ✅ `http: ^1.5.0`
- ✅ `flutter_riverpod: ^3.0.3`
- ✅ `flutter_secure_storage: ^9.2.4`

### Backend
- [ ] **DTO - TwoFactorLoginResponseDto.cs**
  - [ ] Properties: RequiresTwoFactor, TempToken (để verify 2FA)

- [ ] **DTO - VerifyTwoFactorDto.cs**
  - [ ] Properties: TempToken, TwoFactorCode

- [ ] **Service - AuthService.cs**
  - [ ] Tạo method `Setup2FAAsync(User user)`
  - [ ] Logic:
    - [ ] Tạo secret key: `KeyGeneration.GenerateRandomKey()`
    - [ ] Tạo QR code từ secret: `Totp.GetQrCodeUri()`
    - [ ] Lưu secret vào database (AspNetUserTokens)
    - [ ] Return QR code URI
  - [ ] Dùng packages: `Otp.NET`, `QRCoder`
  - [ ] Hiểu: TOTP algorithm, QR code

- [ ] **Service - AuthService.cs**
  - [ ] Tạo method `Verify2FACodeAsync(string code, string secret)`
  - [ ] Logic:
    - [ ] Tạo TOTP object từ secret
    - [ ] Verify code: `totp.VerifyTotp(code)`
    - [ ] Return true/false
  - [ ] Hiểu: TOTP verification

- [ ] **Service - AuthService.cs**
  - [ ] Tạo method `LoginAsync()` - Update để support 2FA
  - [ ] Logic:
    - [ ] Nếu user có 2FA enabled
    - [ ] Tạo temp token (short-lived)
    - [ ] Return TwoFactorLoginResponseDto (RequiresTwoFactor = true)
    - [ ] Frontend dùng temp token để verify 2FA

- [ ] **Service - AuthService.cs**
  - [ ] Tạo method `VerifyTwoFactorAsync(VerifyTwoFactorDto dto)`
  - [ ] Logic:
    - [ ] Validate temp token
    - [ ] Verify 2FA code
    - [ ] Tạo access token + refresh token
    - [ ] Return AuthResponseDto

- [ ] **Controller - AuthController.cs**
  - [ ] Endpoint `POST /api/auth/setup-2fa`
  - [ ] Endpoint `POST /api/auth/verify-2fa`

- [ ] **Controller - AdminController.cs**
  - [ ] Endpoint `POST /api/admin/enable-2fa` (bắt buộc 2FA cho Admin)
  - [ ] Endpoint `POST /api/admin/disable-2fa`

### Frontend
- [ ] **Model - two_factor_login_response_model.dart**
  - [ ] Properties: requiresTwoFactor, tempToken

- [ ] **API Service - auth_api_service.dart**
  - [ ] Method `setup2FA()`
  - [ ] Method `verify2FA(tempToken, code)`

- [ ] **Screen - setup_2fa_screen.dart**
  - [ ] UI:
    - [ ] Hiển thị QR code
    - [ ] Hiển thị secret key (backup)
    - [ ] Button "Confirm Setup"
  - [ ] Logic:
    - [ ] Gọi API setup 2FA
    - [ ] Hiển thị QR code (dùng package `qr_flutter`)
    - [ ] User scan bằng authenticator app (Google Authenticator, Authy)
  - [ ] Hiểu: QR code rendering, user flow

- [ ] **Screen - verify_2fa_screen.dart**
  - [ ] UI:
    - [ ] 6-digit code input field
    - [ ] Button "Verify"
  - [ ] Logic:
    - [ ] Gọi API verify 2FA
    - [ ] Nếu đúng, lưu access token + navigate to home
    - [ ] Nếu sai, show error
  - [ ] Hiểu: OTP input, error handling

- [ ] **Screen - login_screen.dart**
  - [ ] Update logic:
    - [ ] Nếu login response có `requiresTwoFactor = true`
    - [ ] Navigate to verify_2fa_screen
    - [ ] Pass temp token

---

## 6️⃣ ADMIN DASHBOARD

### 📦 Packages cần thiết

**Backend (.NET)**:
- ✅ `Microsoft.AspNetCore.Identity.EntityFrameworkCore` (v9.0.10)
- ✅ `Microsoft.EntityFrameworkCore` (v9.0.10)
- ✅ `System.IdentityModel.Tokens.Jwt` (v7.0.0)

**Frontend (Flutter)**:
- ✅ `http: ^1.5.0`
- ✅ `flutter_riverpod: ^3.0.3`
- ✅ `fl_chart: ^0.69.0` - Charts & graphs
- ✅ `intl: ^0.20.2` - Localization & formatting
- ✅ `lucide_flutter: ^0.546.0` - Icons

### Backend
- [ ] **DTO - UserListDto.cs**
  - [ ] Properties: Id, Email, Username, FullName, Role, TwoFactorEnabled, CreatedAt

- [ ] **DTO - UpdateUserRoleDto.cs**
  - [ ] Properties: UserId, NewRole

- [ ] **DTO - CreateAdminDto.cs**
  - [ ] Properties: Email, Username, Password, FullName

- [ ] **Controller - AdminController.cs**
  - [ ] Endpoint `GET /api/admin/users` (lấy danh sách users)
  - [ ] Logic:
    - [ ] Authorize: Chỉ Admin
    - [ ] Query users từ database
    - [ ] Return List<UserListDto>
  - [ ] Hiểu: Authorization, filtering, pagination

- [ ] **Controller - AdminController.cs**
  - [ ] Endpoint `POST /api/admin/users/{id}/role` (cập nhật role)
  - [ ] Logic:
    - [ ] Authorize: Chỉ Admin
    - [ ] Validate role hợp lệ
    - [ ] Update user role
    - [ ] Return success message

- [ ] **Controller - AdminController.cs**
  - [ ] Endpoint `DELETE /api/admin/users/{id}` (xóa user)
  - [ ] Endpoint `POST /api/admin/users` (tạo admin)

- [ ] **Controller - StatisticsController.cs**
  - [ ] Endpoint `GET /api/statistics/dashboard` (thống kê hệ thống)
  - [ ] Logic: Tổng users, habits, completions, etc.

### Frontend
- [ ] **Model - user_list_model.dart**
  - [ ] Properties: id, email, username, fullName, role, twoFactorEnabled, createdAt
  - [ ] fromJson/toJson

- [ ] **API Service - admin_api_service.dart**
  - [ ] Method `getUsers()`
  - [ ] Method `updateUserRole(userId, newRole)`
  - [ ] Method `deleteUser(userId)`
  - [ ] Method `createAdmin(email, username, password, fullName)`

- [ ] **API Service - statistics_api_service.dart**
  - [ ] Method `getDashboardStats()`

- [ ] **State Management - admin_provider.dart**
  - [ ] Provider `usersListProvider` (FutureProvider)
  - [ ] Provider `dashboardStatsProvider` (FutureProvider)

- [ ] **Screen - admin_dashboard_screen.dart**
  - [ ] UI:
    - [ ] Tab 1: Users Management
    - [ ] Tab 2: System Statistics
    - [ ] Tab 3: Settings
  - [ ] Users Management:
    - [ ] DataTable: Email, Username, Role, 2FA Status
    - [ ] Button: Edit Role, Delete, Create Admin
  - [ ] System Statistics:
    - [ ] Cards: Total Users, Total Habits, Completion Rate
    - [ ] Charts: User growth, habit completion trend
  - [ ] Logic:
    - [ ] Load users list
    - [ ] Load statistics
    - [ ] Handle update role, delete user
    - [ ] Show loading/error states
  - [ ] Hiểu: DataTable, charts, state management

---

## 📊 Tóm tắt theo thứ tự học

| # | Chức năng | Độ khó | Thời gian | Ưu tiên |
|---|-----------|--------|----------|---------|
| 1 | Đăng ký | ⭐ | 2-3h | 🔴 Cao |
| 2 | Đăng nhập | ⭐⭐ | 2-3h | 🔴 Cao |
| 3 | Quên mật khẩu | ⭐⭐ | 2-3h | 🟡 Trung |
| 4 | Sinh trắc học | ⭐⭐⭐ | 1-2h | 🟡 Trung |
| 5 | 2FA Admin | ⭐⭐⭐⭐ | 3-4h | 🔴 Cao |
| 6 | Admin Dashboard | ⭐⭐⭐ | 3-4h | 🟡 Trung |

---

## 💡 Tips khi demo

1. **Chuẩn bị script**: Viết sẵn các bước demo (register → login → 2FA → dashboard)
2. **Hiểu từng dòng**: Có thể giải thích từng dòng code khi giảng viên hỏi
3. **Biết các khái niệm**: JWT, TOTP, DTO, Provider, Riverpod, etc.
4. **Test trước**: Chạy toàn bộ flow trước khi demo
5. **Chuẩn bị câu hỏi**: Dự đoán giảng viên sẽ hỏi gì
