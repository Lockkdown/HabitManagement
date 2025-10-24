namespace backend.Models.Dtos;

/// <summary>
/// DTO cho việc tạo thói quen mới.
/// </summary>
public class CreateHabitDto
{
    /// <summary>
    /// Tên thói quen.
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Mô tả thói quen.
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// ID của danh mục thói quen.
    /// </summary>
    public int CategoryId { get; set; }

    /// <summary>
    /// Ngày bắt đầu thói quen.
    /// </summary>
    public DateTime StartDate { get; set; }

    /// <summary>
    /// Ngày kết thúc thói quen (có thể null).
    /// </summary>
    public DateTime? EndDate { get; set; }

    /// <summary>
    /// Tần suất thực hiện thói quen.
    /// </summary>
    public string Frequency { get; set; } = "daily";

    /// <summary>
    /// Giá trị tùy chỉnh cho tần suất.
    /// </summary>
    public int? CustomFrequencyValue { get; set; }

    /// <summary>
    /// Đơn vị tùy chỉnh cho tần suất.
    /// </summary>
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
    /// Loại nhắc nhở.
    /// </summary>
    public string? ReminderType { get; set; }
}

/// <summary>
/// DTO cho việc cập nhật thói quen.
/// </summary>
public class UpdateHabitDto
{
    /// <summary>
    /// Tên thói quen.
    /// </summary>
    public string? Name { get; set; }

    /// <summary>
    /// Mô tả thói quen.
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// ID của danh mục thói quen.
    /// </summary>
    public int? CategoryId { get; set; }

    /// <summary>
    /// Ngày bắt đầu thói quen.
    /// </summary>
    public DateTime? StartDate { get; set; }

    /// <summary>
    /// Ngày kết thúc thói quen.
    /// </summary>
    public DateTime? EndDate { get; set; }

    /// <summary>
    /// Tần suất thực hiện thói quen.
    /// </summary>
    public string? Frequency { get; set; }

    /// <summary>
    /// Giá trị tùy chỉnh cho tần suất.
    /// </summary>
    public int? CustomFrequencyValue { get; set; }

    /// <summary>
    /// Đơn vị tùy chỉnh cho tần suất.
    /// </summary>
    public string? CustomFrequencyUnit { get; set; }

    /// <summary>
    /// Có nhắc nhở hay không.
    /// </summary>
    public bool? HasReminder { get; set; }

    /// <summary>
    /// Thời gian nhắc nhở.
    /// </summary>
    public TimeSpan? ReminderTime { get; set; }

    /// <summary>
    /// Loại nhắc nhở.
    /// </summary>
    public string? ReminderType { get; set; }

    /// <summary>
    /// Trạng thái hoạt động.
    /// </summary>
    public bool? IsActive { get; set; }
}

/// <summary>
/// DTO cho việc trả về thông tin thói quen.
/// </summary>
public class HabitResponseDto
{
    /// <summary>
    /// ID của thói quen.
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Tên thói quen.
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Mô tả thói quen.
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// Thông tin danh mục.
    /// </summary>
    public CategoryResponseDto Category { get; set; } = null!;

    /// <summary>
    /// Ngày bắt đầu thói quen.
    /// </summary>
    public DateTime StartDate { get; set; }

    /// <summary>
    /// Ngày kết thúc thói quen.
    /// </summary>
    public DateTime? EndDate { get; set; }

    /// <summary>
    /// Tần suất thực hiện thói quen.
    /// </summary>
    public string Frequency { get; set; } = string.Empty;

    /// <summary>
    /// Có nhắc nhở hay không.
    /// </summary>
    public bool HasReminder { get; set; }

    /// <summary>
    /// Thời gian nhắc nhở.
    /// </summary>
    public TimeSpan? ReminderTime { get; set; }

    /// <summary>
    /// Loại nhắc nhở.
    /// </summary>
    public string? ReminderType { get; set; }

    /// <summary>
    /// Trạng thái hoạt động.
    /// </summary>
    public bool IsActive { get; set; }

    /// <summary>
    /// Số lần hoàn thành trong tuần này.
    /// </summary>
    public int WeeklyCompletions { get; set; }

    /// <summary>
    /// Số lần hoàn thành trong tháng này.
    /// </summary>
    public int MonthlyCompletions { get; set; }

    /// <summary>
    /// Ngày tạo thói quen.
    /// </summary>
    public DateTime CreatedAt { get; set; }
}

/// <summary>
/// DTO cho việc đánh dấu hoàn thành thói quen.
/// </summary>
public class CompleteHabitDto
{
    /// <summary>
    /// Ghi chú cho lần hoàn thành.
    /// </summary>
    public string? Notes { get; set; }

    /// <summary>
    /// Ngày hoàn thành (mặc định là hôm nay).
    /// </summary>
    public DateTime? CompletedAt { get; set; }
}

