namespace backend.Models.Dtos;

/// <summary>
/// Data Transfer Object cho phản hồi xác thực thành công.
/// Chứa thông tin người dùng và các tokens.
/// </summary>
public class AuthResponseDto
{
    /// <summary>
    /// ID người dùng.
    /// </summary>
    public string UserId { get; set; } = string.Empty;

    /// <summary>
    /// Tên đăng nhập của người dùng.
    /// </summary>
    public string Username { get; set; } = string.Empty;

    /// <summary>
    /// Email của người dùng.
    /// </summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// Họ và tên đầy đủ của người dùng.
    /// </summary>
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// Lựa chọn giao diện của người dùng.
    /// </summary>
    public string ThemePreference { get; set; } = string.Empty;

    /// <summary>
    /// Mã ngôn ngữ ưa thích của người dùng.
    /// </summary>
    public string LanguageCode { get; set; } = string.Empty;

    /// <summary>
    /// Access Token (JWT) để xác thực các request.
    /// Token này có thời hạn ngắn.
    /// </summary>
    public string AccessToken { get; set; } = string.Empty;

    /// <summary>
    /// Refresh Token để lấy Access Token mới khi hết hạn.
    /// Token này có thời hạn dài hơn.
    /// </summary>
    public string RefreshToken { get; set; } = string.Empty;

    /// <summary>
    /// Thời gian hết hạn của Access Token.
    /// </summary>
    public DateTime ExpiresAt { get; set; }
}
