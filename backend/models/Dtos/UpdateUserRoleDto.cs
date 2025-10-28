using System.ComponentModel.DataAnnotations;

namespace backend.Models.Dtos;

/// <summary>
/// DTO cho việc cập nhật role của user
/// </summary>
public class UpdateUserRoleDto
{
    [Required(ErrorMessage = "User ID là bắt buộc")]
    public string UserId { get; set; } = string.Empty;

    [Required(ErrorMessage = "Role mới là bắt buộc")]
    public string Role { get; set; } = string.Empty; // "Admin" hoặc "User"
}
