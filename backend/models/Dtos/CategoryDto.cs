namespace backend.Models.Dtos;

/// <summary>
/// DTO cho việc tạo danh mục mới.
/// </summary>
public class CreateCategoryDto
{
    /// <summary>
    /// Tên danh mục.
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Màu sắc của danh mục (hex color code).
    /// </summary>
    public string Color { get; set; } = "#FF0000";

    /// <summary>
    /// Icon của danh mục.
    /// </summary>
    public string Icon { get; set; } = "default";
}

/// <summary>
/// DTO cho việc cập nhật danh mục.
/// </summary>
public class UpdateCategoryDto
{
    /// <summary>
    /// Tên danh mục.
    /// </summary>
    public string? Name { get; set; }

    /// <summary>
    /// Màu sắc của danh mục.
    /// </summary>
    public string? Color { get; set; }

    /// <summary>
    /// Icon của danh mục.
    /// </summary>
    public string? Icon { get; set; }
}

/// <summary>
/// DTO cho việc trả về thông tin danh mục.
/// </summary>
public class CategoryResponseDto
{
    /// <summary>
    /// ID của danh mục.
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Tên danh mục.
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Màu sắc của danh mục.
    /// </summary>
    public string Color { get; set; } = string.Empty;

    /// <summary>
    /// Icon của danh mục.
    /// </summary>
    public string Icon { get; set; } = string.Empty;

    /// <summary>
    /// Số lượng thói quen trong danh mục này.
    /// </summary>
    public int HabitCount { get; set; }

    /// <summary>
    /// Ngày tạo danh mục.
    /// </summary>
    public DateTime CreatedAt { get; set; }
}

