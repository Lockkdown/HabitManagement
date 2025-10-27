# Cấu trúc Database cho Hệ thống Xác thực

## 1. Thông tin Kết nối (SQL Server)

- **Server**: `DESKTOP-DBOGR0L`
- **Database Name**: `HabitManagement`
- **Connection String (ví dụ cho `appsettings.json`)**:
  ```json
  "ConnectionStrings": {
    "DefaultConnection": "Server=DESKTOP-DBOGR0L;Database=HabitManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True"
  }
  ```

**Lưu ý**: `Trusted_Connection=True` sử dụng Windows Authentication. Nếu SQL Server của bạn dùng user/password, connection string sẽ khác.

---

## 2. Cấu trúc Bảng của ASP.NET Core Identity

Khi bạn tích hợp `ASP.NET Core Identity` với `EntityFrameworkCore`, nó sẽ tự động tạo ra các bảng sau trong database `HabitManagement` để quản lý người dùng và vai trò.

### Bảng chính:

-   **`AspNetUsers`**
    -   **Mục đích**: Lưu trữ thông tin người dùng. Bảng này sẽ được mở rộng từ `IdentityUser` mặc định để chứa các thông tin tùy chỉnh.
    -   **Các cột mặc định quan trọng**: 
        -   `Id`: Khóa chính (string, guid).
        -   `UserName`: Tên đăng nhập.
        -   `NormalizedUserName`: Tên đăng nhập đã chuẩn hóa (viết hoa) để tìm kiếm không phân biệt chữ hoa/thường.
        -   `Email`: Địa chỉ email.
        -   `NormalizedEmail`: Email đã chuẩn hóa.
        -   `EmailConfirmed`: `true` nếu email đã được xác thực.
        -   `PasswordHash`: Hash của mật khẩu (không bao giờ lưu mật khẩu gốc).
        -   `SecurityStamp`: Một giá trị ngẫu nhiên, thay đổi khi thông tin bảo mật của user thay đổi (e.g., đổi mật khẩu).
        -   `PhoneNumber`: Số điện thoại.
        -   `TwoFactorEnabled`: `true` nếu người dùng đã bật xác thực 2 yếu tố.

    -   **Các cột mở rộng (custom)**:
        -   `FullName` (string): Họ và tên đầy đủ của người dùng.
        -   `DateOfBirth` (DateTime): Ngày tháng năm sinh.
        -   `ThemePreference` (string): Lưu lựa chọn giao diện (e.g., "light", "dark", "system").
        -   `LanguageCode` (string): Lưu lựa chọn ngôn ngữ (e.g., "vi", "en").

-   **`AspNetRoles`**
    -   **Mục đích**: Lưu trữ các vai trò (roles) trong hệ thống (e.g., "Admin", "User").
    -   **Các cột quan trọng**:
        -   `Id`: Khóa chính.
        -   `Name`: Tên vai trò (e.g., "Admin").
        -   `NormalizedName`: Tên vai trò đã chuẩn hóa.

-   **`AspNetUserRoles`**
    -   **Mục đích**: Bảng trung gian, liên kết người dùng với vai trò (quan hệ nhiều-nhiều).
    -   **Các cột quan trọng**:
        -   `UserId`: Khóa ngoại, trỏ tới `AspNetUsers.Id`.
        -   `RoleId`: Khóa ngoại, trỏ tới `AspNetRoles.Id`.

### Các bảng phụ khác:

-   **`AspNetUserClaims`**: Lưu các "claim" (thông tin bổ sung) về user.
-   **`AspNetUserLogins`**: Lưu thông tin đăng nhập từ các nhà cung cấp bên ngoài (e.g., Google, Facebook).
-   **`AspNetUserTokens`**: Lưu các loại token của user (e.g., refresh token, password reset token).
