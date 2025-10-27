namespace backend.Models.Dtos;

/// <summary>
/// DTO cho việc tạo thói quen mới.
/// </summary>
public class CreateHabitDto
{

    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int CategoryId { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string Frequency { get; set; } = "daily";
    public int? CustomFrequencyValue { get; set; }
    public string? CustomFrequencyUnit { get; set; }
    
    

    /// <summary>
    /// Các ngày trong tuần áp dụng cho tần suất "weekly".
    /// Dạng lưu trữ JSON: "[1,3,5]" (Thứ 2, Thứ 4, Thứ 6)
    /// </summary>
    public string? DaysOfWeek { get; set; }

    /// <summary>
    /// Các ngày trong tháng áp dụng cho tần suất "monthly".
    /// Dạng lưu trữ JSON: "[5,10,25]" (ngày 5, 10, 25 trong tháng)
    /// </summary>
    public string? DaysOfMonth { get; set; }


    
    public bool HasReminder { get; set; } = false;
    public TimeSpan? ReminderTime { get; set; }
    public string? ReminderType { get; set; }
}

/// <summary>
/// DTO cho việc cập nhật thói quen.
/// </summary>
public class UpdateHabitDto
{

    public string? Name { get; set; }
    public string? Description { get; set; }
    public int? CategoryId { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? Frequency { get; set; }
    public int? CustomFrequencyValue { get; set; }
    public string? CustomFrequencyUnit { get; set; }



    /// <summary>
    /// Các ngày trong tuần áp dụng cho tần suất "weekly".
    /// Dạng lưu trữ JSON: "[1,3,5]" (Thứ 2, Thứ 4, Thứ 6)
    /// </summary>
    public string? DaysOfWeek { get; set; }

    /// <summary>
    /// Các ngày trong tháng áp dụng cho tần suất "monthly".
    /// Dạng lưu trữ JSON: "[5,10,25]" (ngày 5, 10, 25 trong tháng)
    /// </summary>
    public string? DaysOfMonth { get; set; }




    public bool? HasReminder { get; set; }
    public TimeSpan? ReminderTime { get; set; }
    public string? ReminderType { get; set; }
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

    /// <summary>
    /// Danh sách ngày hoàn thành thói quen.
    /// </summary>
    public List<DateTime> CompletionDates { get; set; } = new List<DateTime>();
}



/// <summary>
/// DTO cho việc đánh dấu hoàn thành thói quen.
/// </summary>
public class CompleteHabitDto
{
    public string? Notes { get; set; }
    public DateTime? CompletedAt { get; set; }
}

