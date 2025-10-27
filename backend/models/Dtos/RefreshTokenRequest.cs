namespace backend.Models.Dtos;

/// <summary>
/// DTO cho request refresh access token.
/// Được gọi khi sinh trắc học thành công.
/// </summary>
public class RefreshTokenRequest
{
    /// <summary>
    /// Refresh token được lưu sau khi đăng nhập
    /// </summary>
    public string RefreshToken { get; set; } = string.Empty;
}
