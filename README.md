# 🎯 Habit Management - Ứng dụng Quản lý Thói quen

## Đây là đồ án môn học của môn "Lập trình trên thiết bị di động" 

## 👨‍💻 Đội ngũ phát triển

- **Trương Hoàng Phúc** - Frontend & Backend: splash, login/register, forgot password, admin dashboard, user management.
- **Nguyễn Trịnh Lân** - Frontend & Backend: add/edit/delete habits, category.
- **Hoàng Viết Nguyên** - Frontend & Backend: schedule habits, habit complete, add habits, chatbot, speech to text.
- **Ngô Xuân Hạo** - Frontend & Backend: setting user, statistics.


---

## 📋 Mục lục

- [Tính năng](#-tính-năng)
- [Công nghệ sử dụng](#-công-nghệ-sử-dụng)
- [Yêu cầu hệ thống](#-yêu-cầu-hệ-thống)
- [Cài đặt](#-cài-đặt)
- [Cấu hình](#️-cấu-hình)
- [Chạy ứng dụng](#-chạy-ứng-dụng)
- [Cấu trúc project](#-cấu-trúc-project)
- [API Documentation](#-api-documentation)
- [Tài liệu chi tiết](#-tài-liệu-chi-tiết)

---

## ✨ Tính năng

### Xác thực & Bảo mật
- ✅ Đăng ký tài khoản với xác thực email
- ✅ Đăng nhập với JWT (Access Token + Refresh Token)
- ✅ Quên mật khẩu với email verification
- ✅ Đăng nhập sinh trắc học (vân tay/khuôn mặt) - Quick Login
- ✅ Two-Factor Authentication (2FA/TOTP) cho Admin
- ✅ Phân quyền User/Admin với Authorization

### Quản lý Thói quen
- ✅ Tạo/Sửa/Xóa thói quen
- ✅ Phân loại thói quen theo Category (màu sắc & icon)
- ✅ Lịch trình thói quen (Daily/Weekly/Monthly/Custom)
- ✅ Đánh dấu hoàn thành thói quen
- ✅ Ghi chú/Journal cho mỗi lần hoàn thành
- ✅ Calendar view với heatmap
- ✅ Thống kê & phân tích chi tiết

### Admin Dashboard
- ✅ Quản lý danh sách Users
- ✅ Cập nhật vai trò User/Admin
- ✅ Tạo tài khoản Admin với 2FA bắt buộc
- ✅ Xem thống kê hệ thống

### Giao diện & Trải nghiệm
- ✅ Theme sáng/tối/theo hệ thống
- ✅ Đa ngôn ngữ (Tiếng Việt/Tiếng Anh)
- ✅ Responsive design
- ✅ Material Design 3
- ✅ Charts & Analytics (fl_chart)
- ✅ Elegant notifications
- ✅ Loading animations (SpinKit)
- ✅ Icon library (Lucide Icons)

### Import/Export
- ✅ Export dữ liệu thói quen
- ✅ Import dữ liệu
- ✅ Share habits
- ✅ Backup & restore

---

## 🛠 Công nghệ sử dụng

### Backend
- **Framework**: ASP.NET Core 9.0.10
- **Database**: SQL Server (Entity Framework Core 9.0.10)
- **Authentication**: ASP.NET Core Identity + JWT Bearer
- **2FA/TOTP**: Otp.NET, QRCoder
- **Password Hashing**: BCrypt.Net-Next
- **Email**: SendGrid 9.29.3
- **SMS**: Twilio 7.13.5
- **Logging**: Serilog 4.3.0
- **API Documentation**: Swagger/OpenAPI

### Frontend
- **Framework**: Flutter 3.9.2+
- **Dart SDK**: 3.9.2+
- **State Management**: Riverpod 3.0.3 + Provider 6.1.2
- **HTTP Client**: http 1.5.0
- **Secure Storage**: flutter_secure_storage 9.2.4
- **Biometrics**: local_auth 3.0.0, local_auth_android 2.0.0
- **Charts**: fl_chart 0.69.0
- **Calendar**: flutter_heatmap_calendar 1.0.5, easy_date_timeline 2.0.9
- **File Operations**: file_picker 8.1.4, share_plus 10.1.2, path_provider 2.1.5
- **UI/UX**: Lucide Icons, Flutter Animate, SpinKit, Elegant Notification

---

## 📦 Backend Dependencies

### NuGet Packages chính

```xml
<!-- ASP.NET Core & Identity -->
<PackageReference Include="Microsoft.AspNetCore.Identity.EntityFrameworkCore" Version="9.0.10" />
<PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="9.0.10" />
<PackageReference Include="Microsoft.AspNetCore.OpenApi" Version="9.0.9" />

<!-- Entity Framework Core -->
<PackageReference Include="Microsoft.EntityFrameworkCore" Version="9.0.10" />
<PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="9.0.10" />
<PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="9.0.10" />

<!-- Security & 2FA -->
<PackageReference Include="BCrypt.Net-Next" Version="4.0.3" />
<PackageReference Include="Otp.NET" Version="1.4.0" />
<PackageReference Include="QRCoder" Version="1.7.0" />

<!-- Communication -->
<PackageReference Include="SendGrid" Version="9.29.3" />

<!-- Logging -->
<PackageReference Include="Serilog" Version="4.3.0" />
<PackageReference Include="Serilog.AspNetCore" Version="9.0.0" />

<!-- Configuration -->
<PackageReference Include="Microsoft.Extensions.Configuration.EnvironmentVariables" Version="9.0.10" />
<PackageReference Include="dotenv.net" Version="4.0.0" />
<PackageReference Include="DotNetEnv" Version="3.1.1" />

<!-- Swagger/OpenAPI -->
<PackageReference Include="Swashbuckle.AspNetCore" Version="9.0.6" />
```

### Cài đặt packages

```bash
cd backend

# Restore tất cả packages từ .csproj
dotnet restore

# Hoặc cài từng package nếu cần
dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package SendGrid
dotnet add package BCrypt.Net-Next
dotnet add package Otp.NET
```

### Kiểm tra packages đã cài

```bash
# Liệt kê tất cả packages
dotnet list package

# Kiểm tra package cụ thể
dotnet list package --include-transitive
```

---

## 📱 Frontend Dependencies

### Flutter Packages chính

```yaml
dependencies:
  # State Management
  flutter_riverpod: ^3.0.3
  provider: ^6.1.2
  
  # API & Networking
  http: ^1.5.0
  
  # Security & Storage
  flutter_secure_storage: ^9.2.4
  local_auth: ^3.0.0
  local_auth_android: ^2.0.0
  
  # Configuration
  flutter_dotenv: ^5.2.1
  
  # UI/UX & Icons
  cupertino_icons: ^1.0.8
  flutter_animate: ^4.5.2
  lucide_flutter: ^0.546.0
  lucide_icons: ^0.257.0
  flutter_spinkit: ^5.2.2
  elegant_notification: ^2.5.1
  
  # Charts & Calendar
  fl_chart: ^0.69.0
  flutter_heatmap_calendar: ^1.0.5
  easy_date_timeline: ^2.0.9
  
  # Date & Localization
  intl: ^0.20.2
  shared_preferences: ^2.3.2
  
  # File Operations
  file_picker: ^8.1.4
  share_plus: ^10.1.2
  path_provider: ^2.1.5
```

### Cài đặt packages

```bash
cd frontend

# Get tất cả Flutter dependencies
flutter pub get

# Hoặc cài từng package nếu cần
flutter pub add flutter_riverpod
flutter pub add http
flutter pub add flutter_secure_storage
flutter pub add local_auth
flutter pub add fl_chart
```

---

## 💻 Yêu cầu hệ thống

### Backend
- .NET SDK 9.0+ hoặc cao hơn
- SQL Server 2019+ hoặc SQL Server Express
- Visual Studio 2022 hoặc VS Code (khuyến nghị)

### Frontend
- Flutter SDK 3.9.2+
- Dart SDK 3.9.2+
- Android Studio / Xcode (để chạy trên mobile)
- Chrome (để chạy trên web)

---

## 🚀 Cài đặt

### 1. Clone repository

```bash
git clone 
cd truong_hoang_phuc_habit
```

### 2. Cài đặt Backend

```bash
cd backend

# Restore packages
dotnet restore

# Tạo file .env từ .env.example
copy .env.example .env
# Hoặc trên Linux/Mac: cp .env.example .env
```

### 3. Cài đặt Frontend

```bash
cd frontend

# Get Flutter dependencies
flutter pub get

# Tạo file .env từ .env.example (nếu có)
# copy .env.example .env
```

---

## ⚙️ Cấu hình

### Backend Configuration

**⚠️ LƯU Ý**: 
- File `.env` **KHÔNG BAO GIỜ** được commit lên Git (đã có trong `.gitignore`)
- Thay `your_sendgrid_api_key_here` bằng SendGrid API key thật của bạn
- Tạo JWT secret key dài ít nhất 32 ký tự

### Frontend Configuration

Tạo file `frontend/.env` (nếu cần):

```env
# API Base URL
API_BASE_URL=http://localhost:5224
# Hoặc nếu dùng ngrok:
# API_BASE_URL=https://xxx.ngrok-free.app
```

### Database Setup

```bash
cd backend

# Tạo migration (nếu chưa có)
dotnet ef migrations add InitialCreate

# Apply migration (tạo database)
dotnet ef database update
```

---

## 🏃 Chạy ứng dụng

### Chạy Backend

```bash
cd backend
dotnet run

# Backend sẽ chạy tại:
# - HTTP: http://localhost:5224
# - Swagger UI: http://localhost:5224/swagger
```

### Chạy Frontend

```bash
cd frontend

# Chạy trên Chrome (Web)
flutter run -d chrome

# Chạy trên Android Emulator
flutter run -d emulator-5554

# Chạy trên iOS Simulator
flutter run -d iPhone
```

---

## 📁 Cấu trúc project

```
truong_hoang_phuc_habit/
├── backend/                          # Backend .NET 9.0
│   ├── Controllers/                 # API Controllers (9 files)
│   │   ├── AdminController.cs       # Quản lý Admin (Users, Roles, 2FA)
│   │   ├── AuthController.cs        # Xác thực (Register, Login, 2FA, Forgot Password)
│   │   ├── CategoryController.cs    # Quản lý Categories
│   │   ├── HabitController.cs       # Quản lý Habits (CRUD, Complete)
│   │   ├── HabitNoteController.cs   # Quản lý Habit Notes/Journal
│   │   ├── HabitScheduleController.cs # Quản lý lịch trình
│   │   ├── StatisticsController.cs  # Thống kê & phân tích
│   │   ├── UserController.cs        # Quản lý Profile
│   │   └── TestController.cs        # API Testing
│   ├── Data/                        # DbContext & Seed Data
│   │   ├── ApplicationDbContext.cs
│   │   └── SeedData.cs
│   ├── Models/                      # Data models (5 files)
│   │   ├── User.cs
│   │   ├── Category.cs
│   │   ├── Habit.cs
│   │   ├── HabitNote.cs
│   │   ├── HabitSchedule.cs
│   │   └── Dtos/                    # DTOs (17 files)
│   ├── Services/                    # Business logic (3 files)
│   │   ├── AuthService.cs           # Authentication logic
│   │   ├── EmailService.cs          # SendGrid integration
│   │   └── HabitScheduleService.cs  # Schedule calculations
│   ├── Migrations/                  # EF Core Migrations
│   ├── Program.cs                   # Entry point & configuration
│   ├── .env.example                 # Environment variables template
│   └── backend.csproj               # Project file
│
├── frontend/                         # Frontend Flutter 3.9.2+
│   ├── lib/
│   │   ├── api/                     # API services (8 files)
│   │   │   ├── admin_api_service.dart
│   │   │   ├── auth_api_service.dart
│   │   │   ├── habit_api_service.dart
│   │   │   ├── habit_completion_api_service.dart
│   │   │   ├── habit_note_api_service.dart
│   │   │   ├── habit_schedule_api_service.dart
│   │   │   ├── statistics_api_service.dart
│   │   │   └── user_api_service.dart
│   │   ├── models/                  # Data models (8 files)
│   │   │   ├── user_model.dart
│   │   │   ├── auth_response_model.dart
│   │   │   ├── category_model.dart
│   │   │   ├── habit_model.dart
│   │   │   ├── habit_note_model.dart
│   │   │   ├── habit_schedule_model.dart
│   │   │   ├── two_factor_login_response_model.dart
│   │   │   └── user_list_model.dart
│   │   ├── screens/                 # UI screens (18 files)
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart              # Quick Login + Biometric
│   │   │   ├── register_screen.dart
│   │   │   ├── waiting_verification_screen.dart
│   │   │   ├── reset_password_screen.dart
│   │   │   ├── home_screen.dart               # Bottom Navigation
│   │   │   ├── habits_screen.dart
│   │   │   ├── create_habit_screen.dart
│   │   │   ├── edit_habit_screen.dart
│   │   │   ├── habit_journal_screen.dart      # Notes/Journal
│   │   │   ├── habit_schedule_screen.dart
│   │   │   ├── create_category_screen.dart
│   │   │   ├── select_category_screen.dart
│   │   │   ├── statistics_screen.dart         # Charts & Analytics
│   │   │   ├── settings_screen.dart           # Settings & Preferences
│   │   │   ├── admin_dashboard_screen.dart    # Admin Panel
│   │   │   ├── setup_2fa_screen.dart          # TOTP Setup
│   │   │   └── verify_2fa_screen.dart
│   │   ├── services/                # State management (5 files)
│   │   │   ├── auth_provider.dart
│   │   │   ├── auth_state.dart
│   │   │   ├── biometric_service.dart
│   │   │   ├── category_providers.dart
│   │   │   └── storage_service.dart
│   │   ├── themes/                  # App themes (2 files)
│   │   │   ├── app_theme.dart
│   │   │   └── theme_provider.dart
│   │   ├── utils/                   # Utilities (3 files)
│   │   │   ├── app_notification.dart
│   │   │   ├── icon_utils.dart
│   │   │   └── jwt_decoder.dart
│   │   ├── widgets/                 # Reusable widgets (1 file)
│   │   │   └── habit_calendar_popup.dart
│   │   └── main.dart                # Entry point
│   ├── android/                     # Android platform code
│   ├── pubspec.yaml                 # Dependencies
│   └── .env                         # Environment variables
│
├── docs/                            # Tài liệu chi tiết
│   └── users/
│       ├── ADMIN_2FA_AUTHORIZATION.md    # Hướng dẫn 2FA cho Admin
│       ├── BIOMETRIC_ANDROID.md          # Hướng dẫn Biometric Android
│       ├── BIOMETRIC_USAGE.md            # Cách sử dụng Biometric
│       ├── BUILD_AUTH.md                 # Chi tiết xây dựng Authentication
│       ├── DB_AUTH.md                    # Database schema cho Auth
│       └── habits/                       # Tài liệu Habits
│
├── .gitignore                       # Git ignore rules
├── HabitManagement.sln              # Visual Studio solution
└── README.md                        # This file
```

---

## 📚 API Documentation

Sau khi chạy backend, truy cập Swagger UI tại:
```
http://localhost:5224/swagger
```

### Các endpoint chính:

#### 🔐 Authentication (`/api/auth`)
- `POST /api/auth/register` - Đăng ký tài khoản
- `POST /api/auth/login` - Đăng nhập (trả về JWT tokens)
- `POST /api/auth/verify-two-factor` - Xác thực 2FA code
- `POST /api/auth/forgot-password` - Gửi email reset password
- `GET /api/auth/verify-reset-token` - Xác nhận token reset password
- `GET /api/auth/check-token-status` - Kiểm tra trạng thái token
- `POST /api/auth/reset-password` - Đặt lại mật khẩu
- `POST /api/auth/refresh-token` - Refresh access token

#### 👤 User (`/api/user`)
- `GET /api/user/profile` - Lấy thông tin profile
- `PUT /api/user/profile` - Cập nhật profile

#### 👨‍💼 Admin (`/api/admin`)
- `POST /api/admin/create-admin` - Tạo tài khoản Admin (yêu cầu 2FA)
- `GET /api/admin/users` - Lấy danh sách Users
- `PUT /api/admin/users/{userId}/role` - Cập nhật vai trò User
- `GET /api/admin/setup-2fa` - Setup 2FA (QR code)
- `POST /api/admin/enable-2fa` - Kích hoạt 2FA

#### 📂 Category (`/api/category`)
- `GET /api/category` - Lấy danh sách categories
- `GET /api/category/{id}` - Lấy category theo ID
- `POST /api/category` - Tạo category mới
- `PUT /api/category/{id}` - Cập nhật category
- `DELETE /api/category/{id}` - Xóa category

#### 🎯 Habit (`/api/habit`)
- `GET /api/habit` - Lấy danh sách habits
- `GET /api/habit/{id}` - Lấy habit theo ID
- `POST /api/habit` - Tạo habit mới
- `PUT /api/habit/{id}` - Cập nhật habit
- `DELETE /api/habit/{id}` - Xóa habit
- `POST /api/habit/{id}/complete` - Đánh dấu hoàn thành
- `GET /api/habit/{id}/completions` - Lấy lịch sử hoàn thành

#### 📝 Habit Note (`/api/habitnote`)
- `GET /api/habitnote/habit/{habitId}` - Lấy notes của habit
- `GET /api/habitnote/{id}` - Lấy note theo ID
- `POST /api/habitnote` - Tạo note mới
- `PUT /api/habitnote/{id}` - Cập nhật note
- `DELETE /api/habitnote/{id}` - Xóa note

#### 📅 Habit Schedule (`/api/habitschedule`)
- `GET /api/habitschedule/habit/{habitId}` - Lấy lịch trình habit
- `GET /api/habitschedule/user` - Lấy lịch trình của user

#### 📊 Statistics (`/api/statistics`)
- `GET /api/statistics/overview` - Tổng quan thống kê
- `GET /api/statistics/habit/{habitId}` - Thống kê habit cụ thể
- `GET /api/statistics/category` - Thống kê theo category
- `GET /api/statistics/completion-rate` - Tỷ lệ hoàn thành

#### 🧪 Test (`/api/test`)
- `GET /api/test/health` - Health check

---

## 🔐 Bảo mật

### Các file nhạy cảm (KHÔNG commit lên Git)
- `backend/.env` - Chứa API keys, database credentials, JWT secrets
- `frontend/.env` - Chứa API base URL
- `backend/appsettings.Development.json` - Có thể chứa connection strings
- Các file `secrets.json`

### Best Practices
- ✅ Sử dụng HTTPS trong production
- ✅ Không hardcode API keys trong code
- ✅ Sử dụng environment variables cho mọi config nhạy cảm
- ✅ JWT tokens được lưu trong secure storage (không localStorage)
- ✅ Passwords được hash với ASP.NET Core Identity

---

## 📖 Tài liệu chi tiết

### Backend Documentation
- **[BUILD_AUTH.md](docs/users/BUILD_AUTH.md)** - Chi tiết xây dựng hệ thống Authentication
- **[DB_AUTH.md](docs/users/DB_AUTH.md)** - Cấu trúc Database cho Authentication

### Frontend Documentation
- **[BIOMETRIC_ANDROID.md](docs/users/BIOMETRIC_ANDROID.md)** - Hướng dẫn Biometric trên Android
- **[BIOMETRIC_USAGE.md](docs/users/BIOMETRIC_USAGE.md)** - Cách sử dụng tính năng Biometric

### Admin Documentation
- **[ADMIN_2FA_AUTHORIZATION.md](docs/users/ADMIN_2FA_AUTHORIZATION.md)** - Hướng dẫn 2FA cho Admin

### Database Schema

#### Bảng chính
- **AspNetUsers** - Thông tin người dùng (extended từ Identity)
- **AspNetRoles** - Vai trò (User, Admin)
- **Categories** - Danh mục thói quen
- **Habits** - Thói quen
- **HabitCompletions** - Lịch sử hoàn thành
- **HabitNotes** - Ghi chú/Journal
- **HabitSchedules** - Lịch trình thói quen

#### Custom User Properties
- `FullName` (string) - Họ và tên
- `DateOfBirth` (DateTime?) - Ngày sinh
- `ThemePreference` (string?) - light/dark/system
- `LanguageCode` (string?) - vi/en
- `TwoFactorSecretKey` (string?) - TOTP secret key

---

## 🐛 Debug & Troubleshooting

### Backend không chạy được
- **Lỗi SQL Server**: Kiểm tra SQL Server đã chạy chưa
- **Connection string**: Kiểm tra `DB_SERVER`, `DB_NAME` trong `.env`
- **Database chưa tạo**: Chạy `dotnet ef database update`
- **Port conflict**: Thay đổi port trong `launchSettings.json`

### Frontend không connect được API
- **Backend chưa chạy**: Kiểm tra backend đã chạy tại `http://localhost:5224`
- **URL sai**: Kiểm tra `API_BASE_URL` trong `frontend/.env`
- **Ngrok expired**: Nếu dùng ngrok, tạo URL mới và cập nhật
- **CORS error**: Kiểm tra CORS đã enable trong `Program.cs`

### Email không gửi được
- **API key sai**: Kiểm tra `SENDGRID_API_KEY` trong `.env`
- **Email chưa verify**: Verify `SENDGRID_FROM_EMAIL` trên SendGrid dashboard
- **Rate limit**: Kiểm tra SendGrid quota

### Biometric không hoạt động
- **Android**: Cần Android 6.0+ (API 23+)
- **Permission**: Kiểm tra `USE_BIOMETRIC` trong `AndroidManifest.xml`
- **Device không hỗ trợ**: Kiểm tra device có cảm biến vân tay/khuôn mặt
- **Chưa đăng ký**: Đăng ký vân tay/khuôn mặt trong Settings device

### 2FA không hoạt động
- **QR code không hiện**: Kiểm tra `Otp.NET` và `QRCoder` đã cài
- **Code không đúng**: Đồng bộ thời gian trên device với server
- **Setup chưa hoàn thành**: Admin phải enable 2FA trước khi login

---

## 🙏 Acknowledgments

- **ASP.NET Core Team** - Backend framework
- **Flutter Team** - Mobile framework
- **SendGrid** - Email service
- **Otp.NET** - TOTP implementation
- **fl_chart** - Charts & analytics
- **Lucide Icons** - Icon library

---

**Happy Coding! 🚀**
