namespace backend.Models.Dtos;

/// <summary>
/// DTO để check trạng thái token reset password
/// </summary>
public class VerifyResetTokenDto
{
    /// <summary>
    /// Email của người dùng
    /// </summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// Token ID để tracking (không phải token gốc)
    /// </summary>
    public string TokenId { get; set; } = string.Empty;
}

/// <summary>
/// Response khi check token status
/// </summary>
public class TokenStatusResponse
{
    /// <summary>
    /// Token đã được verify chưa
    /// </summary>
    public bool IsVerified { get; set; }

    /// <summary>
    /// Token thật để dùng khi reset (chỉ trả về khi verified)
    /// </summary>
    public string? Token { get; set; }

    /// <summary>
    /// Thông báo
    /// </summary>
    public string Message { get; set; } = string.Empty;
}
