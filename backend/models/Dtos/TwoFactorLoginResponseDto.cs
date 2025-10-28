namespace backend.Models.Dtos;

/// <summary>
/// Response cho Login với 2FA
/// </summary>
public class TwoFactorLoginResponseDto
{
    /// <summary>
    /// Có yêu cầu setup 2FA không (lần đầu)
    /// </summary>
    public bool RequiresTwoFactorSetup { get; set; }

    /// <summary>
    /// Có yêu cầu verify 2FA không (lần sau)
    /// </summary>
    public bool RequiresTwoFactorVerification { get; set; }

    /// <summary>
    /// Temporary token (5 phút) để verify OTP
    /// </summary>
    public string? TempToken { get; set; }

    /// <summary>
    /// QR Code base64 (chỉ có khi RequiresTwoFactorSetup = true)
    /// </summary>
    public string? QrCode { get; set; }

    /// <summary>
    /// Secret Key (chỉ có khi RequiresTwoFactorSetup = true)
    /// </summary>
    public string? SecretKey { get; set; }

    /// <summary>
    /// Access Token (chỉ có khi không cần 2FA)
    /// </summary>
    public string? AccessToken { get; set; }

    /// <summary>
    /// Refresh Token (chỉ có khi không cần 2FA)
    /// </summary>
    public string? RefreshToken { get; set; }

    /// <summary>
    /// Thời gian hết hạn của Access Token
    /// </summary>
    public DateTime? ExpiresAt { get; set; }

    /// <summary>
    /// Thông tin user (chỉ có khi không cần 2FA)
    /// </summary>
    public AuthResponseDto? User { get; set; }
}
