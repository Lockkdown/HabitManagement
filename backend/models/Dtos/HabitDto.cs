// File: backend/Models/Dtos/HabitDto.cs
using System;
using System.Collections.Generic; // Đảm bảo using này tồn tại

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
    /// Flutter gửi lên dạng List<int> (1-7, ISO).
    /// </summary>
    public List<int>? DaysOfWeek { get; set; } // <<< ĐÃ SỬA TỪ string?

    /// <summary>
    /// Các ngày trong tháng áp dụng cho tần suất "monthly".
    /// Flutter gửi lên dạng List<int> (1-31).
    /// </summary>
    public List<int>? DaysOfMonth { get; set; } // <<< ĐÃ SỬA TỪ string?

    public bool HasReminder { get; set; } = false;
    public TimeSpan? ReminderTime { get; set; } // Giữ TimeSpan
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
    /// Flutter gửi lên dạng List<int> (1-7, ISO).
    /// </summary>
    public List<int>? DaysOfWeek { get; set; } // <<< ĐÃ SỬA TỪ string?

    /// <summary>
    /// Các ngày trong tháng áp dụng cho tần suất "monthly".
    /// Flutter gửi lên dạng List<int> (1-31).
    /// </summary>
    public List<int>? DaysOfMonth { get; set; } // <<< ĐÃ SỬA TỪ string?

    public bool? HasReminder { get; set; }
    public TimeSpan? ReminderTime { get; set; } // Giữ TimeSpan
    public string? ReminderType { get; set; }
    public bool? IsActive { get; set; }
}

/// <summary>
/// DTO cho việc trả về thông tin thói quen.
/// </summary>
public class HabitResponseDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public CategoryResponseDto? Category { get; set; } // Đã sửa thành nullable
    public DateTime StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string Frequency { get; set; } = string.Empty;
    public bool HasReminder { get; set; }
    public TimeSpan? ReminderTime { get; set; }
    public string? ReminderType { get; set; }
    public bool IsActive { get; set; }
    public int WeeklyCompletions { get; set; }
    public int MonthlyCompletions { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<DateTime> CompletionDates { get; set; } = new List<DateTime>();

    // --- ĐÃ THÊM THUỘC TÍNH NÀY ---
    public HabitScheduleDto? HabitSchedule { get; set; } // <<< THÊM VÀO
}

/// <summary>
/// DTO cho việc đánh dấu hoàn thành thói quen.
/// </summary>
public class CompleteHabitDto
{
    public string? Notes { get; set; }
    public DateTime? CompletedAt { get; set; } // Client nên gửi giờ UTC hoặc kèm timezone
}