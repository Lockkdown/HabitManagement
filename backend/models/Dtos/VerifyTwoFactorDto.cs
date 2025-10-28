using System.ComponentModel.DataAnnotations;

namespace backend.Models.Dtos;

/// <summary>
/// DTO cho việc verify OTP (2FA)
/// </summary>
public class VerifyTwoFactorDto
{
    /// <summary>
    /// Temporary token từ login response
    /// </summary>
    [Required(ErrorMessage = "Temporary token là bắt buộc")]
    public string TempToken { get; set; } = string.Empty;

    /// <summary>
    /// OTP 6 số từ Google Authenticator
    /// </summary>
    [Required(ErrorMessage = "OTP là bắt buộc")]
    [StringLength(6, MinimumLength = 6, ErrorMessage = "OTP phải có 6 ký tự")]
    [RegularExpression(@"^\d{6}$", ErrorMessage = "OTP phải là 6 chữ số")]
    public string Otp { get; set; } = string.Empty;
}
