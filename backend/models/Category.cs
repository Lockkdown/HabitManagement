using System.ComponentModel.DataAnnotations;

namespace backend.Models;

/// <summary>
/// Đại diện cho một danh mục thói quen trong hệ thống.
/// </summary>
public class Category
{
    /// <summary>
    /// ID duy nhất của danh mục.
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Tên danh mục.
    /// </summary>
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Màu sắc của danh mục (hex color code).
    /// </summary>
    [Required]
    [MaxLength(7)]
    public string Color { get; set; } = "#FF0000";

    /// <summary>
    /// Icon của danh mục (tên icon từ icon library).
    /// </summary>
    [Required]
    [MaxLength(50)]
    public string Icon { get; set; } = "default";

    /// <summary>
    /// ID của người dùng tạo danh mục này.
    /// </summary>
    [Required]
    public string UserId { get; set; } = string.Empty;

    /// <summary>
    /// Người dùng sở hữu danh mục này.
    /// </summary>
    public virtual User User { get; set; } = null!;

    /// <summary>
    /// Ngày tạo danh mục.
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Ngày cập nhật cuối cùng.
    /// </summary>
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Danh sách thói quen thuộc danh mục này.
    /// </summary>
    public virtual ICollection<Habit> Habits { get; set; } = new List<Habit>();
}

