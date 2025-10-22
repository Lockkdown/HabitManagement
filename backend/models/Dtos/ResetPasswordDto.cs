using System.ComponentModel.DataAnnotations;

namespace backend.Models.Dtos;

/// <summary>
/// Data Transfer Object cho yêu cầu đặt lại mật khẩu.
/// </summary>
public class ResetPasswordDto
{
    /// <summary>
    /// Địa chỉ email của người dùng.
    /// Bắt buộc và phải có định dạng email hợp lệ.
    /// </summary>
    [Required(ErrorMessage = "Email là bắt buộc")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ")]
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// Token reset mật khẩu được gửi qua email.
    /// Bắt buộc phải có.
    /// </summary>
    [Required(ErrorMessage = "Token là bắt buộc")]
    public string Token { get; set; } = string.Empty;

    /// <summary>
    /// Mật khẩu mới của người dùng.
    /// Bắt buộc và phải có ít nhất 6 ký tự.
    /// </summary>
    [Required(ErrorMessage = "Mật khẩu mới là bắt buộc")]
    [MinLength(6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự")]
    public string NewPassword { get; set; } = string.Empty;

    /// <summary>
    /// Xác nhận mật khẩu mới phải khớp với mật khẩu mới.
    /// </summary>
    [Required(ErrorMessage = "Xác nhận mật khẩu là bắt buộc")]
    [Compare("NewPassword", ErrorMessage = "Mật khẩu mới và xác nhận mật khẩu không khớp")]
    public string ConfirmPassword { get; set; } = string.Empty;
}
