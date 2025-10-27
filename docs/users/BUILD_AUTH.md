# Hệ thống Xác thực & Phân quyền (Authentication & Authorization)

Tài liệu này mô tả các yêu cầu, luồng hoạt động và công nghệ sử dụng để xây dựng hệ thống bảo mật cho ứng dụng "Quản lý thói quen".

## 1. Công nghệ & Thư viện

### Backend (.NET 9.0)
- **Nền tảng**: `ASP.NET Core Identity` để quản lý người dùng, vai trò, mật khẩu và tokens.
- **Authentication**: `JWT Bearer Tokens` (Access Token + Refresh Token).
- **Email Service**: `SendGrid` để gửi email xác thực và reset mật khẩu.
- **2FA/TOTP**: Sử dụng tính năng có sẵn của `ASP.NET Core Identity` để làm việc với các app như Google Authenticator.
- **API Documentation**: `Swagger (OpenAPI)` để tạo UI tương tác, giúp kiểm tra và tài liệu hóa API.
- **Development Workflow**: `Ngrok` để tạo tunnel từ một URL công khai tới server local, cho phép thiết bị di động gọi API backend đang chạy trên máy tính.
- **Configuration Management**: Các thông tin nhạy cảm như Connection String, API Keys (SendGrid), JWT Secret Key phải được quản lý qua `secrets.json` trong môi trường Development và qua các biến môi trường (Environment Variables) trong môi trường Production.

**Packages .NET cần cài đặt**:
```bash
dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add package SendGrid
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
# ... và các package cần thiết khác cho migrations
```

### Frontend (Flutter)
- **State Management**: `flutter_riverpod` để quản lý trạng thái đăng nhập.
- **API Client**: `http`.
- **Secure Storage**: `flutter_secure_storage` để lưu trữ tokens an toàn.
- **Biometrics**: `local_auth` để tích hợp đăng nhập bằng vân tay/khuôn mặt.
- **UI**:
    - **Splash/Intro Screen**: Hiển thị màn hình chờ khi khởi động ứng dụng để kiểm tra trạng thái đăng nhập hoặc tải dữ liệu ban đầu.
    - **Theme**: Xây dựng một hệ thống theme thống nhất cho toàn bộ ứng dụng (màu sắc, font chữ, kích thước...). Theme mặc định là **Light (trắng)**. Cho phép người dùng chuyển đổi giữa Light/Dark mode.
    - **Ngôn ngữ**: Mặc định là **Tiếng Việt**. Hỗ trợ đa ngôn ngữ (Tiếng Anh/Việt).
- **Configuration Management**: Sử dụng file `.env` để lưu trữ các thông tin cấu hình như `API_BASE_URL`. Thêm package `flutter_dotenv` để đọc các biến này.
- **Code Quality & UI/UX Packages**:
        - `flutter_animate`: Thêm các hiệu ứng animation một cách đơn giản.
    - `lucide_flutter`: Bộ icon hiện đại và nhất quán.
    - `flutter_spinkit`: Cung cấp các hiệu ứng loading đẹp mắt.
    - `elegant_notification`: Hiển thị các thông báo (toast) tùy biến cao.

