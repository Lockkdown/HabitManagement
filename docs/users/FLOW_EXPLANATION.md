# 🔄 Flow Hoạt động: Đăng ký & Đăng nhập

## 📌 Khái niệm cơ bản

### DTO (Data Transfer Object)
- **Là gì?** Class chứa dữ liệu từ client, có validation
- **Tại sao?** Validate dữ liệu trước khi xử lý, bảo mật
- **Ví dụ**: `RegisterDto` có Email, Username, Password, ConfirmPassword

### JWT Token (JSON Web Token)
- **Cấu trúc**: `header.payload.signature`
- **Header**: Loại token (JWT) + thuật toán (HS256)
- **Payload**: Dữ liệu (UserId, Email, Role, ExpiresIn)
- **Signature**: Chữ ký để verify token không bị thay đổi
- **Tại sao?** Stateless authentication (không cần lưu session)

### Refresh Token
- **Là gì?** Token dài hạn để lấy access token mới
- **Tại sao?** Access token hết hạn → dùng refresh token để lấy access token mới
- **Lưu ở đâu?** Database (AspNetUserTokens table)

---

## 1️⃣ FLOW ĐĂNG KÝ (Register)

### 📁 Files & Functions liên quan

#### Frontend (Flutter)
| File | Function | Mục đích |
|------|----------|---------|
| `screens/register_screen.dart` | `RegisterScreen` (Widget) | UI form đăng ký |
| `screens/register_screen.dart` | `_onRegisterPressed()` | Xử lý click button Register |
| `screens/register_screen.dart` | `_validateForm()` | Validate form client-side |
| `api/auth_api_service.dart` | `registerUser()` | Gọi API POST /api/auth/register |
| `services/auth_provider.dart` | `registerProvider` (FutureProvider) | State management cho register |
| `services/storage_service.dart` | `saveToken()` | Lưu token vào secure storage |
| `models/user_model.dart` | `User.fromJson()` | Parse JSON response thành User object |

#### Backend (.NET)
| File | Function | Mục đích |
|------|----------|---------|
| `DTOs/RegisterDto.cs` | `RegisterDto` (Class) | DTO chứa dữ liệu từ client |
| `Controllers/AuthController.cs` | `Register()` (Endpoint) | POST /api/auth/register |
| `Services/AuthService.cs` | `RegisterAsync()` | Logic xử lý đăng ký |
| `Models/User.cs` | `User` (Model) | Entity User extends IdentityUser |
| `Services/EmailService.cs` | `SendEmailAsync()` | Gửi email xác thực |

---

