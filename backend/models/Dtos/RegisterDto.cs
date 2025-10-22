using System.ComponentModel.DataAnnotations;

namespace backend.Models.Dtos;

/// <summary>
/// Data Transfer Object cho yêu cầu đăng ký người dùng mới.
/// </summary>
public class RegisterDto
{
    /// <summary>
    /// Tên đăng nhập của người dùng.
    /// Bắt buộc phải có.
    /// </summary>
    [Required(ErrorMessage = "Username là bắt buộc")]
    public string Username { get; set; } = string.Empty;

    /// <summary>
    /// Họ và tên đầy đủ của người dùng.
    /// Bắt buộc phải có.
    /// </summary>
    [Required(ErrorMessage = "Họ tên là bắt buộc")]
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// Địa chỉ email của người dùng.
    /// Bắt buộc và phải có định dạng email hợp lệ.
    /// </summary>
    [Required(ErrorMessage = "Email là bắt buộc")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ")]
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// Mật khẩu của người dùng.
    /// Bắt buộc và phải có ít nhất 6 ký tự.
    /// </summary>
    [Required(ErrorMessage = "Mật khẩu là bắt buộc")]
    [MinLength(6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự")]
    public string Password { get; set; } = string.Empty;

    /// <summary>
    /// Xác nhận mật khẩu phải khớp với mật khẩu.
    /// </summary>
    [Required(ErrorMessage = "Xác nhận mật khẩu là bắt buộc")]
    [Compare("Password", ErrorMessage = "Mật khẩu và xác nhận mật khẩu không khớp")]
    public string ConfirmPassword { get; set; } = string.Empty;

    /// <summary>
    /// Số điện thoại của người dùng.
    /// Tùy chọn.
    /// </summary>
    public string? PhoneNumber { get; set; }

    /// <summary>
    /// Ngày tháng năm sinh của người dùng.
    /// Tùy chọn.
    /// </summary>
    public DateTime? DateOfBirth { get; set; }
}
