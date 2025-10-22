using System.ComponentModel.DataAnnotations;

namespace backend.Models.Dtos;

/// <summary>
/// Data Transfer Object cho yêu cầu quên mật khẩu.
/// </summary>
public class ForgotPasswordDto
{
    /// <summary>
    /// Địa chỉ email của người dùng cần reset mật khẩu.
    /// Bắt buộc và phải có định dạng email hợp lệ.
    /// </summary>
    [Required(ErrorMessage = "Email là bắt buộc")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ")]
    public string Email { get; set; } = string.Empty;
}
