# 🔐 Giải thích Chi tiết Flow Đăng nhập: Frontend → Backend

## 📋 Mục lục
1. [Cấu trúc Files & Packages](#cấu-trúc-files--packages)
2. [Flow Hoạt động Chi tiết](#flow-hoạt-động-chi-tiết)
3. [Frontend Implementation](#frontend-implementation)
4. [Backend Implementation](#backend-implementation)
5. [Token Management](#token-management)
6. [Security Considerations](#security-considerations)

---

## 🗂️ Cấu trúc Files & Packages

### Frontend Packages (Flutter)

| Package | Phiên bản | Mục đích | Liên quan đến Token |
|---------|----------|---------|-------------------|
| **flutter_secure_storage** | ^9.2.4 | ✅ **Lưu token an toàn** | Encrypt & lưu access/refresh token |
| **http** | ^1.5.0 | Gọi API | Gửi request đến backend |
| **flutter_riverpod** | ^3.0.3 | State management | Quản lý auth state |
| **flutter_dotenv** | ^5.2.1 | Load .env file | Lấy API_BASE_URL |
| **local_auth** | ^3.0.0 | Biometric auth | Xác thực sinh trắc học (Quick Login) |

### Backend Packages (.NET)

| Package | Phiên bản | Mục đích | Liên quan đến Token |
|---------|----------|---------|-------------------|
| **Microsoft.AspNetCore.Identity.EntityFrameworkCore** | 9.0.10 | ✅ **Quản lý user & password** | UserManager, SignInManager |
| **Microsoft.AspNetCore.Authentication.JwtBearer** | 9.0.10 | ✅ **JWT authentication** | Verify JWT token |
| **System.IdentityModel.Tokens.Jwt** | (built-in) | ✅ **Tạo JWT token** | JwtSecurityToken, JwtSecurityTokenHandler |
| **Microsoft.IdentityModel.Tokens** | (built-in) | ✅ **Signing JWT** | SymmetricSecurityKey, SigningCredentials |

---

## 🔄 Flow Hoạt động Chi tiết

### 📊 Diagram Tổng Quát

```
┌─────────────────────────────────────────────────────────────────┐
│                    FRONTEND (Flutter)                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. LoginScreen: User nhập email + password                     │
│     ↓                                                             │
│  2. _handleLogin() validate form                                │
│     ↓                                                             │
│  3. AuthApiService.loginWith2FA(email, password)                │
│     ↓                                                             │
│  4. HTTP POST /api/auth/login                                   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                         ↓ HTTP Request
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND (.NET)                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  5. AuthController.Login() nhận request                         │
│     ↓                                                             │
│  6. AuthService.LoginAsync()                                    │
│     - FindByEmailAsync() → Tìm user                             │
│     - CheckPasswordSignInAsync() → Verify password              │
│     - GenerateAccessTokenAsync() → Tạo JWT access token         │
│     - GenerateRefreshTokenAsync() → Tạo JWT refresh token       │
│     ↓                                                             │
│  7. Return AuthResponseDto (tokens + user info)                 │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                    ↓ HTTP Response (200 OK)
┌─────────────────────────────────────────────────────────────────┐
│                    FRONTEND (Flutter)                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  8. AuthResponseModel.fromJson() → Parse response               │
│     ↓                                                             │
│  9. StorageService.saveAccessToken() → Lưu access token        │
│     StorageService.saveRefreshToken() → Lưu refresh token      │
│     StorageService.saveUserInfo() → Lưu user info              │
│     ↓                                                             │
│  10. AuthProvider.state = AuthState.authenticated()             │
│      ↓                                                             │
│  11. Navigate to HomeScreen                                     │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎯 Frontend Implementation

### Step 1: LoginScreen - UI & Input

**File**: `screens/login_screen.dart` (Lines 1-50)

```dart
class LoginScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _authApiService = AuthApiService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Build UI với TextField cho email & password
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Email required';
                if (!value!.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Password required';
                return null;
              },
            ),
            ElevatedButton(
              onPressed: _handleLogin,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Step 2: Validate Form & Call API

**File**: `screens/login_screen.dart` (Lines 157-173)

```dart
Future<void> _handleLogin() async {
  // Validate form
  if (!_formKey.currentState!.validate()) {
    return;  // Form không hợp lệ, dừng lại
  }

  // Bắt đầu loading
  setState(() {
    _isLoading = true;
  });

  try {
    // Gọi API đăng nhập
    final response = await _authApiService.loginWith2FA(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    // Xử lý response (sẽ giải thích ở dưới)
    // ...
  } catch (e) {
    AppNotification.showError(context, 'Lỗi: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
```

**Giải thích**:
- `_formKey.currentState!.validate()` - Validate tất cả TextFormField
- `_emailController.text.trim()` - Lấy email, xóa khoảng trắng
- `_authApiService.loginWith2FA()` - Gọi API service

---

### Step 3: AuthApiService - Gọi Backend API

**File**: `api/auth_api_service.dart` (Lines 64-91)

```dart
class AuthApiService {
  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:5224';

  /// Đăng nhập người dùng
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      // Gửi HTTP POST request
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Thành công → Parse thành AuthResponseModel
        return AuthResponseModel.fromJson(data);
      } else {
        // Thất bại → Throw exception
        throw Exception(data['message'] ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}
```

**HTTP Request gửi đi**:
```
POST http://localhost:5224/api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "SecurePass123"
}
```

---

### Step 4: Parse Response & Save Tokens

**File**: `models/auth_response_model.dart` (Lines 25-33)

```dart
class AuthResponseModel {
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: UserModel.fromJson(json),
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
```

**Backend Response (200 OK)**:
```json
{
  "userId": "user-123",
  "username": "john_doe",
  "email": "john@example.com",
  "fullName": "John Doe",
  "themePreference": "dark",
  "languageCode": "vi",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresAt": "2025-10-30T20:30:00Z"
}
```

---

### Step 5: StorageService - Lưu Token An Toàn

**File**: `services/storage_service.dart` (Lines 1-60)

```dart
class StorageService {
  /// Dùng FlutterSecureStorage để encrypt & lưu token
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';
  static const String _fullNameKey = 'full_name';

  /// Lưu Access Token (mã hóa)
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// Lấy Access Token (giải mã)
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Lưu Refresh Token (mã hóa)
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Lấy Refresh Token (giải mã)
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Lưu toàn bộ thông tin user
  Future<void> saveUserInfo({
    required String userId,
    required String username,
    required String email,
    required String fullName,
    required String themePreference,
    required String languageCode,
  }) async {
    await Future.wait([
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _usernameKey, value: username),
      _storage.write(key: _emailKey, value: email),
      _storage.write(key: _fullNameKey, value: fullName),
      _storage.write(key: _themePreferenceKey, value: themePreference),
      _storage.write(key: _languageCodeKey, value: languageCode),
    ]);
  }
}
```

**Lưu ý**:
- `FlutterSecureStorage` **encrypt dữ liệu** trước khi lưu
- Trên Android: Dùng Android Keystore
- Trên iOS: Dùng Keychain
- Không bao giờ lưu token ở SharedPreferences (plain text)

**Nơi lưu token**:
```
Android: /data/data/com.example.app/shared_prefs/
iOS: ~/Library/Preferences/com.example.app.plist (Keychain)
```

---

### Step 6: Update AuthProvider State

**File**: `screens/login_screen.dart` (Lines 234-244)

```dart
// CẬP NHẬT AUTHPROVIDER STATE
final authNotifier = ref.read(authProvider.notifier);
final userModel = UserModel(
  userId: response.user!['userId'] ?? '',
  username: response.user!['username'] ?? '',
  email: response.user!['email'] ?? '',
  fullName: response.user!['fullName'] ?? '',
  themePreference: response.user!['themePreference'] ?? 'dark',
  languageCode: response.user!['languageCode'] ?? 'vi',
);
authNotifier.state = AuthState.authenticated(userModel);
```

**Giải thích**:
- `ref.read(authProvider.notifier)` - Lấy notifier của auth provider
- `.state = AuthState.authenticated(userModel)` - Cập nhật state
- Tất cả widget dùng `ref.watch(authProvider)` sẽ được rebuild

---

### Step 7: Navigate to Home

**File**: `screens/login_screen.dart` (Lines 246-254)

```dart
if (!mounted) return;

// Hiển thị thông báo thành công
AppNotification.showSuccess(context, 'Đăng nhập thành công!');

// Navigate đến HomeScreen
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (context) => const HomeScreen()),
);
```

---

## 🔧 Backend Implementation

### Step 1: AuthController - Nhận Request

**File**: `controllers/AuthController.cs` (Lines 66-80)

```csharp
[HttpPost("login")]
public async Task<IActionResult> Login([FromBody] LoginDto loginDto)
{
    try
    {
        // Gọi service để xác thực và tạo tokens
        var response = await _authService.LoginAsync(loginDto);

        if (response == null)
        {
            return Unauthorized(new { message = "Email hoặc mật khẩu không đúng" });
        }

        return Ok(response);
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Lỗi khi đăng nhập");
        return StatusCode(500, new { message = "Có lỗi xảy ra" });
    }
}
```

**Giải thích**:
- `[HttpPost("login")]` - Endpoint: POST /api/auth/login
- `[FromBody] LoginDto loginDto` - Nhận JSON body, parse thành LoginDto
- `_authService.LoginAsync()` - Gọi service để xử lý logic

---

### Step 2: LoginDto - Validation

**File**: `DTOs/LoginDto.cs`

```csharp
public class LoginDto
{
    [Required(ErrorMessage = "Email is required")]
    [EmailAddress(ErrorMessage = "Invalid email format")]
    public string Email { get; set; }

    [Required(ErrorMessage = "Password is required")]
    [MinLength(6, ErrorMessage = "Password must be at least 6 characters")]
    public string Password { get; set; }
}
```

**Validation tự động**:
- `[Required]` - Email không được để trống
- `[EmailAddress]` - Email phải đúng format
- Nếu validation fail → Return 400 BadRequest

---

### Step 3: AuthService.LoginAsync() - Main Logic

**File**: `services/AuthService.cs` (Lines 103-142)

```csharp
public async Task<AuthResponseDto?> LoginAsync(LoginDto loginDto)
{
    // Step 1: Tìm user theo email
    var user = await _userManager.FindByEmailAsync(loginDto.Email);
    if (user == null)
    {
        return null;  // Email không tồn tại
    }

    // Step 2: Verify password
    var result = await _signInManager.CheckPasswordSignInAsync(
        user, 
        loginDto.Password, 
        lockoutOnFailure: false
    );
    if (!result.Succeeded)
    {
        return null;  // Password sai
    }

    // Step 3: Tạo Access Token
    var accessToken = await GenerateAccessTokenAsync(user);

    // Step 4: Tạo Refresh Token
    var refreshToken = await GenerateRefreshTokenAsync(user);

    // Step 5: Tính thời gian hết hạn
    var expirationMinutes = int.Parse(
        Environment.GetEnvironmentVariable("JWT_ACCESS_TOKEN_EXPIRATION_MINUTES") ?? "30"
    );
    var expiresAt = DateTime.UtcNow.AddMinutes(expirationMinutes);

    // Step 6: Return response
    return new AuthResponseDto
    {
        UserId = user.Id,
        Username = user.UserName!,
        Email = user.Email!,
        FullName = user.FullName,
        ThemePreference = user.ThemePreference,
        LanguageCode = user.LanguageCode,
        AccessToken = accessToken,
        RefreshToken = refreshToken,
        ExpiresAt = expiresAt
    };
}
```

**Các hàm có sẵn**:

| Hàm | Thư viện | Mục đích |
|-----|---------|---------|
| `FindByEmailAsync()` | `UserManager<T>` | Tìm user theo email |
| `CheckPasswordSignInAsync()` | `SignInManager<T>` | Verify password |

---

### Step 4: GenerateAccessTokenAsync() - Tạo JWT

**File**: `services/AuthService.cs` (Lines 149-186)

```csharp
private async Task<string> GenerateAccessTokenAsync(User user)
{
    // Step 1: Lấy roles
    var roles = await _userManager.GetRolesAsync(user);

    // Step 2: Tạo claims
    var claims = new List<Claim>
    {
        new(ClaimTypes.NameIdentifier, user.Id),
        new(ClaimTypes.Name, user.UserName!),
        new(ClaimTypes.Email, user.Email!),
        new("FullName", user.FullName),
    };
    claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));

    // Step 3: Tạo signing key
    var secretKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY")!;
    var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
    var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

    // Step 4: Lấy config
    var issuer = Environment.GetEnvironmentVariable("JWT_ISSUER");
    var audience = Environment.GetEnvironmentVariable("JWT_AUDIENCE");
    var expirationMinutes = int.Parse(
        Environment.GetEnvironmentVariable("JWT_ACCESS_TOKEN_EXPIRATION_MINUTES") ?? "30"
    );

    // Step 5: Tạo JWT token
    var token = new JwtSecurityToken(
        issuer: issuer,
        audience: audience,
        claims: claims,
        expires: DateTime.UtcNow.AddMinutes(expirationMinutes),
        signingCredentials: credentials
    );

    // Step 6: Convert thành string
    return new JwtSecurityTokenHandler().WriteToken(token);
}
```

**Các class/method từ thư viện**:

| Class/Method | Thư viện | Mục đích |
|--------------|---------|---------|
| `Claim` | `System.Security.Claims` | Thông tin nhúng vào token |
| `SymmetricSecurityKey` | `Microsoft.IdentityModel.Tokens` | Key để sign JWT |
| `SigningCredentials` | `Microsoft.IdentityModel.Tokens` | Credentials chứa key + algorithm |
| `JwtSecurityToken` | `System.IdentityModel.Tokens.Jwt` | Tạo JWT token object |
| `JwtSecurityTokenHandler().WriteToken()` | `System.IdentityModel.Tokens.Jwt` | Convert JWT object → string |

---

### Step 5: GenerateRefreshTokenAsync() - Tạo Refresh Token

**File**: `services/AuthService.cs` (Lines 193-230)

```csharp
private async Task<string> GenerateRefreshTokenAsync(User user)
{
    // Giống như GenerateAccessTokenAsync nhưng:
    // 1. Claims tối giản (chỉ cần userId)
    // 2. Expiration dài hơn (7 ngày thay vì 30 phút)

    var roles = await _userManager.GetRolesAsync(user);

    var claims = new List<Claim>
    {
        new(ClaimTypes.NameIdentifier, user.Id),
        new(ClaimTypes.Name, user.UserName!),
        new(ClaimTypes.Email, user.Email!),
    };
    claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));

    var secretKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY")!;
    var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
    var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

    var issuer = Environment.GetEnvironmentVariable("JWT_ISSUER");
    var audience = Environment.GetEnvironmentVariable("JWT_AUDIENCE");
    var expirationDays = int.Parse(
        Environment.GetEnvironmentVariable("JWT_REFRESH_TOKEN_EXPIRATION_DAYS") ?? "7"
    );

    var token = new JwtSecurityToken(
        issuer: issuer,
        audience: audience,
        claims: claims,
        expires: DateTime.UtcNow.AddDays(expirationDays),  // ← 7 ngày
        signingCredentials: credentials
    );

    return new JwtSecurityTokenHandler().WriteToken(token);
}
```

---

## 🎫 Token Management

### Access Token vs Refresh Token

| Thuộc tính | Access Token | Refresh Token |
|-----------|--------------|---------------|
| **Thời hạn** | 30 phút | 7 ngày |
| **Mục đích** | Gọi API | Lấy access token mới |
| **Lưu ở** | Secure Storage | Secure Storage + Database |
| **Gửi ở** | Authorization header | Khi access token hết hạn |
| **Claims** | Đầy đủ (userId, email, role, fullName) | Tối giản (userId, email, role) |

### Cách sử dụng Token

**Frontend gọi API với Access Token**:
```dart
// Lấy token từ storage
final accessToken = await storageService.getAccessToken();

// Gửi request với Authorization header
final response = await http.get(
  Uri.parse('$_baseUrl/api/habits'),
  headers: {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  },
);
```

**Backend verify Token**:
```csharp
[Authorize]  // Middleware tự động verify token
[HttpGet("habits")]
public async Task<IActionResult> GetHabits()
{
    // Lấy userId từ claims
    var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    
    // Lấy role từ claims
    var role = User.FindFirst(ClaimTypes.Role)?.Value;
    
    // ...
}
```

---

## 🛡️ Security Considerations

### 1. Token Storage

**❌ KHÔNG LÀM**:
```dart
// Lưu token ở SharedPreferences (plain text)
await prefs.setString('access_token', token);
```

**✅ LÀM**:
```dart
// Lưu token ở FlutterSecureStorage (encrypted)
await _storage.write(key: 'access_token', value: token);
```

### 2. Password Verification

**Backend**:
```csharp
// UserManager tự động hash password
var result = await _userManager.CheckPasswordAsync(user, password);
// Không bao giờ so sánh password gốc
```

### 3. JWT Secret Key

**❌ KHÔNG LÀM**:
```env
JWT_SECRET_KEY=simple-key
```

**✅ LÀM**:
```env
JWT_SECRET_KEY=aB3cD4eF5gH6iJ7kL8mN9oP0qR1sT2uV3wX4yZ5aB6cD7eF8gH9iJ0kL1mN2oP3
```

- Secret key phải >= 32 ký tự
- Không được commit vào git
- Khác nhau cho mỗi environment (dev, staging, production)

### 4. HTTPS Only

**❌ KHÔNG LÀM**:
```
http://localhost:5224/api/auth/login
```

**✅ LÀM**:
```
https://api.habitmanagement.com/api/auth/login
```

---

## 📊 Tóm tắt Flow

```
1. User nhập email + password ở LoginScreen
   ↓
2. _handleLogin() validate form
   ↓
3. AuthApiService.login() gửi HTTP POST /api/auth/login
   ↓
4. AuthController.Login() nhận request
   ↓
5. AuthService.LoginAsync():
   - FindByEmailAsync() → Tìm user
   - CheckPasswordSignInAsync() → Verify password
   - GenerateAccessTokenAsync() → Tạo JWT access token
   - GenerateRefreshTokenAsync() → Tạo JWT refresh token
   ↓
6. Return AuthResponseDto (tokens + user info)
   ↓
7. Frontend nhận response:
   - AuthResponseModel.fromJson() → Parse JSON
   - StorageService.saveAccessToken() → Lưu access token (encrypted)
   - StorageService.saveRefreshToken() → Lưu refresh token (encrypted)
   - StorageService.saveUserInfo() → Lưu user info
   ↓
8. AuthProvider.state = AuthState.authenticated()
   ↓
9. Navigate to HomeScreen
```

---

## 🎓 Khi demo, giảng viên có thể hỏi:

**Q: "Flow đăng nhập là gì?"**
A: User nhập email + password → Frontend gọi API → Backend verify → Tạo 2 tokens → Frontend lưu token → Navigate home

**Q: "Tại sao cần 2 tokens?"**
A: Access token ngắn hạn (30 phút) để gọi API, Refresh token dài hạn (7 ngày) để lấy access token mới

**Q: "Frontend dùng package nào để lưu token?"**
A: `flutter_secure_storage` - Encrypt & lưu token an toàn

**Q: "Backend dùng thư viện nào để tạo JWT?"**
A: `System.IdentityModel.Tokens.Jwt` (JwtSecurityToken) + `Microsoft.IdentityModel.Tokens` (SymmetricSecurityKey)

**Q: "Tại sao không lưu token ở SharedPreferences?"**
A: Vì SharedPreferences lưu plain text, không an toàn. FlutterSecureStorage encrypt dữ liệu

**Q: "Nếu access token hết hạn sao?"**
A: Frontend dùng refresh token để lấy access token mới từ backend

---

## 📁 File Structure

```
frontend/
├── lib/
│   ├── screens/
│   │   └── login_screen.dart          ← UI + Logic đăng nhập
│   ├── api/
│   │   └── auth_api_service.dart      ← Gọi API backend
│   ├── models/
│   │   ├── auth_response_model.dart   ← Parse response
│   │   └── user_model.dart
│   └── services/
│       ├── storage_service.dart       ← Lưu token (encrypted)
│       └── auth_provider.dart         ← State management
│
backend/
├── Controllers/
│   └── AuthController.cs              ← Endpoint /api/auth/login
├── Services/
│   └── AuthService.cs                 ← Logic: verify + tạo tokens
├── Models/
│   └── DTOs/
│       ├── LoginDto.cs                ← Validation
│       └── AuthResponseDto.cs         ← Response
└── .env                               ← JWT config
```

---

**Tạo bởi**: Cascade AI
**Ngày**: Oct 30, 2025
**Phiên bản**: 1.0
