namespace backend.Models.Dtos;

/// <summary>
/// DTO để cập nhật thông tin profile người dùng.
/// </summary>
public class UpdateUserProfileDto
{
    /// <summary>
    /// Tên người dùng mới.
    /// </summary>
    public string? Username { get; set; }

    /// <summary>
    /// Họ và tên đầy đủ mới.
    /// </summary>
    public string? FullName { get; set; }

    /// <summary>
    /// Email mới.
    /// </summary>
    public string? Email { get; set; }

    /// <summary>
    /// Số điện thoại mới.
    /// </summary>
    public string? PhoneNumber { get; set; }

    /// <summary>
    /// Lựa chọn giao diện mới.
    /// Các giá trị hợp lệ: "light", "dark", "system".
    /// </summary>
    public string? ThemePreference { get; set; }

    /// <summary>
    /// Mã ngôn ngữ mới.
    /// Các giá trị hợp lệ: "vi", "en".
    /// </summary>
    public string? LanguageCode { get; set; }

    /// <summary>
    /// Cài đặt bật/tắt thông báo.
    /// </summary>
    public bool? NotificationEnabled { get; set; }

    /// <summary>
    /// Cài đặt bật/tắt nhắc nhở hàng ngày.
    /// </summary>
    public bool? ReminderEnabled { get; set; }

    /// <summary>
    /// Thời gian nhắc nhở hàng ngày.
    /// Định dạng: HH:mm (ví dụ: "08:00").
    /// </summary>
    public string? ReminderTime { get; set; }
}