# 🎯 Habit Management - Ứng dụng Quản lý Thói quen

# Đây là đồ án môn học của môn "Lập trình trên thiết bị di động" 
# Các thành viên: 
- Trương Hoàng Phúc
- Nguyễn Trịnh Lân
- Hoàng Viết Nguyên
- Ngô Xuân Hạo

## 📋 Mục lục

- [Tính năng](#-tính-năng)
- [Công nghệ sử dụng](#-công-nghệ-sử-dụng)
- [Yêu cầu hệ thống](#-yêu-cầu-hệ-thống)
- [Cài đặt](#-cài-đặt)
- [Cấu hình](#️-cấu-hình)
- [Chạy ứng dụng](#-chạy-ứng-dụng)
- [Cấu trúc project](#-cấu-trúc-project)
- [API Documentation](#-api-documentation)

---

## ✨ Tính năng

### Xác thực & Bảo mật
- ✅ Đăng ký tài khoản với xác thực email
- ✅ Đăng nhập với JWT (Access Token + Refresh Token)
- ✅ Quên mật khẩu với email verification
- ✅ Đăng nhập sinh trắc học (vân tay/khuôn mặt)
- ✅ Two-Factor Authentication (2FA) cho Admin
- ✅ Phân quyền User/Admin

### Giao diện
- ✅ Theme sáng/tối
- ✅ Đa ngôn ngữ (Tiếng Việt/Tiếng Anh)
- ✅ Responsive design
- ✅ Material Design 3

---

## 🛠 Công nghệ sử dụng

### Backend
- **Framework**: ASP.NET Core 9.0
- **Database**: SQL Server
- **Authentication**: ASP.NET Core Identity + JWT Bearer
- **Email**: SendGrid
- **ORM**: Entity Framework Core

### Frontend
- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **HTTP Client**: http package
- **Secure Storage**: flutter_secure_storage
- **Biometrics**: local_auth

---

## 📦 Backend Dependencies

### NuGet Packages chính

```xml
<!-- ASP.NET Core & Identity -->
<PackageReference Include="Microsoft.AspNetCore.Identity.EntityFrameworkCore" Version="9.0.0" />
<PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="9.0.0" />

<!-- Entity Framework Core -->
<PackageReference Include="Microsoft.EntityFrameworkCore" Version="9.0.0" />
<PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="9.0.0" />
<PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="9.0.0" />

<!-- SendGrid for Email -->
<PackageReference Include="SendGrid" Version="9.28.1" />

<!-- Logging -->
<PackageReference Include="Serilog" Version="3.1.1" />
<PackageReference Include="Serilog.AspNetCore" Version="8.0.1" />

<!-- Configuration -->
<PackageReference Include="Microsoft.Extensions.Configuration.EnvironmentVariables" Version="9.0.0" />
<PackageReference Include="DotNetEnv" Version="2.5.0" />

<!-- Swagger/OpenAPI -->
<PackageReference Include="Swashbuckle.AspNetCore" Version="6.4.0" />
```

### Cài đặt packages

```bash
cd backend

# Restore tất cả packages từ .csproj
dotnet restore

# Hoặc cài từng package nếu cần
dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package SendGrid
dotnet add package DotNetEnv
```

### Kiểm tra packages đã cài

```bash
# Liệt kê tất cả packages
dotnet list package

# Kiểm tra package cụ thể
dotnet list package --include-transitive
```

---

## 💻 Yêu cầu hệ thống

### Backend
- .NET SDK 9.0 hoặc cao hơn
- SQL Server 2019+ hoặc SQL Server Express
- Visual Studio 2022 hoặc VS Code (khuyến nghị)

### Frontend
- Flutter SDK 3.19.0+
- Dart SDK 3.3.0+
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
├── backend/                    # Backend .NET
│   ├── Controllers/           # API Controllers
│   ├── Data/                  # DbContext
│   ├── Models/                # Data models & DTOs
│   ├── Services/              # Business logic
│   ├── Program.cs             # Entry point
│   ├── .env.example           # Environment variables template
│   └── backend.csproj         # Project file
│
├── frontend/                   # Frontend Flutter
│   ├── lib/
│   │   ├── api/              # API services
│   │   ├── models/           # Data models
│   │   ├── screens/          # UI screens
│   │   ├── services/         # State management & services
│   │   ├── themes/           # App themes
│   │   ├── widgets/          # Reusable widgets
│   │   └── main.dart         # Entry point
│   ├── pubspec.yaml          # Dependencies
│   └── .env                  # Environment variables
│
├── .gitignore                 # Git ignore rules
└── README.md                  # This file
```

---

## 📚 API Documentation

Sau khi chạy backend, truy cập Swagger UI tại:
```
http://localhost:5224/swagger
```

### Các endpoint chính:

#### Authentication
- `POST /api/auth/register` - Đăng ký tài khoản
- `POST /api/auth/login` - Đăng nhập
- `POST /api/auth/forgot-password` - Quên mật khẩu
- `GET /api/auth/verify-reset-token` - Xác nhận token reset password
- `GET /api/auth/check-token-status` - Kiểm tra trạng thái token
- `POST /api/auth/reset-password` - Đặt lại mật khẩu

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

## 🐛 Debug & Troubleshooting

### Backend không chạy được
- Kiểm tra SQL Server đã chạy chưa
- Kiểm tra connection string trong `.env`
- Chạy `dotnet ef database update` để tạo database

### Frontend không connect được API
- Kiểm tra backend đã chạy chưa
- Kiểm tra `API_BASE_URL` trong `.env`
- Nếu dùng ngrok, kiểm tra URL còn valid không

### Email không gửi được
- Kiểm tra SendGrid API key trong `.env`
- Kiểm tra `SENDGRID_FROM_EMAIL` đã verify trên SendGrid chưa

---

## 👨‍💻 Tác giả

**Trương Hoàng Phúc**

---

## 📝 License

This project is licensed under the MIT License.

---

## 🙏 Cảm ơn

- ASP.NET Core Team
- Flutter Team
- SendGrid
- Tất cả contributors

---

**Happy Coding! 🚀**
