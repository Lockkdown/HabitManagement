using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace backend.Models;

/// <summary>
/// Đại diện cho một ghi chú nhật ký thói quen trong hệ thống.
/// Cho phép người dùng ghi lại cảm nghĩ, lý do hoàn thành hoặc chưa hoàn thành mỗi ngày cho từng thói quen.
/// </summary>
public class HabitNote
{
    /// <summary>
    /// ID duy nhất của ghi chú nhật ký.
    /// </summary>
    [Key]
    [Column("note_id")]
    public int Id { get; set; }

    /// <summary>
    /// ID của thói quen liên kết.
    /// </summary>
    [Required]
    [Column("habit_id")]
    [ForeignKey("Habit")]
    public int HabitId { get; set; }

    /// <summary>
    /// Thói quen được ghi chú.
    /// </summary>
    public virtual Habit Habit { get; set; } = null!;

    /// <summary>
    /// Ngày ghi chú (chỉ lưu ngày, không lưu giờ).
    /// </summary>
    [Required]
    [Column("date", TypeName = "date")]
    public DateTime Date { get; set; }

    /// <summary>
    /// Nội dung ghi chú của người dùng.
    /// </summary>
    [Required]
    [Column("content")]
    [MaxLength(1000)]
    public string Content { get; set; } = string.Empty;

    /// <summary>
    /// Mức độ cảm xúc (1-5).
    /// 1: Rất buồn 😢
    /// 2: Buồn 😞
    /// 3: Bình thường 😐
    /// 4: Vui 😊
    /// 5: Rất vui 😄
    /// Có thể null nếu người dùng không chọn cảm xúc.
    /// </summary>
    [Column("mood")]
    [Range(1, 5)]
    public int? Mood { get; set; }

    /// <summary>
    /// Thời điểm tạo ghi chú.
    /// </summary>
    [Required]
    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Thời điểm cập nhật cuối cùng.
    /// </summary>
    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}