using System.ComponentModel.DataAnnotations;

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
    /// Danh mục thói quen.
    /// </summary>
    public virtual Category Category { get; set; } = null!;

    /// <summary>
    /// ID của người dùng sở hữu thói quen.
    /// </summary>
    [Required]
    public string UserId { get; set; } = string.Empty;

    /// <summary>
    /// Người dùng sở hữu thói quen.
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
    /// Tần suất thực hiện thói quen.
    /// Các giá trị: "daily", "weekly", "monthly", "custom"
    /// </summary>
    [Required]
    [MaxLength(20)]
    public string Frequency { get; set; } = "daily";

    /// <summary>
    /// Giá trị tùy chỉnh cho tần suất (ví dụ: mỗi 2 ngày).
    /// </summary>
    public int? CustomFrequencyValue { get; set; }

    /// <summary>
    /// Đơn vị tùy chỉnh cho tần suất (ví dụ: "days", "weeks").
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
    /// Danh sách các lần thực hiện thói quen.
    /// </summary>
    public virtual ICollection<HabitCompletion> Completions { get; set; } = new List<HabitCompletion>();

    /// <summary>
    /// Danh sách lịch trình của thói quen.
    /// </summary>
    public virtual ICollection<HabitSchedule> HabitSchedules { get; set; } = new List<HabitSchedule>();
}

/// <summary>
/// Đại diện cho một lần hoàn thành thói quen.
/// </summary>
public class HabitCompletion
{
    /// <summary>
    /// ID duy nhất của lần hoàn thành.
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// ID của thói quen.
    /// </summary>
    [Required]
    public int HabitId { get; set; }

    /// <summary>
    /// Thói quen được hoàn thành.
    /// </summary>
    public virtual Habit Habit { get; set; } = null!;

    /// <summary>
    /// Ngày hoàn thành thói quen.
    /// </summary>
    [Required]
    public DateTime CompletedAt { get; set; }

    /// <summary>
    /// Ghi chú cho lần hoàn thành này.
    /// </summary>
    [MaxLength(500)]
    public string? Notes { get; set; }
}

