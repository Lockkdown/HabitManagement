using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using backend.Data;
using backend.Models;
using backend.Models.Dtos;
using System.Security.Claims;
using System.Text.Json; // Thêm using này để Serialize

namespace backend.Controllers;

/// <summary>
/// Controller quản lý thói quen.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class HabitController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public HabitController(ApplicationDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Lấy danh sách tất cả thói quen của người dùng hiện tại.
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<HabitResponseDto>>> GetHabits()
    {
        try
        {
            var userId = GetCurrentUserId();
            Console.WriteLine($"GetHabits called for userId: {userId}");
            
            if (userId == null) 
            {
                Console.WriteLine("GetHabits: userId is null, returning Unauthorized");
                return Unauthorized();
            }

            Console.WriteLine($"GetHabits: Querying habits for userId: {userId}");
            
            // QUAN TRỌNG: Include HabitSchedule ở đây để GetHabits trả về schedule luôn
            var habits = await _context.Habits
                .Where(h => h.UserId == userId)
                .Include(h => h.Category)
                .Include(h => h.HabitSchedule) // <<< ĐÃ THÊM
                .Include(h => h.CompletionDates) // <<< ĐÃ THÊM (Đổi tên từ Completions)
                .ToListAsync();

            var habitDtos = new List<HabitResponseDto>();
            foreach (var habit in habits)
            {
                var weeklyCompletions = await _context.HabitCompletions
                    .CountAsync(c => c.HabitId == habit.Id && 
                                c.CompletedAt >= DateTime.UtcNow.AddDays(-7));
                var monthlyCompletions = await _context.HabitCompletions
                    .CountAsync(c => c.HabitId == habit.Id && 
                                c.CompletedAt >= DateTime.UtcNow.AddDays(-30));

                // Get completion dates for this habit (đã Include, không cần query lại)
                var completionDates = habit.CompletionDates
                    .Select(c => c.CompletedAt)
                    .OrderBy(d => d)
                    .ToList();

                habitDtos.Add(new HabitResponseDto
                {
                    Id = habit.Id,
                    Name = habit.Name,
                    Description = habit.Description,
                    Category = new CategoryResponseDto // Đảm bảo Category không null
                    {
                        Id = habit.Category?.Id ?? 0,
                        Name = habit.Category?.Name ?? "N/A",
                        Color = habit.Category?.Color ?? "#808080",
                        Icon = habit.Category?.Icon ?? "help",
                        HabitCount = 0, 
                        CreatedAt = habit.Category?.CreatedAt ?? DateTime.MinValue
                    },
                    StartDate = habit.StartDate,
                    EndDate = habit.EndDate,
                    Frequency = habit.Frequency,
                    HasReminder = habit.HasReminder,
                    ReminderTime = habit.ReminderTime,
                    ReminderType = habit.ReminderType,
                    IsActive = habit.IsActive,
                    WeeklyCompletions = weeklyCompletions,
                    MonthlyCompletions = monthlyCompletions,
                    CreatedAt = habit.CreatedAt,
                    CompletionDates = completionDates,
                    // Map HabitSchedule sang DTO nếu nó tồn tại
                    HabitSchedule = habit.HabitSchedule == null ? null : new HabitScheduleDto
                    {
                         Id = habit.HabitSchedule.Id,
                         HabitId = habit.HabitSchedule.HabitId,
                         FrequencyType = habit.HabitSchedule.FrequencyType,
                         FrequencyValue = habit.HabitSchedule.FrequencyValue,
                         DaysOfWeek = habit.HabitSchedule.DaysOfWeek,
                         DaysOfMonth = habit.HabitSchedule.DaysOfMonth, // <<< SỬA: Dùng DaysOfMonth (string)
                         IsActive = habit.HabitSchedule.IsActive
                    }
                });
            }

            Console.WriteLine($"GetHabits: Found {habitDtos.Count} habits for userId: {userId}");
            return Ok(habitDtos);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"GetHabits error: {ex.Message}");
            Console.WriteLine($"Stack trace: {ex.StackTrace}");
            return StatusCode(500, new { message = "Lỗi server: " + ex.Message });
        }
    }

    /// <summary>
    /// Lấy thông tin chi tiết của một thói quen.
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<HabitResponseDto>> GetHabit(int id)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var habit = await _context.Habits
            .Where(h => h.Id == id && h.UserId == userId)
            .Include(h => h.Category)
            .Include(h => h.HabitSchedule) // <<< ĐÃ THÊM
            .Include(h => h.CompletionDates) // <<< ĐÃ THÊM
            .FirstOrDefaultAsync();

        if (habit == null) return NotFound();

        var weeklyCompletions = await _context.HabitCompletions
            .CountAsync(c => c.HabitId == habit.Id && 
                           c.CompletedAt >= DateTime.UtcNow.AddDays(-7));
        var monthlyCompletions = await _context.HabitCompletions
            .CountAsync(c => c.HabitId == habit.Id && 
                           c.CompletedAt >= DateTime.UtcNow.AddDays(-30));

        var completionDates = habit.CompletionDates
            .Select(c => c.CompletedAt)
            .OrderBy(d => d)
            .ToList();

        var response = new HabitResponseDto
        {
            Id = habit.Id,
            Name = habit.Name,
            Description = habit.Description,
             Category = new CategoryResponseDto
            {
                Id = habit.Category?.Id ?? 0,
                Name = habit.Category?.Name ?? "N/A",
                Color = habit.Category?.Color ?? "#808080",
                Icon = habit.Category?.Icon ?? "help",
                HabitCount = 0, 
                CreatedAt = habit.Category?.CreatedAt ?? DateTime.MinValue
            },
            StartDate = habit.StartDate,
            EndDate = habit.EndDate,
            Frequency = habit.Frequency,
            HasReminder = habit.HasReminder,
            ReminderTime = habit.ReminderTime,
            ReminderType = habit.ReminderType,
            IsActive = habit.IsActive,
            WeeklyCompletions = weeklyCompletions,
            MonthlyCompletions = monthlyCompletions,
            CreatedAt = habit.CreatedAt,
            CompletionDates = completionDates,
            HabitSchedule = habit.HabitSchedule == null ? null : new HabitScheduleDto
            {
                 Id = habit.HabitSchedule.Id,
                 HabitId = habit.HabitSchedule.HabitId,
                 FrequencyType = habit.HabitSchedule.FrequencyType,
                 FrequencyValue = habit.HabitSchedule.FrequencyValue,
                 DaysOfWeek = habit.HabitSchedule.DaysOfWeek,
                 DaysOfMonth = habit.HabitSchedule.DaysOfMonth, // <<< SỬA: Dùng DaysOfMonth (string)
                 IsActive = habit.HabitSchedule.IsActive
            }
        };

        return Ok(response);
    }

    /// <summary>
    /// Tạo thói quen mới.
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<HabitResponseDto>> CreateHabit(CreateHabitDto dto)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var category = await _context.Categories
            .FirstOrDefaultAsync(c => c.Id == dto.CategoryId && c.UserId == userId);

        if (category == null) return BadRequest("Danh mục không tồn tại");

        var habit = new Habit
        {
            Name = dto.Name,
            Description = dto.Description,
            CategoryId = dto.CategoryId,
            UserId = userId,
            StartDate = dto.StartDate.Date, // Chỉ lấy phần ngày
            EndDate = dto.EndDate?.Date,   // Chỉ lấy phần ngày nếu có
            Frequency = dto.Frequency,
            // Xóa DaysOfWeek/DaysOfMonth khỏi Habit
            CustomFrequencyValue = dto.CustomFrequencyValue,
            CustomFrequencyUnit = dto.CustomFrequencyUnit,
            HasReminder = dto.HasReminder,
            ReminderTime = dto.ReminderTime,
            ReminderType = dto.ReminderType,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.Habits.Add(habit);
        await _context.SaveChangesAsync(); 

        // --- Tạo đối tượng HabitSchedule liên kết ---
        var schedule = new HabitSchedule
        {
            HabitId = habit.Id,
            FrequencyType = dto.Frequency,
            FrequencyValue = 1, 
            DaysOfWeek = null,
            DaysOfMonth = null, // <<< SỬA: Khởi tạo là null
            IsActive = true
        };

        var intToDayStringMap = new Dictionary<int, string> {
            {1, "Mon"}, {2, "Tue"}, {3, "Wed"}, {4, "Thu"}, {5, "Fri"}, {6, "Sat"}, {7, "Sun"}
        };

        switch (dto.Frequency.ToLower())
        {
            case "weekly":
                schedule.DaysOfWeek = (dto.DaysOfWeek != null && dto.DaysOfWeek.Any())
                    ? string.Join(",", dto.DaysOfWeek.Select(d => intToDayStringMap.ContainsKey(d) ? intToDayStringMap[d] : null)
                                                  .Where(s => s != null))
                    : null;
                Console.WriteLine($"Creating schedule for weekly: DaysOfWeek set to '{schedule.DaysOfWeek}'");
                break;
            
            // ==========================================================
            // <<< SỬA ĐỔI TẠI ĐÂY (CreateHabit) >>>
            // ==========================================================
            case "monthly":
                // Chuyển List<int> [16, 17] thành chuỗi "16,17"
                schedule.DaysOfMonth = (dto.DaysOfMonth != null && dto.DaysOfMonth.Any())
                    ? string.Join(",", dto.DaysOfMonth) // Nối list thành chuỗi
                    : null;
                Console.WriteLine($"Creating schedule for monthly: DaysOfMonth set to '{schedule.DaysOfMonth}'");
                break;
            // ==========================================================

             case "daily":
                schedule.FrequencyValue = dto.CustomFrequencyValue ?? 1; 
                Console.WriteLine($"Creating schedule for daily: FrequencyValue set to '{schedule.FrequencyValue}'");
                break;
        }

        _context.HabitSchedules.Add(schedule);
        await _context.SaveChangesAsync();

        await _context.Entry(habit).Reference(h => h.Category).LoadAsync();
        habit.HabitSchedule = schedule; 

        var response = new HabitResponseDto
        {
            Id = habit.Id,
            Name = habit.Name,
            Description = habit.Description,
            Category = new CategoryResponseDto
            {
                Id = habit.Category.Id,
                Name = habit.Category.Name,
                Color = habit.Category.Color,
                Icon = habit.Category.Icon,
                HabitCount = 0,
                CreatedAt = habit.Category.CreatedAt
            },
            StartDate = habit.StartDate,
            EndDate = habit.EndDate,
            Frequency = habit.Frequency,
            HasReminder = habit.HasReminder,
            ReminderTime = habit.ReminderTime,
            ReminderType = habit.ReminderType,
            IsActive = habit.IsActive,
            WeeklyCompletions = 0,
            MonthlyCompletions = 0,
            CreatedAt = habit.CreatedAt,
            CompletionDates = new List<DateTime>(), 
            HabitSchedule = new HabitScheduleDto 
            {
                 Id = schedule.Id,
                 HabitId = schedule.HabitId,
                 FrequencyType = schedule.FrequencyType,
                 FrequencyValue = schedule.FrequencyValue,
                 DaysOfWeek = schedule.DaysOfWeek,
                 DaysOfMonth = schedule.DaysOfMonth, // <<< SỬA: Dùng DaysOfMonth (string)
                 IsActive = schedule.IsActive
            }
        };

        return CreatedAtAction(nameof(GetHabit), new { id = habit.Id }, response);
    }

    // ==========================================================
    // <<< BẮT ĐẦU SỬA PHƯƠNG THỨC UPDATE >>>
    // ==========================================================
    /// <summary>
    /// Cập nhật thói quen.
    /// </summary>
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateHabit(int id, UpdateHabitDto dto) 
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var habit = await _context.Habits
            .Include(h => h.HabitSchedule) // <<< ĐÃ THÊM
            .FirstOrDefaultAsync(h => h.Id == id && h.UserId == userId);

        if (habit == null) return NotFound();

        // --- 1. Cập nhật các trường cơ bản của Habit ---
        habit.Name = dto.Name ?? habit.Name;
        habit.Description = dto.Description; 
        habit.CategoryId = dto.CategoryId ?? habit.CategoryId;
        habit.StartDate = dto.StartDate?.Date ?? habit.StartDate; 
        habit.EndDate = dto.EndDate?.Date;   
        habit.HasReminder = dto.HasReminder ?? habit.HasReminder;
        habit.ReminderTime = dto.ReminderTime; 
        habit.ReminderType = dto.ReminderType;
        habit.IsActive = dto.IsActive ?? habit.IsActive;

        // --- 2. Cập nhật Frequency gốc VÀ HabitSchedule ---
        bool scheduleChanged = false;
        if (dto.Frequency != null)
        {
            habit.Frequency = dto.Frequency; 

            var schedule = habit.HabitSchedule;
            if (schedule == null)
            {
                Console.WriteLine($"Habit {id} has no schedule, creating new one.");
                schedule = new HabitSchedule { HabitId = habit.Id };
                _context.HabitSchedules.Add(schedule);
                habit.HabitSchedule = schedule; 
            }

            schedule.FrequencyType = dto.Frequency; 
            schedule.IsActive = dto.IsActive ?? schedule.IsActive; 

            var intToDayStringMap = new Dictionary<int, string> {
                {1, "Mon"}, {2, "Tue"}, {3, "Wed"}, {4, "Thu"}, {5, "Fri"}, {6, "Sat"}, {7, "Sun"}
            };

            switch (dto.Frequency.ToLower())
            {
                case "weekly":
                    var newDaysOfWeek = (dto.DaysOfWeek != null && dto.DaysOfWeek.Any())
                        ? string.Join(",", dto.DaysOfWeek.Select(d => intToDayStringMap.ContainsKey(d) ? intToDayStringMap[d] : null)
                                                      .Where(s => s != null))
                        : null;
                     if (schedule.DaysOfWeek != newDaysOfWeek) {
                         schedule.DaysOfWeek = newDaysOfWeek;
                         scheduleChanged = true;
                     }
                    schedule.DaysOfMonth = null; // <<< SỬA: Reset DaysOfMonth (string)
                    schedule.FrequencyValue = 1; 
                    Console.WriteLine($"Updating schedule for weekly: DaysOfWeek set to '{schedule.DaysOfWeek}'");
                    break;

                // ==========================================================
                // <<< SỬA ĐỔI TẠI ĐÂY (UpdateHabit) >>>
                // ==========================================================
                case "monthly":
                    // Chuyển List<int> [16, 17] thành chuỗi "16,17"
                    var newDaysOfMonth = (dto.DaysOfMonth != null && dto.DaysOfMonth.Any())
                        ? string.Join(",", dto.DaysOfMonth) // Nối list thành chuỗi
                        : null;
                     if (schedule.DaysOfMonth != newDaysOfMonth) {
                        schedule.DaysOfMonth = newDaysOfMonth;
                        scheduleChanged = true;
                     }
                    schedule.DaysOfWeek = null; // Reset trường không liên quan
                    schedule.FrequencyValue = 1; 
                     Console.WriteLine($"Updating schedule for monthly: DaysOfMonth set to '{schedule.DaysOfMonth}'");
                    break;
                // ==========================================================

                 case "daily":
                    var newFreqValue = dto.CustomFrequencyValue ?? 1;
                    if(schedule.FrequencyValue != newFreqValue) {
                        schedule.FrequencyValue = newFreqValue;
                        scheduleChanged = true;
                    }
                    schedule.DaysOfWeek = null; 
                    schedule.DaysOfMonth = null; // <<< SỬA: Reset DaysOfMonth (string)
                    Console.WriteLine($"Updating schedule for daily: FrequencyValue set to '{schedule.FrequencyValue}'");
                    break;

                default: 
                    if (schedule.DaysOfWeek != null) { schedule.DaysOfWeek = null; scheduleChanged = true; }
                    if (schedule.DaysOfMonth != null) { schedule.DaysOfMonth = null; scheduleChanged = true; } // <<< SỬA
                    if (schedule.FrequencyValue != 1) { schedule.FrequencyValue = 1; scheduleChanged = true; }
                    Console.WriteLine($"Updating schedule for frequency '{dto.Frequency}': Resetting specific days.");
                    break;
            }
             if (scheduleChanged || schedule.Id == 0) {
                 _context.Entry(schedule).State = schedule.Id == 0 ? EntityState.Added : EntityState.Modified;
             }
        }
        
        // <<< XÓA KHỐI 'else' Ở ĐÂY >>>
        // (Khối 'else' cũ (dòng 342-364) đã bị xóa vì logic được gộp vào 'if (dto.Frequency != null)')

        habit.UpdatedAt = DateTime.UtcNow;
        _context.Entry(habit).State = EntityState.Modified;

        try
        {
            var changes = await _context.SaveChangesAsync();
            Console.WriteLine($"Successfully updated habit {id}. {changes} entities saved.");
        }
        catch (DbUpdateConcurrencyException ex)
        {
             Console.WriteLine($"Concurrency error updating habit {id}: {ex.Message}");
             return Conflict(new { message = "Dữ liệu đã bị thay đổi.", error = ex.Message });
        }
        catch (Exception ex)
        {
             Console.WriteLine($"Error saving changes for habit {id}: {ex.Message}");
             Console.WriteLine($"Stack trace: {ex.StackTrace}");
             return StatusCode(500, new { message = "Lỗi khi lưu thay đổi.", error = ex.Message });
        }

        return NoContent(); 
    }
    // ==========================================================
    // <<< KẾT THÚC SỬA PHƯƠNG THỨC UPDATE >>>
    // ==========================================================

    /// <summary>
    /// Xóa thói quen.
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteHabit(int id)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var habit = await _context.Habits
            .Include(h => h.HabitSchedule)
            .Include(h => h.CompletionDates) // <<< SỬA: Đổi tên
            .FirstOrDefaultAsync(h => h.Id == id && h.UserId == userId);

        if (habit == null) return NotFound();

        // EF Core sẽ tự xóa HabitSchedule và HabitCompletions nếu đã cấu hình Cascade Delete
        _context.Habits.Remove(habit); 

        try 
        {
            await _context.SaveChangesAsync();
        } 
        catch (DbUpdateException ex) 
        {
             Console.WriteLine($"Error deleting habit {id}: {ex.InnerException?.Message ?? ex.Message}");
             return StatusCode(500, new { message = "Lỗi khi xóa thói quen.", error = ex.InnerException?.Message ?? ex.Message });
        }

        return NoContent();
    }

    /// <summary>
    /// Đánh dấu hoàn thành thói quen.
    /// </summary>
    [HttpPost("{id}/complete")]
    public async Task<IActionResult> CompleteHabit(int id, CompleteHabitDto dto)
    {
        try
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            Console.WriteLine($"=== CompleteHabit DEBUG ===");
            Console.WriteLine($"HabitId: {id}, UserId: {userId}");
            Console.WriteLine($"DTO CompletedAt: {dto.CompletedAt}");
            Console.WriteLine($"DTO CompletedAt Kind: {dto.CompletedAt?.Kind}");
            Console.WriteLine($"Current UTC Now: {DateTime.UtcNow}");
            Console.WriteLine($"Current Local Now: {DateTime.Now}");

            var habit = await _context.Habits
                .FirstOrDefaultAsync(h => h.Id == id && h.UserId == userId);

            if (habit == null) return NotFound();

            // SỬA LỖI: Frontend đã gửi UTC, không cần chuyển đổi lại
            var completedAt = dto.CompletedAt ?? DateTime.UtcNow;
            Console.WriteLine($"Final CompletedAt (UTC): {completedAt}");
            Console.WriteLine($"Final CompletedAt Kind: {completedAt.Kind}");

            // SỬA LỖI: Lấy ngày từ UTC datetime (frontend gửi 12:00 UTC cùng ngày)
            var completedDateOnly = completedAt.Date; // Lấy ngày từ UTC
            Console.WriteLine($"CompletedAt UTC Date: {completedDateOnly:yyyy-MM-dd}");
            
            // Kiểm tra xem đã hoàn thành trong ngày này chưa (so sánh theo ngày UTC)
            var existingCompletions = await _context.HabitCompletions
                .Where(c => c.HabitId == id)
                .ToListAsync();
                
            bool alreadyCompletedToday = existingCompletions
                .Any(c => c.CompletedAt.Date == completedDateOnly);

            if (alreadyCompletedToday)
            {
                Console.WriteLine($"Habit {id} already completed on {completedDateOnly:yyyy-MM-dd} (UTC date).");
                return Ok(new { message = $"Thói quen đã được hoàn thành vào ngày {completedDateOnly:yyyy-MM-dd}." });
            }

            var completion = new HabitCompletion
            {
                HabitId = id,
                Notes = dto.Notes,
                CompletedAt = completedAt // Lưu giờ UTC
            };

            _context.HabitCompletions.Add(completion);
            await _context.SaveChangesAsync();

            Console.WriteLine($"Successfully completed habit {id} at {completedAt} (UTC date: {completedDateOnly:yyyy-MM-dd})");
            return Ok(new { message = "Đã đánh dấu hoàn thành thói quen", completionId = completion.Id });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error completing habit {id}: {ex.Message}");
            Console.WriteLine($"Stack trace: {ex.StackTrace}");
            return StatusCode(500, new { message = "Lỗi server: " + ex.Message });
        }
    }

    /// <summary>
    /// Lấy lịch sử hoàn thành thói quen.
    /// </summary>
    [HttpGet("{id}/completions")]
    public async Task<ActionResult<IEnumerable<object>>> GetHabitCompletions(int id, [FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var habit = await _context.Habits
            .AnyAsync(h => h.Id == id && h.UserId == userId);

        if (!habit) return NotFound();

        var query = _context.HabitCompletions
            .Where(c => c.HabitId == id);

        if (startDate.HasValue)
        {
            var startUtc = startDate.Value.ToUniversalTime();
            query = query.Where(c => c.CompletedAt >= startUtc);
        }
        if (endDate.HasValue)
        {
             var endUtc = endDate.Value.ToUniversalTime().AddDays(1).AddTicks(-1);
            query = query.Where(c => c.CompletedAt <= endUtc);
        }

        var completions = await query
            .OrderByDescending(c => c.CompletedAt)
            .Select(c => new
            {
                Id = c.Id,
                CompletedAt = c.CompletedAt, // Trả về giờ UTC
                Notes = c.Notes
            })
            .ToListAsync();

        return Ok(completions);
    }

    /// <summary>
    /// Xóa một completion cụ thể.
    /// </summary>
    [HttpDelete("{habitId}/completions/{completionId}")]
    public async Task<IActionResult> DeleteCompletion(int habitId, int completionId)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var habitExists = await _context.Habits
            .AnyAsync(h => h.Id == habitId && h.UserId == userId);

        if (!habitExists) return NotFound("Habit not found");

        var completion = await _context.HabitCompletions
            .FirstOrDefaultAsync(c => c.Id == completionId && c.HabitId == habitId);

        if (completion == null) return NotFound("Completion not found");

        _context.HabitCompletions.Remove(completion);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    /// <summary>
    /// Lấy ID của người dùng hiện tại từ JWT token.
    /// </summary>
    private string? GetCurrentUserId()
    {
        return User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    }
}