### 📊 Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      FRONTEND (Flutter)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. User nhập: Email, Username, Password, ConfirmPassword, Name  │
│                                                                   │
│  2. Validate form (client-side):                                 │
│     - Email format: user@example.com                             │
│     - Password length: >= 8 ký tự                               │
│     - Password match: Password == ConfirmPassword                │
│                                                                   │
│  3. Gọi API: POST /api/auth/register                            │
│     Body: {                                                      │
│       "email": "user@example.com",                              │
│       "username": "john_doe",                                   │
│       "password": "SecurePass123",                              │
│       "confirmPassword": "SecurePass123",                       │
│       "fullName": "John Doe"                                    │
│     }                                                            │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓ HTTP POST
┌─────────────────────────────────────────────────────────────────┐
│                      BACKEND (.NET)                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  4. AuthController.Register() nhận request                       │
│                                                                   │
│  5. Validate ModelState:                                         │
│     - Kiểm tra [Required], [EmailAddress], [MinLength]          │
│     - Nếu lỗi → Return 400 BadRequest                          │
│                                                                   │
│  6. Gọi AuthService.RegisterAsync(dto):                         │
│                                                                   │
│     a) Check email đã tồn tại?                                  │
│        - Query: SELECT * FROM AspNetUsers WHERE Email = ?       │
│        - Nếu tồn tại → Throw Exception "Email already exists"  │
│                                                                   │
│     b) Tạo User object:                                         │
│        var user = new User {                                    │
│          Email = dto.Email,                                     │
│          UserName = dto.Username,                               │
│          FullName = dto.FullName,                               │
│          EmailConfirmed = false,                                │
│          TwoFactorEnabled = false                               │
│        };                                                        │
│                                                                   │
│     c) Hash password + tạo user:                                │
│        var result = await userManager.CreateAsync(              │
│          user,                                                  │
│          dto.Password  // Password được hash bởi UserManager    │
│        );                                                        │
│        - UserManager sử dụng BCrypt để hash password            │
│        - Lưu vào AspNetUsers.PasswordHash                       │
│        - Nếu thất bại → Return error                            │
│                                                                   │
│     d) Assign role "User":                                      │
│        await userManager.AddToRoleAsync(user, "User");          │
│        - Thêm record vào AspNetUserRoles table                  │
│                                                                   │
│     e) Gửi email xác thực:                                      │
│        var token = await userManager                            │
│          .GenerateEmailConfirmationTokenAsync(user);            │
│        var confirmLink = $"https://frontend.com/verify?token={token}";
│        await emailService.SendEmailAsync(                       │
│          user.Email,                                            │
│          "Verify your email",                                   │
│          confirmLink                                            │
│        );                                                        │
│        - Dùng SendGrid để gửi email                             │
│                                                                   │
│     f) Return success:                                          │
│        return new { message = "Register successful" };          │
│                                                                   │
│  7. Return 201 Created                                          │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓ HTTP 201
┌─────────────────────────────────────────────────────────────────┐
│                      FRONTEND (Flutter)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  8. Nhận response 201 Created                                    │
│                                                                   │
│  9. Show success message: "Register successful! Check your email"│
│                                                                   │
│  10. Navigate to waiting_verification_screen                    │
│      - Hiển thị: "Check your email to verify"                  │
│      - User click link trong email                              │
│      - Frontend verify email (call API)                         │
│      - Redirect to login screen                                 │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### 🔍 Chi tiết từng bước Backend

#### Step 1: DTO Validation

**File**: `DTOs/RegisterDto.cs`
```csharp
public class RegisterDto
{
    [Required(ErrorMessage = "Email is required")]
    [EmailAddress(ErrorMessage = "Invalid email format")]
    public string Email { get; set; }

    [Required(ErrorMessage = "Username is required")]
    [MinLength(3, ErrorMessage = "Username must be at least 3 characters")]
    public string Username { get; set; }

    [Required(ErrorMessage = "Password is required")]
    [MinLength(8, ErrorMessage = "Password must be at least 8 characters")]
    public string Password { get; set; }

    [Required(ErrorMessage = "Confirm password is required")]
    [Compare("Password", ErrorMessage = "Passwords do not match")]
    public string ConfirmPassword { get; set; }

    [Required(ErrorMessage = "Full name is required")]
    public string FullName { get; set; }
}
```

**Validation Rules**:
- ✓ Email format hợp lệ (user@example.com)
- ✓ Username >= 3 ký tự
- ✓ Password >= 8 ký tự
- ✓ Password == ConfirmPassword

#### Step 2: Password Hashing

**File**: `Services/AuthService.cs`
```csharp
public async Task<ServiceResponse<string>> RegisterAsync(RegisterDto dto)
{
    // Check email exists
    var existingUser = await _userManager.FindByEmailAsync(dto.Email);
    if (existingUser != null)
        return new ServiceResponse<string> { Success = false, Message = "Email already exists" };

    // Create user
    var user = new User
    {
        Email = dto.Email,
        UserName = dto.Username,
        FullName = dto.FullName,
        EmailConfirmed = false,
        TwoFactorEnabled = false
    };

    // CreateAsync sẽ hash password bằng UserManager
    var result = await _userManager.CreateAsync(user, dto.Password);
    
    if (!result.Succeeded)
        return new ServiceResponse<string> 
        { 
            Success = false, 
            Message = string.Join(", ", result.Errors.Select(e => e.Description)) 
        };

    // Assign role
    await _userManager.AddToRoleAsync(user, "User");

    // Send verification email
    var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);
    await _emailService.SendVerificationEmailAsync(user.Email, user.FullName, token);

    return new ServiceResponse<string> 
    { 
        Success = true, 
        Message = "Registration successful. Please check your email to verify." 
    };
}
```

