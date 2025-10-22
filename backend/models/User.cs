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
}
