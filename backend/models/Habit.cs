using System.ComponentModel.DataAnnotations;
using System.Collections.Generic; // Đảm bảo using này tồn tại

namespace backend.Models;

/// <summary>
/// Đại diện cho một thói quen trong hệ thống.
/// </summary>
public class Habit
{
    /// <summary>
    /// ID duy nhất của thói quen.
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Tên thói quen.
    /// </summary>
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Mô tả thói quen.
    /// </summary>
    [MaxLength(1000)]
    public string? Description { get; set; }

    /// <summary>
    /// ID của danh mục thói quen.
    /// </summary>
    [Required]
    public int CategoryId { get; set; }

    /// <summary>
    /// Danh mục thói quen (Navigation Property).
    /// </summary>
    public virtual Category Category { get; set; } = null!;

    /// <summary>
    /// ID của người dùng sở hữu thói quen.
    /// </summary>
    [Required]
    public string UserId { get; set; } = string.Empty;

    /// <summary>
    /// Người dùng sở hữu thói quen (Navigation Property).
    /// </summary>
    public virtual User User { get; set; } = null!;

    /// <summary>
    /// Ngày bắt đầu thói quen.
    /// </summary>
    [Required]
    public DateTime StartDate { get; set; }

    /// <summary>
    /// Ngày kết thúc thói quen (có thể null nếu không có ngày kết thúc).
    /// </summary>
    public DateTime? EndDate { get; set; }

    /// <summary>
    /// Tần suất thực hiện thói quen (Frequency gốc, có thể dùng làm fallback).
    /// Các giá trị: "daily", "weekly", "monthly", "custom"
    /// </summary>
    [Required]
    [MaxLength(20)]
    public string Frequency { get; set; } = "daily";

    // <<< ĐÃ XÓA DaysOfWeek và DaysOfMonth KHỎI ĐÂY >>>

    /// <summary>
    /// Giá trị tùy chỉnh cho tần suất (ví dụ: mỗi 2 ngày).
    /// Chỉ dùng nếu Frequency = "custom".
    /// </summary>
    public int? CustomFrequencyValue { get; set; }

    /// <summary>
    /// Đơn vị tùy chỉnh cho tần suất (ví dụ: "days", "weeks").
    /// Chỉ dùng nếu Frequency = "custom".
    /// </summary>
    [MaxLength(20)]
    public string? CustomFrequencyUnit { get; set; }

    /// <summary>
    /// Có nhắc nhở hay không.
    /// </summary>
    public bool HasReminder { get; set; } = false;

    /// <summary>
    /// Thời gian nhắc nhở (chỉ giờ:phút).
    /// </summary>
    public TimeSpan? ReminderTime { get; set; }

    /// <summary>
    /// Loại nhắc nhở: "notification", "sound", "both".
    /// </summary>
    [MaxLength(20)]
    public string? ReminderType { get; set; }

    /// <summary>
    /// Trạng thái hoạt động của thói quen.
    /// </summary>
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// Ngày tạo thói quen.
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Ngày cập nhật cuối cùng.
    /// </summary>
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Danh sách các lần thực hiện thói quen (Navigation Property).
    /// Đổi tên từ Completions để khớp code Controller/DTO
    /// </summary>
    public virtual ICollection<HabitCompletion> CompletionDates { get; set; } = new List<HabitCompletion>();

    /// <summary>
    /// Lịch trình chi tiết của thói quen (Navigation Property - Một-Một).
    /// </summary>
    public virtual HabitSchedule? HabitSchedule { get; set; } // <<< SỬA THÀNH MỘT-MỘT (có thể null)
}

// Lớp HabitCompletion giữ nguyên như bạn đã cung cấp
public class HabitCompletion
{
    public int Id { get; set; }
    [Required]
    public int HabitId { get; set; }
    public virtual Habit Habit { get; set; } = null!;
    [Required]
    public DateTime CompletedAt { get; set; }
    [MaxLength(500)]
    public string? Notes { get; set; }
}