**Cách BCrypt hoạt động**:
```
Input: "SecurePass123"
↓
BCrypt Algorithm:
- Tạo salt (random): $2b$10$N9qo8uLOickgx2ZMRZoMye
- Hash password + salt
- Lặp lại 10 lần (cost factor = 10)
↓
Output: "$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcg7b3XeKeUxWdeS86E36P4/TVm2"
        (Hash này được lưu vào AspNetUsers.PasswordHash)
```

**Tại sao không lưu password gốc?**
- ✓ Nếu database bị hack, attacker không biết password gốc
- ✓ Mỗi lần login, hash password input rồi so sánh với hash trong DB
- ✓ Không thể reverse BCrypt hash (one-way function)

#### Step 3: Email Confirmation Token

**File**: `Services/EmailService.cs`
```csharp
public async Task SendVerificationEmailAsync(string email, string fullName, string token)
{
    // Encode token để an toàn khi gửi qua URL
    var encodedToken = WebEncoders.Base64UrlEncode(Encoding.UTF8.GetBytes(token));
    var verificationLink = $"{_frontendUrl}/verify-email?token={encodedToken}&email={email}";

    var htmlContent = $@"
        <h2>Welcome {fullName}!</h2>
        <p>Please verify your email by clicking the link below:</p>
        <a href='{verificationLink}'>Verify Email</a>
        <p>This link expires in 24 hours.</p>
    ";

    var msg = new SendGridMessage()
    {
        From = new EmailAddress(_fromEmail, _fromName),
        Subject = "Verify your email",
        HtmlContent = htmlContent
    };
    msg.AddTo(new EmailAddress(email, fullName));

    await _client.SendEmailAsync(msg);
}
```

**Token Properties**:
- ✓ Được tạo bởi: `userManager.GenerateEmailConfirmationTokenAsync(user)`
- ✓ Thời hạn: 24 giờ (mặc định)
- ✓ Được encode Base64Url để an toàn khi gửi qua URL
- ✓ Frontend dùng token này để verify email

#### Step 4: Role Assignment

**File**: `Services/AuthService.cs` (trong RegisterAsync)
```csharp
// Assign role "User"
await _userManager.AddToRoleAsync(user, "User");
```

**Database Operation**:
```sql
-- Thêm record vào AspNetUserRoles
INSERT INTO AspNetUserRoles (UserId, RoleId)
SELECT @UserId, Id FROM AspNetRoles WHERE Name = 'User'
```

**Kết quả**:
- ✓ User có role "User" (không phải Admin)
- ✓ Khi login, JWT token sẽ chứa claim: `Role = "User"`
- ✓ Authorization check sẽ dùng role này để quyết định quyền truy cập

---

## 2️⃣ FLOW ĐĂNG NHẬP (Login)

### 📁 Files & Functions liên quan

#### Frontend (Flutter)
| File | Function | Mục đích |
|------|----------|---------|
| `screens/login_screen.dart` | `LoginScreen` (Widget) | UI form đăng nhập |
| `screens/login_screen.dart` | `_onLoginPressed()` | Xử lý click button Login |
| `api/auth_api_service.dart` | `loginUser()` | Gọi API POST /api/auth/login |
| `services/auth_provider.dart` | `loginProvider` (FutureProvider) | State management cho login |
| `services/storage_service.dart` | `saveToken()` | Lưu access/refresh token |
| `services/storage_service.dart` | `getToken()` | Lấy token từ secure storage |
| `models/auth_response_model.dart` | `AuthResponse.fromJson()` | Parse JWT response |

#### Backend (.NET)
| File | Function | Mục đích |
|------|----------|---------|
| `DTOs/LoginDto.cs` | `LoginDto` (Class) | DTO chứa email + password |
| `DTOs/AuthResponseDto.cs` | `AuthResponseDto` (Class) | DTO response chứa tokens |
| `Controllers/AuthController.cs` | `Login()` (Endpoint) | POST /api/auth/login |
| `Services/AuthService.cs` | `LoginAsync()` | Logic xử lý đăng nhập |
| `Services/AuthService.cs` | `GenerateJwtToken()` | Tạo JWT access token |
| `Services/AuthService.cs` | `GenerateRefreshToken()` | Tạo refresh token |

