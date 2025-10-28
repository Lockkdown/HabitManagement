using Microsoft.AspNetCore.Identity;

namespace backend.Models;

/// <summary>
/// Đại diện cho một người dùng trong hệ thống.
/// Kế thừa từ IdentityUser để tận dụng các tính năng xác thực của ASP.NET Core Identity.
/// </summary>
public class User : IdentityUser
{
    /// <summary>
    /// Họ và tên đầy đủ của người dùng.
    /// </summary>
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// Ngày tháng năm sinh của người dùng.
    /// Có thể null nếu người dùng không cung cấp.
    /// </summary>
    public DateTime? DateOfBirth { get; set; }

    /// <summary>
    /// Lựa chọn giao diện của người dùng.
    /// Các giá trị hợp lệ: "light", "dark", "system".
    /// Mặc định là "light".
    /// </summary>
    public string ThemePreference { get; set; } = "light";

    /// <summary>
    /// Mã ngôn ngữ ưa thích của người dùng.
    /// Các giá trị hợp lệ: "vi" (Tiếng Việt), "en" (Tiếng Anh).
    /// Mặc định là "vi".
    /// </summary>
    public string LanguageCode { get; set; } = "vi";

    /// <summary>
    /// Cài đặt bật/tắt thông báo của người dùng.
    /// Mặc định là true (bật).
    /// </summary>
    public bool NotificationEnabled { get; set; } = true;

    /// <summary>
    /// Cài đặt bật/tắt nhắc nhở hàng ngày của người dùng.
    /// Mặc định là true (bật).
    /// </summary>
    public bool ReminderEnabled { get; set; } = true;

    /// <summary>
    /// Thời gian nhắc nhở hàng ngày của người dùng.
    /// Định dạng: HH:mm (ví dụ: "08:00").
    /// Mặc định là "08:00".
    /// </summary>
    public string ReminderTime { get; set; } = "08:00";
}
