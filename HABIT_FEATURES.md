# 🎯 Tính năng Quản lý Thói quen

## ✅ Đã hoàn thành

### Backend (ASP.NET Core 9.0)
- ✅ **Models**: Category, Habit, HabitCompletion
- ✅ **API Endpoints**:
  - `GET /api/category` - Lấy danh sách danh mục
  - `GET /api/category/default` - Lấy danh mục mặc định
  - `POST /api/category` - Tạo danh mục mới
  - `PUT /api/category/{id}` - Cập nhật danh mục
  - `DELETE /api/category/{id}` - Xóa danh mục
  - `GET /api/habit` - Lấy danh sách thói quen
  - `POST /api/habit` - Tạo thói quen mới
  - `PUT /api/habit/{id}` - Cập nhật thói quen
  - `DELETE /api/habit/{id}` - Xóa thói quen
  - `POST /api/habit/{id}/complete` - Đánh dấu hoàn thành
  - `GET /api/habit/{id}/completions` - Lấy lịch sử hoàn thành

### Frontend (Flutter)
- ✅ **Giao diện chính**:
  - Bottom Navigation với 4 tab: Hôm nay, Thói quen, Nhiệm vụ, Thống kê
  - Floating Action Button để tạo thói quen mới
  - Danh sách thói quen với card hiển thị thông tin
  - Dark theme với màu sắc phù hợp

- ✅ **Tạo thói quen**:
  - Form thông tin chung: tên, danh mục, ngày bắt đầu/kết thúc
  - Chọn tần suất: hàng ngày, hàng tuần, hàng tháng
  - Cấu hình nhắc nhở: thời gian, loại (thông báo/âm thanh)
  - Mô tả thói quen (tùy chọn)

- ✅ **Quản lý danh mục**:
  - Chọn từ danh mục mặc định hoặc danh mục cá nhân
  - Tạo danh mục mới với chọn màu sắc và icon
  - Giao diện chọn màu và icon trực quan

- ✅ **Theme & UI**:
  - Dark mode mặc định
  - Màu sắc phù hợp với thiết kế trong hình
  - Responsive design
  - Material Design 3

## 🚀 Cách sử dụng

### 1. Chạy Backend
```bash
cd HabitManagement/backend
dotnet run
```
Backend sẽ chạy tại: http://localhost:5224

### 2. Chạy Frontend
```bash
cd HabitManagement/frontend
flutter run
```

### 3. Sử dụng ứng dụng
1. **Đăng nhập** với tài khoản đã tạo
2. **Tạo thói quen**:
   - Nhấn nút + ở giữa màn hình
   - Điền thông tin thói quen
   - Chọn danh mục (có thể tạo mới)
   - Cấu hình tần suất và nhắc nhở
3. **Quản lý thói quen**:
   - Xem danh sách thói quen
   - Đánh dấu hoàn thành
   - Theo dõi tiến độ

## 📱 Tính năng chính

### Tạo thói quen
- **Thông tin cơ bản**: Tên, mô tả, danh mục
- **Thời gian**: Ngày bắt đầu, ngày kết thúc (tùy chọn)
- **Tần suất**: Hàng ngày, hàng tuần, hàng tháng
- **Nhắc nhở**: Thời gian, loại nhắc nhở
- **Danh mục**: Chọn từ danh mục có sẵn hoặc tạo mới

### Quản lý danh mục
- **Danh mục mặc định**: Sức khỏe, Học tập, Công việc, Thể thao, Giải trí, Gia đình, Khác
- **Danh mục cá nhân**: Tạo với màu sắc và icon tùy chỉnh
- **Giao diện chọn**: Grid màu sắc và icon trực quan

### Giao diện
- **Dark theme** với màu chủ đạo hồng/đỏ
- **Bottom navigation** với 4 tab chính
- **Card design** cho danh sách thói quen
- **Floating action button** để tạo thói quen mới

## 🔧 Công nghệ sử dụng

### Backend
- ASP.NET Core 9.0
- Entity Framework Core
- SQL Server
- JWT Authentication
- Swagger API Documentation

### Frontend
- Flutter 3.x
- Riverpod (State Management)
- Lucide Icons
- Material Design 3
- HTTP Client

## 📊 Database Schema

### Categories
- Id, Name, Color, Icon, UserId
- CreatedAt, UpdatedAt

### Habits
- Id, Name, Description, CategoryId, UserId
- StartDate, EndDate, Frequency
- HasReminder, ReminderTime, ReminderType
- IsActive, CreatedAt, UpdatedAt

### HabitCompletions
- Id, HabitId, CompletedAt, Notes

## 🎨 UI/UX Features

- **Dark Mode**: Giao diện tối với màu sắc phù hợp
- **Color Picker**: Chọn màu cho danh mục với grid trực quan
- **Icon Selector**: Chọn icon từ bộ icon có sẵn
- **Form Validation**: Kiểm tra dữ liệu đầu vào
- **Loading States**: Hiển thị trạng thái loading
- **Error Handling**: Xử lý lỗi và hiển thị thông báo

## 🔐 Bảo mật

- JWT Authentication
- User-specific data isolation
- Input validation
- SQL injection protection
- CORS configuration

## 📈 Tính năng tương lai

- [ ] Thống kê chi tiết
- [ ] Biểu đồ tiến độ
- [ ] Nhắc nhở push notification
- [ ] Export dữ liệu
- [ ] Chia sẻ thói quen
- [ ] Mục tiêu hàng tuần/tháng