---

### 📊 Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      FRONTEND (Flutter)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. User nhập: Email/Username + Password                        │
│                                                                   │
│  2. Validate form (client-side):                                │
│     - Email/Username không trống                                │
│     - Password không trống                                      │
│                                                                   │
│  3. Gọi API: POST /api/auth/login                              │
│     Body: {                                                      │
│       "email": "user@example.com",                              │
│       "password": "SecurePass123"                               │
│     }                                                            │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓ HTTP POST
┌─────────────────────────────────────────────────────────────────┐
│                      BACKEND (.NET)                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  4. AuthController.Login() nhận request                          │
│                                                                   │
│  5. Validate ModelState                                         │
│                                                                   │
│  6. Gọi AuthService.LoginAsync(dto):                           │
│                                                                   │
│     a) Tìm user bằng email:                                     │
│        var user = await userManager.FindByEmailAsync(           │
│          dto.Email                                              │
│        );                                                        │
│        - Query: SELECT * FROM AspNetUsers WHERE Email = ?       │
│        - Nếu không tìm thấy → Return error "Invalid email"     │
│                                                                   │
│     b) Verify password:                                         │
│        var passwordValid = await userManager                    │
│          .CheckPasswordAsync(user, dto.Password);               │
│        - Lấy hash từ database                                   │
│        - Hash password input                                    │
│        - So sánh 2 hash                                         │
│        - Nếu không match → Return error "Invalid password"     │
│                                                                   │
│     c) Lấy roles của user:                                      │
│        var roles = await userManager.GetRolesAsync(user);       │
│        - Query: SELECT r.Name FROM AspNetRoles r                │
│                 JOIN AspNetUserRoles ur ON r.Id = ur.RoleId    │
│                 WHERE ur.UserId = ?                             │
│        - Kết quả: ["User"] hoặc ["Admin"]                      │
│                                                                   │
│     d) Tạo JWT Access Token:                                    │
│        var claims = new List<Claim> {                           │
│          new Claim(ClaimTypes.NameIdentifier, user.Id),        │
│          new Claim(ClaimTypes.Email, user.Email),              │
│          new Claim("FullName", user.FullName),                 │
│          new Claim(ClaimTypes.Role, roles[0])                  │
│        };                                                        │
│                                                                   │
│        var key = new SymmetricSecurityKey(                      │
│          Encoding.UTF8.GetBytes(JWT_SECRET_KEY)                 │
│        );                                                        │
│        var creds = new SigningCredentials(                      │
│          key,                                                   │
│          SecurityAlgorithms.HmacSha256                          │
│        );                                                        │
│                                                                   │
│        var token = new JwtSecurityToken(                        │
│          issuer: JWT_ISSUER,                                    │
│          audience: JWT_AUDIENCE,                                │
│          claims: claims,                                        │
│          expires: DateTime.UtcNow.AddMinutes(30),               │
│          signingCredentials: creds                              │
│        );                                                        │
│                                                                   │
│        var accessToken = new JwtSecurityTokenHandler()          │
│          .WriteToken(token);                                    │
│                                                                   │
│        Kết quả Access Token:                                    │
│        eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.                  │
│        eyJuYW1laWQiOiIxMjM0NTY3ODkwIiwiZW1haWwiOiJ1c2VyQGV4YW1wbGUuY29tIiwicm9sZSI6IlVzZXIiLCJleHAiOjE2OTg3NjU0MDB9.
│        TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ
│        ↑ Header (base64)  ↑ Payload (base64)  ↑ Signature
│                                                                   │
│     e) Tạo Refresh Token:                                       │
│        var refreshToken = Guid.NewGuid().ToString();            │
│        - Lưu vào database:                                      │
│          INSERT INTO AspNetUserTokens                           │
│          (UserId, LoginProvider, Name, Value)                   │
│          VALUES (user.Id, "RefreshToken", "RefreshToken", token)
│                                                                   │
│     f) Return AuthResponseDto:                                  │
│        return new AuthResponseDto {                             │
│          AccessToken = accessToken,                             │
│          RefreshToken = refreshToken,                           │
│          User = new UserDto {                                   │
│            Id = user.Id,                                        │
│            Email = user.Email,                                  │
│            Username = user.UserName,                            │
│            FullName = user.FullName,                            │
│            Role = roles[0]                                      │
│          },                                                      │
│          ExpiresIn = 1800,  // 30 minutes in seconds            │
│          TokenType = "Bearer"                                   │
│        };                                                        │
│                                                                   │
│  7. Return 200 OK với AuthResponseDto                           │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓ HTTP 200
┌─────────────────────────────────────────────────────────────────┐
│                      FRONTEND (Flutter)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  8. Nhận response 200 OK:                                        │
│     {                                                            │
│       "accessToken": "eyJhbGciOiJIUzI1NiIs...",                │
│       "refreshToken": "a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6", │
│       "user": {                                                  │
│         "id": "user-id-123",                                    │
│         "email": "user@example.com",                            │
│         "username": "john_doe",                                 │
│         "fullName": "John Doe",                                 │
│         "role": "User"                                          │
│       },                                                         │
│       "expiresIn": 1800,                                        │
│       "tokenType": "Bearer"                                     │
│     }                                                            │
│                                                                   │
│  9. Lưu tokens vào secure storage:                              │
│     - Dùng flutter_secure_storage                               │
│     - Lưu: accessToken, refreshToken                            │
│     - Không lưu vào SharedPreferences (không an toàn)           │
│                                                                   │
│  10. Lưu user info vào state (Riverpod):                        │
│      - ref.read(currentUserProvider.notifier).state = user;     │
│                                                                   │
│  11. Navigate to home_screen                                    │
│                                                                   │
│  12. Khi gọi API khác, thêm token vào header:                  │
│      GET /api/habits                                            │
│      Headers: {                                                 │
│        "Authorization": "Bearer eyJhbGciOiJIUzI1NiIs..."       │
│      }                                                           │
│                                                                   │
│      Backend verify token:                                      │
│      - Decode JWT (verify signature)                            │
│      - Check expiration                                         │
│      - Extract claims (UserId, Role, etc.)                      │
│      - Nếu hợp lệ → Process request                            │
│      - Nếu hết hạn → Return 401 Unauthorized                   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### 🔍 Chi tiết JWT Token

