using System.ComponentModel.DataAnnotations;

namespace backend.Models.Dtos;

/// <summary>
/// Data Transfer Object cho yêu cầu đăng nhập.
/// </summary>
public class LoginDto
{
    /// <summary>
    /// Địa chỉ email của người dùng.
    /// Bắt buộc và phải có định dạng email hợp lệ.
    /// </summary>
    [Required(ErrorMessage = "Email là bắt buộc")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ")]
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// Mật khẩu của người dùng.
    /// Bắt buộc phải có.
    /// </summary>
    [Required(ErrorMessage = "Mật khẩu là bắt buộc")]
    public string Password { get; set; } = string.Empty;
}
