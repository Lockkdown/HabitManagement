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
                .Include(h => h.HabitSchedule) // <<< THÊM INCLUDE SCHEDULE
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

                // Get completion dates for this habit
                var completionDates = await _context.HabitCompletions
                    .Where(c => c.HabitId == habit.Id)
                    .Select(c => c.CompletedAt)
                    .OrderBy(d => d)
                    .ToListAsync();

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
                        HabitCount = 0, // Tính toán nếu cần
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
                         DayOfMonth = habit.HabitSchedule.DayOfMonth,
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
            .Include(h => h.HabitSchedule) // <<< THÊM INCLUDE SCHEDULE
            .FirstOrDefaultAsync();

        if (habit == null) return NotFound();

        var weeklyCompletions = await _context.HabitCompletions
            .CountAsync(c => c.HabitId == habit.Id && 
                           c.CompletedAt >= DateTime.UtcNow.AddDays(-7));
        var monthlyCompletions = await _context.HabitCompletions
            .CountAsync(c => c.HabitId == habit.Id && 
                           c.CompletedAt >= DateTime.UtcNow.AddDays(-30));

        // Get completion dates for this habit
        var completionDates = await _context.HabitCompletions
            .Where(c => c.HabitId == habit.Id)
            .Select(c => c.CompletedAt)
            .OrderBy(d => d)
            .ToListAsync();

        var response = new HabitResponseDto
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
                HabitCount = 0, // Tính toán nếu cần
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
                 DayOfMonth = habit.HabitSchedule.DayOfMonth,
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

        // Kiểm tra xem category có tồn tại không
        var category = await _context.Categories
            .FirstOrDefaultAsync(c => c.Id == dto.CategoryId && c.UserId == userId);

        if (category == null) return BadRequest("Danh mục không tồn tại");

        // --- Tạo đối tượng Habit ---
        var habit = new Habit
        {
            Name = dto.Name,
            Description = dto.Description,
            CategoryId = dto.CategoryId,
            UserId = userId,
            StartDate = dto.StartDate.Date, // Chỉ lấy phần ngày
            EndDate = dto.EndDate?.Date,   // Chỉ lấy phần ngày nếu có
            Frequency = dto.Frequency,
            // KHÔNG lưu DaysOfWeek/DaysOfMonth trực tiếp vào Habit nữa
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
        // Lưu habit trước để có Id
        await _context.SaveChangesAsync(); 

        // --- Tạo đối tượng HabitSchedule liên kết ---
        var schedule = new HabitSchedule
        {
            HabitId = habit.Id, // Gán Id của habit vừa tạo
            FrequencyType = dto.Frequency,
            FrequencyValue = 1, // Mặc định là 1, sẽ cập nhật bên dưới nếu cần
            DaysOfWeek = null,
            DayOfMonth = 0,
            IsActive = true
        };

        // Map int (1-7) sang string ("Mon", "Tue"...) - Cần khớp với map Flutter gửi lên
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
            case "monthly":
                schedule.DayOfMonth = (dto.DaysOfMonth != null && dto.DaysOfMonth.Any())
                    ? dto.DaysOfMonth.First()
                    : 0;
                Console.WriteLine($"Creating schedule for monthly: DayOfMonth set to '{schedule.DayOfMonth}'");
                break;
             case "daily":
                // Giữ lại FrequencyValue nếu DTO cung cấp, nếu không thì mặc định là 1
                schedule.FrequencyValue = dto.CustomFrequencyValue ?? 1; 
                Console.WriteLine($"Creating schedule for daily: FrequencyValue set to '{schedule.FrequencyValue}'");
                break;
             // Thêm case "custom" nếu cần
        }

        _context.HabitSchedules.Add(schedule);
        await _context.SaveChangesAsync();

        // Load category để trả về response
        await _context.Entry(habit).Reference(h => h.Category).LoadAsync();
        // Gán schedule vào habit để trả về response (EF Core có thể tự làm điều này nếu quan hệ được định nghĩa đúng)
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
                HabitCount = 0, // Tính toán nếu cần
                CreatedAt = habit.Category.CreatedAt
            },
            StartDate = habit.StartDate,
            EndDate = habit.EndDate,
            Frequency = habit.Frequency,
            HasReminder = habit.HasReminder,
            ReminderTime = habit.ReminderTime,
            ReminderType = habit.ReminderType,
            IsActive = habit.IsActive,
            WeeklyCompletions = 0, // Mới tạo nên là 0
            MonthlyCompletions = 0, // Mới tạo nên là 0
            CreatedAt = habit.CreatedAt,
            CompletionDates = new List<DateTime>(), // Mới tạo nên rỗng
            HabitSchedule = new HabitScheduleDto // Map schedule DTO
            {
                 Id = schedule.Id,
                 HabitId = schedule.HabitId,
                 FrequencyType = schedule.FrequencyType,
                 FrequencyValue = schedule.FrequencyValue,
                 DaysOfWeek = schedule.DaysOfWeek,
                 DayOfMonth = schedule.DayOfMonth,
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
    public async Task<IActionResult> UpdateHabit(int id, UpdateHabitDto dto) // Đảm bảo DTO này có DaysOfWeek (List<int>), DaysOfMonth (List<int>)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        // Lấy Habit VÀ HabitSchedule liên kết
        var habit = await _context.Habits
            .Include(h => h.HabitSchedule) // <<< THÊM INCLUDE
            .FirstOrDefaultAsync(h => h.Id == id && h.UserId == userId);

        if (habit == null) return NotFound();

        // --- 1. Cập nhật các trường cơ bản của Habit ---
        // Dùng ?? để chỉ cập nhật nếu DTO có giá trị, giữ lại giá trị cũ nếu DTO là null/không có
        habit.Name = dto.Name ?? habit.Name;
        habit.Description = dto.Description; // Cho phép set Description thành null
        habit.CategoryId = dto.CategoryId ?? habit.CategoryId;
        habit.StartDate = dto.StartDate?.Date ?? habit.StartDate; // Chỉ lấy phần ngày
        habit.EndDate = dto.EndDate?.Date;   // Cho phép set EndDate thành null, chỉ lấy phần ngày
        habit.HasReminder = dto.HasReminder ?? habit.HasReminder;
        habit.ReminderTime = dto.ReminderTime; // Cho phép set ReminderTime thành null
        habit.ReminderType = dto.ReminderType; // Cho phép set ReminderType thành null
        habit.IsActive = dto.IsActive ?? habit.IsActive;

        // --- 2. Cập nhật Frequency gốc VÀ HabitSchedule ---
        bool scheduleChanged = false;
        if (dto.Frequency != null)
        {
            habit.Frequency = dto.Frequency; // Cập nhật Frequency gốc trên Habit

            // Tìm hoặc tạo mới HabitSchedule
            var schedule = habit.HabitSchedule;
            if (schedule == null)
            {
                Console.WriteLine($"Habit {id} has no schedule, creating new one.");
                schedule = new HabitSchedule { HabitId = habit.Id };
                _context.HabitSchedules.Add(schedule);
                habit.HabitSchedule = schedule; // Gán schedule mới tạo vào habit
            }

            // Cập nhật các trường của HabitSchedule
            schedule.FrequencyType = dto.Frequency; // Luôn cập nhật FrequencyType
            schedule.IsActive = dto.IsActive ?? schedule.IsActive; // Đồng bộ IsActive

            // Map int (1-7) sang string ("Mon", "Tue"...) - Cần khớp với map Flutter UpdateHabitModel.toJson()
            var intToDayStringMap = new Dictionary<int, string> {
                {1, "Mon"}, {2, "Tue"}, {3, "Wed"}, {4, "Thu"}, {5, "Fri"}, {6, "Sat"}, {7, "Sun"}
            };

            switch (dto.Frequency.ToLower())
            {
                case "weekly":
                    // Chuyển List<int> từ DTO thành chuỗi "Mon,Wed"
                    var newDaysOfWeek = (dto.DaysOfWeek != null && dto.DaysOfWeek.Any())
                        ? string.Join(",", dto.DaysOfWeek.Select(d => intToDayStringMap.ContainsKey(d) ? intToDayStringMap[d] : null)
                                                      .Where(s => s != null))
                        : null;
                     if (schedule.DaysOfWeek != newDaysOfWeek) {
                         schedule.DaysOfWeek = newDaysOfWeek;
                         scheduleChanged = true;
                     }
                    schedule.DayOfMonth = 0; // Reset trường không liên quan
                    schedule.FrequencyValue = 1; // Mặc định cho weekly
                    Console.WriteLine($"Updating schedule for weekly: DaysOfWeek set to '{schedule.DaysOfWeek}'");
                    break;

                case "monthly":
                    // Lấy ngày đầu tiên từ List<int> (nếu có)
                    var newDayOfMonth = (dto.DaysOfMonth != null && dto.DaysOfMonth.Any())
                        ? dto.DaysOfMonth.First()
                        : 0;
                     if (schedule.DayOfMonth != newDayOfMonth) {
                        schedule.DayOfMonth = newDayOfMonth;
                        scheduleChanged = true;
                     }
                    schedule.DaysOfWeek = null; // Reset trường không liên quan
                    schedule.FrequencyValue = 1; // Mặc định cho monthly
                     Console.WriteLine($"Updating schedule for monthly: DayOfMonth set to '{schedule.DayOfMonth}'");
                    break;

                 case "daily":
                    var newFreqValue = dto.CustomFrequencyValue ?? 1;
                    if(schedule.FrequencyValue != newFreqValue) {
                        schedule.FrequencyValue = newFreqValue;
                        scheduleChanged = true;
                    }
                    schedule.DaysOfWeek = null; // Reset
                    schedule.DayOfMonth = 0;   // Reset
                    Console.WriteLine($"Updating schedule for daily: FrequencyValue set to '{schedule.FrequencyValue}'");
                    break;

                 // Bạn có thể thêm case "custom" nếu cần
                // case "custom":
                //    // ...
                //    break;

                default: // Reset cho các trường hợp không xác định
                    if (schedule.DaysOfWeek != null) { schedule.DaysOfWeek = null; scheduleChanged = true; }
                    if (schedule.DayOfMonth != 0) { schedule.DayOfMonth = 0; scheduleChanged = true; }
                    if (schedule.FrequencyValue != 1) { schedule.FrequencyValue = 1; scheduleChanged = true; }
                    Console.WriteLine($"Updating schedule for frequency '{dto.Frequency}': Resetting specific days.");
                    break;
            }
             // Chỉ đánh dấu schedule là Modified nếu có thay đổi thực sự HOẶC nếu là schedule mới
             if (scheduleChanged || schedule.Id == 0) {
                 _context.Entry(schedule).State = schedule.Id == 0 ? EntityState.Added : EntityState.Modified;
             }

        }
        // <<< BỎ HOÀN TOÀN LOGIC CẬP NHẬT DaysOfWeek/DaysOfMonth TRỰC TIẾP TRÊN HABIT >>>
        // Khối else (dòng 342-364 cũ) đã bị xóa.

        habit.UpdatedAt = DateTime.UtcNow;

        _context.Entry(habit).State = EntityState.Modified; // Đánh dấu habit đã thay đổi

        try
        {
            var changes = await _context.SaveChangesAsync();
            Console.WriteLine($"Successfully updated habit {id}. {changes} entities saved.");
        }
        catch (DbUpdateConcurrencyException ex)
        {
             Console.WriteLine($"Concurrency error updating habit {id}: {ex.Message}");
            // Xử lý lỗi concurrency nếu cần
             var entry = ex.Entries.Single();
             var databaseValues = await entry.GetDatabaseValuesAsync();
             if (databaseValues == null) {
                 Console.WriteLine("Entity deleted by another user.");
             } else {
                 Console.WriteLine("Entity modified by another user.");
                 // Có thể reload hoặc thông báo lỗi
             }
            return Conflict(new { message = "Dữ liệu đã bị thay đổi bởi người khác. Vui lòng tải lại.", error = ex.Message });
        }
        catch (Exception ex)
        {
             Console.WriteLine($"Error saving changes for habit {id}: {ex.Message}");
             Console.WriteLine($"Stack trace: {ex.StackTrace}");
             return StatusCode(500, new { message = "Lỗi khi lưu thay đổi.", error = ex.Message });
        }

        return NoContent(); // Trả về 204 No Content khi thành công
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
            // QUAN TRỌNG: Include cả schedule và completions để xóa cascaded (nếu có)
            .Include(h => h.HabitSchedule)
            .Include(h => h.CompletionDates) 
            .FirstOrDefaultAsync(h => h.Id == id && h.UserId == userId);

        if (habit == null) return NotFound();

        // Xóa completions trước nếu không có cascade delete
        // _context.HabitCompletions.RemoveRange(habit.CompletionDates); 
        // Xóa schedule trước nếu không có cascade delete
        // if(habit.HabitSchedule != null) _context.HabitSchedules.Remove(habit.HabitSchedule);

        _context.Habits.Remove(habit); // EF Core sẽ tự xóa schedule/completions nếu có cascade delete

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

            Console.WriteLine($"CompleteHabit called for habitId: {id}, userId: {userId}");
            Console.WriteLine($"DTO CompletedAt: {dto.CompletedAt}");
            Console.WriteLine($"DTO Notes: {dto.Notes}");

            var habit = await _context.Habits
                .FirstOrDefaultAsync(h => h.Id == id && h.UserId == userId);

            if (habit == null) return NotFound();

            // Sử dụng UTC cho CompletedAt nếu không có múi giờ cụ thể
            var completedAt = dto.CompletedAt?.ToUniversalTime() ?? DateTime.UtcNow;
            Console.WriteLine($"Final CompletedAt (UTC): {completedAt}");

             // Kiểm tra xem đã hoàn thành trong ngày này chưa (chỉ phần Date)
            bool alreadyCompletedToday = await _context.HabitCompletions
                .AnyAsync(c => c.HabitId == id && c.CompletedAt.Date == completedAt.Date);

            if (alreadyCompletedToday)
            {
                Console.WriteLine($"Habit {id} already completed on {completedAt.Date:yyyy-MM-dd}.");
                // Có thể trả về lỗi hoặc thông báo thành công (tùy yêu cầu)
                return Ok(new { message = $"Thói quen đã được hoàn thành vào ngày {completedAt.Date:yyyy-MM-dd}." });
                // return Conflict(new { message = "Thói quen đã được hoàn thành trong ngày này." }); 
            }

            var completion = new HabitCompletion
            {
                HabitId = id,
                Notes = dto.Notes,
                CompletedAt = completedAt // Lưu giờ UTC
            };

            _context.HabitCompletions.Add(completion);
            await _context.SaveChangesAsync();

            Console.WriteLine($"Successfully completed habit {id} at {completedAt}");
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
            .AnyAsync(h => h.Id == id && h.UserId == userId); // Chỉ cần kiểm tra tồn tại

        if (!habit) return NotFound();

        var query = _context.HabitCompletions
            .Where(c => c.HabitId == id);

        // Chuyển đổi sang UTC nếu cần so sánh chính xác
        if (startDate.HasValue)
        {
            var startUtc = startDate.Value.ToUniversalTime();
            query = query.Where(c => c.CompletedAt >= startUtc);
        }
        if (endDate.HasValue)
        {
             var endUtc = endDate.Value.ToUniversalTime().AddDays(1).AddTicks(-1); // Bao gồm cả ngày kết thúc
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

        // Kiểm tra habit có thuộc về user không
        var habitExists = await _context.Habits
            .AnyAsync(h => h.Id == habitId && h.UserId == userId);

        if (!habitExists) return NotFound("Habit not found");

        // Tìm completion
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