#### JWT Generation Code

**File**: `Services/AuthService.cs`
```csharp
private string GenerateJwtToken(User user, IList<string> roles)
{
    var claims = new List<Claim>
    {
        new Claim(ClaimTypes.NameIdentifier, user.Id),
        new Claim(ClaimTypes.Email, user.Email),
        new Claim("FullName", user.FullName),
        new Claim(ClaimTypes.Name, user.UserName)
    };

    // Thêm role claims
    foreach (var role in roles)
    {
        claims.Add(new Claim(ClaimTypes.Role, role));
    }

    var key = new SymmetricSecurityKey(
        Encoding.UTF8.GetBytes(_jwtSettings.SecretKey)
    );
    var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

    var token = new JwtSecurityToken(
        issuer: _jwtSettings.Issuer,
        audience: _jwtSettings.Audience,
        claims: claims,
        expires: DateTime.UtcNow.AddMinutes(_jwtSettings.AccessTokenExpirationMinutes),
        signingCredentials: creds
    );

    return new JwtSecurityTokenHandler().WriteToken(token);
}
```

#### JWT Structure
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
eyJuYW1laWQiOiIxMjM0NTY3ODkwIiwiZW1haWwiOiJ1c2VyQGV4YW1wbGUuY29tIiwicm9sZSI6IlVzZXIiLCJleHAiOjE2OTg3NjU0MDB9.
TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ

↓ Decode ↓

HEADER (base64):
{
  "alg": "HS256",      // Algorithm: HMAC SHA-256
  "typ": "JWT"         // Type: JWT
}

