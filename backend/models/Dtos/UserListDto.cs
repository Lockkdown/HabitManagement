namespace backend.Models.Dtos;

/// <summary>
/// DTO cho danh sách users (Admin view)
/// </summary>
public class UserListDto
{
    public string Id { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public bool EmailConfirmed { get; set; }
    public bool LockoutEnabled { get; set; }
    public DateTimeOffset? LockoutEnd { get; set; }
    public List<string> Roles { get; set; } = new();
    public bool TwoFactorEnabled { get; set; }
    public bool TwoFactorSetupCompleted { get; set; }
    public DateTime? CreatedAt { get; set; }
}
