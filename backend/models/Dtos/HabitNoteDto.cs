using System.ComponentModel.DataAnnotations;

namespace backend.Models.Dtos;

/// <summary>
/// DTO cho việc tạo ghi chú nhật ký thói quen mới.
/// </summary>
public class CreateHabitNoteDto
{
    /// <summary>
    /// ID của thói quen.
    /// </summary>
    [Required]
    public int HabitId { get; set; }

    /// <summary>
    /// Ngày ghi chú.
    /// </summary>
    [Required]
    public DateTime Date { get; set; }

    /// <summary>
    /// Nội dung ghi chú.
    /// </summary>
    [Required]
    [MaxLength(1000)]
    public string Content { get; set; } = string.Empty;

    /// <summary>
    /// Mức độ cảm xúc (1-5).
    /// </summary>
    [Range(1, 5)]
    public int? Mood { get; set; }
}

/// <summary>
/// DTO cho việc cập nhật ghi chú nhật ký thói quen.
/// </summary>
public class UpdateHabitNoteDto
{
    /// <summary>
    /// Nội dung ghi chú mới.
    /// </summary>
    [MaxLength(1000)]
    public string? Content { get; set; }

    /// <summary>
    /// Mức độ cảm xúc mới (1-5).
    /// </summary>
    [Range(1, 5)]
    public int? Mood { get; set; }
}

/// <summary>
/// DTO cho việc trả về thông tin ghi chú nhật ký thói quen.
/// </summary>
public class HabitNoteResponseDto
{
    /// <summary>
    /// ID của ghi chú.
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// ID của thói quen.
    /// </summary>
    public int HabitId { get; set; }

    /// <summary>
    /// Tên thói quen.
    /// </summary>
    public string HabitName { get; set; } = string.Empty;

    /// <summary>
    /// Ngày ghi chú.
    /// </summary>
    public DateTime Date { get; set; }

    /// <summary>
    /// Nội dung ghi chú.
    /// </summary>
    public string Content { get; set; } = string.Empty;

    /// <summary>
    /// Mức độ cảm xúc (1-5).
    /// </summary>
    public int? Mood { get; set; }

    /// <summary>
    /// Biểu tượng cảm xúc tương ứng.
    /// </summary>
    public string? MoodEmoji { get; set; }

    /// <summary>
    /// Thời điểm tạo ghi chú.
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// Thời điểm cập nhật cuối cùng.
    /// </summary>
    public DateTime UpdatedAt { get; set; }
}