PAYLOAD (base64):
{
  "nameid": "user-id-123",          // User ID (NameIdentifier)
  "email": "user@example.com",      // Email
  "FullName": "John Doe",           // Custom claim
  "role": "User",                   // Role
  "exp": 1698765400,                // Expiration (Unix timestamp)
  "iat": 1698761800,                // Issued at
  "iss": "HabitManagementAPI",      // Issuer
  "aud": "HabitManagementClient"    // Audience
}

SIGNATURE (HS256):
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  JWT_SECRET_KEY
)
```

#### Tại sao JWT an toàn?
```
1. Signature được tạo từ header + payload + secret_key
   - Chỉ backend biết secret_key
   - Frontend không thể tạo token giả

2. Nếu attacker thay đổi payload:
   - Signature không còn hợp lệ
   - Backend verify signature → Reject token

3. Token không thể bị decrypt (chỉ encode)
   - Không lưu sensitive data trong payload
   - Ví dụ: Không lưu password, credit card

4. Stateless authentication
   - Không cần lưu session trên server
   - Mỗi request verify token là đủ
```

#### Refresh Token Generation

**File**: `Services/AuthService.cs`
```csharp
private string GenerateRefreshToken()
{
    // Tạo random token
    var randomNumber = new byte[32];
    using (var rng = RandomNumberGenerator.Create())
    {
        rng.GetBytes(randomNumber);
        return Convert.ToBase64String(randomNumber);
    }
}

// Lưu vào database
private async Task SaveRefreshTokenAsync(User user, string refreshToken)
{
    await _userManager.SetAuthenticationTokenAsync(
        user,
        "RefreshToken",
        "RefreshToken",
        refreshToken
    );
    // Lưu vào AspNetUserTokens table
}
```

**Refresh Token Properties**:
- ✓ Random 32-byte string
- ✓ Thời hạn: 7 ngày
- ✓ Lưu trong database (AspNetUserTokens)
- ✓ Dùng để lấy access token mới khi hết hạn

---

## 3️⃣ FLOW TỔNG QUÁT

### Sequence Diagram

```
User                Frontend              Backend              Database
 │                    │                     │                    │
 ├─ Input Email ─────>│                     │                    │
 │  + Password        │                     │                    │
 │                    │                     │                    │
 │                    ├─ POST /register ───>│                    │
 │                    │  (RegisterDto)      │                    │
 │                    │                     ├─ Validate ────────>│
 │                    │                     │  Email exists?     │
 │                    │                     │<─ No ─────────────┤
 │                    │                     │                    │
 │                    │                     ├─ Hash Password    │
 │                    │                     │  (BCrypt)         │
 │                    │                     │                    │
 │                    │                     ├─ Create User ────>│
 │                    │                     │  + Role           │
 │                    │                     │<─ Success ────────┤
 │                    │                     │                    │
 │                    │                     ├─ Send Email       │
 │                    │                     │  (Verification)   │
 │                    │                     │                    │
 │                    │<─ 201 Created ─────┤                    │
 │                    │  (Success message) │                    │
 │<─ Show Success ────┤                     │                    │
 │                    │                     │                    │
 ├─ Click Email Link ─────────────────────────────────────────>│
 │  (Verify Email)    │                     │                    │
 │                    │                     │                    │
 ├─ Input Email ─────>│                     │                    │
 │  + Password        │                     │                    │
 │                    │                     │                    │
 │                    ├─ POST /login ──────>│                    │
 │                    │  (LoginDto)         │                    │
 │                    │                     ├─ Find User ──────>│
 │                    │                     │  by Email         │
 │                    │                     │<─ User Data ──────┤
 │                    │                     │                    │
 │                    │                     ├─ Verify Password  │
 │                    │                     │  (BCrypt Compare) │
 │                    │                     │                    │
 │                    │                     ├─ Get Roles ──────>│
 │                    │                     │  from DB          │
 │                    │                     │<─ Roles ──────────┤
 │                    │                     │                    │
 │                    │                     ├─ Create JWT Token │
 │                    │                     │  (Access + Claims)│
 │                    │                     │                    │
 │                    │                     ├─ Create Refresh ─>│
 │                    │                     │  Token + Save DB  │
 │                    │                     │<─ Success ────────┤
 │                    │                     │                    │
 │                    │<─ 200 OK ──────────┤                    │
 │                    │  (AuthResponseDto) │                    │
 │                    │  - AccessToken     │                    │
 │                    │  - RefreshToken    │                    │
 │                    │  - User Info       │                    │
 │<─ Login Success ───┤                     │                    │
 │                    │                     │                    │
 │                    ├─ Save Tokens ─────>│ (Secure Storage)   │
 │                    │  (Secure Storage)  │                    │
 │                    │                     │                    │
 │                    ├─ Navigate Home ───>│                    │
 │                    │                     │                    │
 ├─ View Habits ─────>│                     │                    │
 │                    │                     │                    │
 │                    ├─ GET /habits ─────>│                    │
 │                    │  Header:           │                    │
 │                    │  Authorization:    │                    │
 │                    │  Bearer {token}    │                    │
 │                    │                     ├─ Verify Token ───>│
 │                    │                     │  (Decode JWT)     │
 │                    │                     │<─ Valid ──────────┤
 │                    │                     │                    │
 │                    │                     ├─ Get Habits ─────>│
 │                    │                     │  for User         │
 │                    │                     │<─ Habits ─────────┤
 │                    │                     │                    │
 │                    │<─ 200 OK ──────────┤                    │
 │                    │  (Habits List)     │                    │
 │<─ Show Habits ─────┤                    │                    │
 │                    │                    │                    │