**Dependencies cần thêm vào `pubspec.yaml`**:
```yaml
dependencies:
  flutter_riverpod: ^3.0.3
  http: ^1.5.0
  flutter_secure_storage: ^9.2.4
  local_auth: ^3.0.0

  # UI/UX & Code Quality
  flutter_animate: ^4.5.2
  lucide_flutter: ^0.546.0
  flutter_spinkit: ^5.2.2
  elegant_notification: ^2.5.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

---

## 2. Chức năng & Luồng hoạt động

### Dành cho Người dùng (User)

#### a. Đăng ký (Sign Up)
1.  **Frontend**: User nhập các thông tin sau:
    -   `Username`
    -   `FullName` (Họ và tên)
    -   `Email`
    -   `Password`
    -   `Confirm Password`
    -   `PhoneNumber` (Số điện thoại)
    -   `DateOfBirth` (Ngày tháng năm sinh)
2.  **Backend** (`POST /api/auth/register`):
    -   Validate input.
    -   Tạo `ApplicationUser` (kế thừa từ `IdentityUser`) mới, lưu trữ các thông tin mở rộng (`FullName`, `DateOfBirth`, `PhoneNumber`, `ThemePreference`, `LanguageCode`) và gán role `User`.
    -   Lưu vào database.
    -   (Tùy chọn) Gửi email chào mừng.

#### b. Đăng nhập (Sign In)
1.  **Frontend**: User nhập email & password.
2.  **Backend** (`POST /api/auth/login`):
    -   Xác thực thông tin bằng `ASP.NET Core Identity`.
    -   Nếu thành công, tạo **Access Token** (JWT, ngắn hạn) và **Refresh Token** (dài hạn).
    -   Trả về cả 2 tokens.
3.  **Frontend**: Lưu 2 tokens vào `flutter_secure_storage`.

#### c. Quên mật khẩu (Forgot Password)
1.  **Frontend**: User nhập email và yêu cầu reset.
2.  **Backend** (`POST /api/auth/forgot-password`):
    -   Tạo một `reset token` (sử dụng `UserManager` của Identity).
    -   Gửi email cho user chứa link reset (e.g., `your-app://reset-password?token=...`).
3.  **Frontend**: User mở link từ email, app được mở lên, trích xuất token.
4.  **Frontend**: User nhập mật khẩu mới.
5.  **Backend** (`POST /api/auth/reset-password`): Xác thực `reset token` và cập nhật mật khẩu mới.

#### d. Tùy chỉnh Giao diện và Ngôn ngữ
1.  **Backend**: Model `ApplicationUser` sẽ có thêm 2 trường:
    -   `ThemePreference` (string): Lưu lựa chọn giao diện (e.g., "light", "dark", "system").
    -   `LanguageCode` (string): Lưu lựa chọn ngôn ngữ (e.g., "vi", "en").
2.  **Frontend**: 
    -   Sau khi đăng nhập, đọc các giá trị này và áp dụng cho ứng dụng.
    -   Trong màn hình cài đặt, cho phép người dùng thay đổi và gọi API để cập nhật lên server.

#### e. Đăng nhập Sinh trắc học (Biometric Login)
1.  **Thiết lập**: Sau khi đăng nhập thành công, hỏi user có muốn bật sinh trắc học không.
2.  **Sử dụng**: Lần mở app tiếp theo, thay vì form đăng nhập, hiển thị prompt của `local_auth`.
3.  **Xác thực**: Nếu sinh trắc học thành công, dùng **Refresh Token** đã lưu để gọi `POST /api/auth/refresh` và lấy Access Token mới, hoàn tất đăng nhập.

---

## 3. Chức năng cho Quản trị viên (Admin)

### a. Tài khoản bảo mật cao
- Tài khoản `Admin` sẽ được tạo thủ công hoặc qua một quy trình đặc biệt, không qua API đăng ký công khai.
- Các API quan trọng (e.g., quản lý user, xem logs) sẽ yêu cầu role `Admin`.

### b. Bắt buộc 2FA (Two-Factor Authentication)
1.  **Luồng đăng nhập cho Admin**:
    -   Nhập email & password.
    -   Nếu thành công, backend kiểm tra nếu user có role `Admin` và đã bật 2FA.
    -   Backend trả về một response yêu cầu mã 2FA, thay vì trả về tokens.
    -   **Frontend** hiển thị màn hình nhập mã TOTP (từ app Google Authenticator).
    -   **Backend** (`POST /api/auth/verify-2fa`): Xác thực mã TOTP.
    -   Nếu mã đúng, trả về Access/Refresh tokens.

2.  **Thiết lập 2FA (lần đầu)**:
    -   Admin truy cập một trang quản lý tài khoản.
    -   **Backend** (`POST /api/auth/enable-2fa`): Tạo một `secret key` và trả về dưới dạng QR code.
    -   **Frontend**: Hiển thị QR code để Admin quét bằng app Authenticator.
    -   Admin nhập mã từ app để xác nhận, hoàn tất quá trình bật 2FA.