```

---

## 4️⃣ FRONTEND IMPLEMENTATION DETAILS

### 📱 Login Screen Flow

**File**: `screens/login_screen.dart`
```dart
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginAsyncValue = ref.watch(loginProvider);

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
              onPressed: _onLoginPressed,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  void _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    final response = await ref.read(loginProvider(
      email: _emailController.text,
      password: _passwordController.text,
    ).future);

    // Lưu token
    await ref.read(storageServiceProvider).saveToken(
      response.accessToken,
      response.refreshToken,
    );

    // Lưu user vào state
    ref.read(currentUserProvider.notifier).state = response.user;

    // Navigate to home
    Navigator.pushReplacementNamed(context, '/home');
  }
}
```

### 🔐 Storage Service

**File**: `services/storage_service.dart`
```dart
class StorageService {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> saveToken(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  Future<void> deleteTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }
}
```

### 📡 API Service

**File**: `api/auth_api_service.dart`
```dart
class AuthApiService {
  final http.Client _httpClient;
  final String _baseUrl;

  Future<AuthResponse> loginUser(String email, String password) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Invalid email or password');
    } else {
      throw Exception('Login failed');
    }
  }

  // Gọi API với token
  Future<List<Habit>> getHabits(String accessToken) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/api/habits'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((h) => Habit.fromJson(h)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Token expired');
    } else {
      throw Exception('Failed to fetch habits');
    }
  }
}
```

### 🔄 State Management

**File**: `services/auth_provider.dart`
```dart
// Login provider
final loginProvider = FutureProvider.family<AuthResponse, LoginParams>(
  (ref, params) async {
    final authService = ref.watch(authApiServiceProvider);
    return authService.loginUser(params.email, params.password);
  },
);

// Current user provider
final currentUserProvider = StateProvider<User?>((ref) => null);

// Access token provider
final accessTokenProvider = FutureProvider<String?>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.getAccessToken();
});
```

---

## 4️⃣ KEY CONCEPTS

### 🔐 Password Security
```
❌ KHÔNG LÀM:
- Lưu password gốc trong database
- Dùng MD5 hoặc SHA1 (dễ crack)
- Dùng password giống nhau cho tất cả users

✅ LÀM:
- Hash password bằng BCrypt (cost factor 10+)
- Mỗi user có salt khác nhau
- Verify bằng cách hash input rồi so sánh
```

### 🎫 Token Management

**File**: `Controllers/AuthController.cs`
```csharp
[HttpPost("login")]
public async Task<IActionResult> Login([FromBody] LoginDto dto)
{
    if (!ModelState.IsValid)
        return BadRequest(ModelState);

    var result = await _authService.LoginAsync(dto);
    
    if (!result.Success)
        return Unauthorized(new { message = result.Message });

    return Ok(result.Data); // AuthResponseDto
}
```

**File**: `Services/AuthService.cs`
```csharp
public async Task<ServiceResponse<AuthResponseDto>> LoginAsync(LoginDto dto)
{
    // Find user
    var user = await _userManager.FindByEmailAsync(dto.Email);
    if (user == null)
        return new ServiceResponse<AuthResponseDto> 
        { 
            Success = false, 
            Message = "Invalid email or password" 
        };

    // Verify password
    var passwordValid = await _userManager.CheckPasswordAsync(user, dto.Password);
    if (!passwordValid)
        return new ServiceResponse<AuthResponseDto> 
        { 
            Success = false, 
            Message = "Invalid email or password" 
        };

    // Get roles
    var roles = await _userManager.GetRolesAsync(user);

    // Generate tokens
    var accessToken = GenerateJwtToken(user, roles);
    var refreshToken = GenerateRefreshToken();

    // Save refresh token
    await SaveRefreshTokenAsync(user, refreshToken);

    // Return response
    var response = new AuthResponseDto
    {
        AccessToken = accessToken,
        RefreshToken = refreshToken,
        User = new UserDto
        {
            Id = user.Id,
            Email = user.Email,
            Username = user.UserName,
            FullName = user.FullName,
            Role = roles.FirstOrDefault()
        },
        ExpiresIn = 1800, // 30 minutes
        TokenType = "Bearer"
    };

    return new ServiceResponse<AuthResponseDto> 
    { 
        Success = true, 
        Data = response 
    };
}
```

**Token Lifecycle**:
```
Access Token:
- Thời hạn: 30 phút
- Dùng để: Gọi API
- Lưu ở: Secure Storage (Flutter)
- Gửi ở: Authorization header
- Khi hết hạn: Dùng refresh token để lấy cái mới

Refresh Token:
- Thời hạn: 7 ngày
- Dùng để: Lấy access token mới
- Lưu ở: Database (AspNetUserTokens) + Secure Storage
- Khi hết hạn: User phải login lại
```

### 🛡️ Security Best Practices
```
1. HTTPS only (không HTTP)
2. Secure Storage cho tokens (không SharedPreferences)
3. CORS configuration (chỉ cho phép frontend domain)
4. Rate limiting (chống brute force)
5. Input validation (DTO validation)
6. SQL injection prevention (Parameterized queries)
7. CSRF protection (nếu dùng cookies)
```

---

## 5️⃣ COMMON ERRORS & SOLUTIONS

### Error: "Invalid email"
```
Nguyên nhân: Email không tồn tại trong database
Giải pháp: 
- Check email đúng không
- Verify email đã confirm chưa
```

### Error: "Invalid password"
```
Nguyên nhân: Password không match
Giải pháp:
- Check password đúng không
- Caps lock bật không
```

### Error: "Email already exists"
```
Nguyên nhân: Email đã được đăng ký
Giải pháp:
- Dùng email khác
- Hoặc reset password nếu quên
```

### Error: "Token expired"
```
Nguyên nhân: Access token hết hạn
Giải pháp:
- Dùng refresh token để lấy access token mới
- Hoặc login lại
```

### Error: "Unauthorized (401)"
```
Nguyên nhân: Token không hợp lệ hoặc không có
Giải pháp:
- Check Authorization header
- Verify token format: "Bearer {token}"
- Refresh token nếu hết hạn
```

---

## 📝 Tóm tắt

### Đăng ký (Register)
1. Frontend: Validate form + gửi API
2. Backend: Validate DTO + hash password + tạo user + gửi email
3. Frontend: Show success + navigate to verification

### Đăng nhập (Login)
1. Frontend: Validate form + gửi API
2. Backend: Verify password + tạo JWT token + return tokens
3. Frontend: Lưu tokens + navigate to home
4. Khi gọi API: Gửi token trong Authorization header
5. Backend: Verify token + process request

### Security
- Password: Hash bằng BCrypt
- Token: JWT (stateless)
- Storage: Secure Storage (Flutter)
- Communication: HTTPS
