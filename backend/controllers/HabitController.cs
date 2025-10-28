using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using backend.Data;
using backend.Models;
using backend.Models.Dtos;
using System.Security.Claims;

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
            var habits = await _context.Habits
                .Where(h => h.UserId == userId)
                .Include(h => h.Category)
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
                    WeeklyCompletions = weeklyCompletions,
                    MonthlyCompletions = monthlyCompletions,
                    CreatedAt = habit.CreatedAt,
                    CompletionDates = completionDates
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
            WeeklyCompletions = weeklyCompletions,
            MonthlyCompletions = monthlyCompletions,
            CreatedAt = habit.CreatedAt,
            CompletionDates = completionDates
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

        // Xử lý tần suất và các ngày cụ thể
        string? daysOfWeek = null;
        string? daysOfMonth = null;

        switch (dto.Frequency.ToLower())
        {
            case "weekly":
                // Xử lý ngày trong tuần (nếu có)
                if (dto.DaysOfWeek != null && dto.DaysOfWeek.Any())
                {
                    daysOfWeek = System.Text.Json.JsonSerializer.Serialize(dto.DaysOfWeek);
                }
                break;
            case "monthly":
                // Xử lý ngày trong tháng (nếu có)
                if (dto.DaysOfMonth != null && dto.DaysOfMonth.Any())
                {
                    daysOfMonth = System.Text.Json.JsonSerializer.Serialize(dto.DaysOfMonth);
                }
                break;
            case "custom":
                // Đảm bảo có giá trị tần suất tùy chỉnh
                if (!dto.CustomFrequencyValue.HasValue || string.IsNullOrEmpty(dto.CustomFrequencyUnit))
                {
                    return BadRequest("Cần cung cấp giá trị và đơn vị tần suất tùy chỉnh");
                }
                break;
        }

        var habit = new Habit
        {
            Name = dto.Name,
            Description = dto.Description,
            CategoryId = dto.CategoryId,
            UserId = userId,
            StartDate = dto.StartDate,
            EndDate = dto.EndDate,
            Frequency = dto.Frequency,
            DaysOfWeek = daysOfWeek,
            DaysOfMonth = daysOfMonth,
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

        // Load category để trả về response
        await _context.Entry(habit).Reference(h => h.Category).LoadAsync();

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
            CreatedAt = habit.CreatedAt
        };

        return CreatedAtAction(nameof(GetHabit), new { id = habit.Id }, response);
    }

    /// <summary>
    /// Cập nhật thói quen.
    /// </summary>
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateHabit(int id, UpdateHabitDto dto)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var habit = await _context.Habits
            .FirstOrDefaultAsync(h => h.Id == id && h.UserId == userId);

        if (habit == null) return NotFound();

        if (dto.Name != null) habit.Name = dto.Name;
        if (dto.Description != null) habit.Description = dto.Description;
        if (dto.CategoryId.HasValue) habit.CategoryId = dto.CategoryId.Value;
        
        // Xử lý cập nhật tần suất nếu có thay đổi
        if (dto.Frequency != null)
        {
            habit.Frequency = dto.Frequency;
            
            // Xử lý các ngày cụ thể dựa trên tần suất mới
            switch (dto.Frequency.ToLower())
            {
                case "weekly":
                    // Xử lý ngày trong tuần (nếu có)
                    if (dto.DaysOfWeek != null && dto.DaysOfWeek.Any())
                    {
                        habit.DaysOfWeek = System.Text.Json.JsonSerializer.Serialize(dto.DaysOfWeek);
                    }
                    else
                    {
                        habit.DaysOfWeek = null;
                    }
                    // Reset các giá trị không liên quan
                    habit.DaysOfMonth = null;
                    break;
                    
                case "monthly":
                    // Xử lý ngày trong tháng (nếu có)
                    if (dto.DaysOfMonth != null && dto.DaysOfMonth.Any())
                    {
                        habit.DaysOfMonth = System.Text.Json.JsonSerializer.Serialize(dto.DaysOfMonth);
                    }
                    else
                    {
                        habit.DaysOfMonth = null;
                    }
                    // Reset các giá trị không liên quan
                    habit.DaysOfWeek = null;
                    break;
                    
                case "custom":
                    // Đảm bảo có giá trị tần suất tùy chỉnh
                    if (dto.CustomFrequencyValue.HasValue && !string.IsNullOrEmpty(dto.CustomFrequencyUnit))
                    {
                        habit.CustomFrequencyValue = dto.CustomFrequencyValue;
                        habit.CustomFrequencyUnit = dto.CustomFrequencyUnit;
                    }
                    // Reset các giá trị không liên quan
                    habit.DaysOfWeek = null;
                    habit.DaysOfMonth = null;
                    break;
                    
                default: // daily hoặc các loại khác
                    // Reset tất cả các giá trị tần suất đặc biệt
                    habit.DaysOfWeek = null;
                    habit.DaysOfMonth = null;
                    habit.CustomFrequencyValue = null;
                    habit.CustomFrequencyUnit = null;
                    break;
            }
        }
        else
        {
            // Nếu không cập nhật tần suất nhưng có cập nhật các ngày cụ thể
            if (habit.Frequency.ToLower() == "weekly" && dto.DaysOfWeek != null)
            {
                habit.DaysOfWeek = dto.DaysOfWeek.Any() 
                    ? System.Text.Json.JsonSerializer.Serialize(dto.DaysOfWeek) 
                    : null;
            }
            else if (habit.Frequency.ToLower() == "monthly" && dto.DaysOfMonth != null)
            {
                habit.DaysOfMonth = dto.DaysOfMonth.Any() 
                    ? System.Text.Json.JsonSerializer.Serialize(dto.DaysOfMonth) 
                    : null;
            }
            else if (habit.Frequency.ToLower() == "custom")
            {
                if (dto.CustomFrequencyValue.HasValue) 
                    habit.CustomFrequencyValue = dto.CustomFrequencyValue;
                if (!string.IsNullOrEmpty(dto.CustomFrequencyUnit)) 
                    habit.CustomFrequencyUnit = dto.CustomFrequencyUnit;
            }
        }
        if (dto.StartDate.HasValue) habit.StartDate = dto.StartDate.Value;
        if (dto.EndDate.HasValue) habit.EndDate = dto.EndDate.Value;
        if (dto.Frequency != null) habit.Frequency = dto.Frequency;
        if (dto.CustomFrequencyValue.HasValue) habit.CustomFrequencyValue = dto.CustomFrequencyValue.Value;
        if (dto.CustomFrequencyUnit != null) habit.CustomFrequencyUnit = dto.CustomFrequencyUnit;
        if (dto.HasReminder.HasValue) habit.HasReminder = dto.HasReminder.Value;
        if (dto.ReminderTime.HasValue) habit.ReminderTime = dto.ReminderTime.Value;
        if (dto.ReminderType != null) habit.ReminderType = dto.ReminderType;
        if (dto.IsActive.HasValue) habit.IsActive = dto.IsActive.Value;

        habit.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return NoContent();
    }

    /// <summary>
    /// Xóa thói quen.
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteHabit(int id)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var habit = await _context.Habits
            .FirstOrDefaultAsync(h => h.Id == id && h.UserId == userId);

        if (habit == null) return NotFound();

        _context.Habits.Remove(habit);
        await _context.SaveChangesAsync();

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

            var completedAt = dto.CompletedAt ?? DateTime.UtcNow;
            Console.WriteLine($"Final CompletedAt: {completedAt}");

            var completion = new HabitCompletion
            {
                HabitId = id,
                Notes = dto.Notes,
                CompletedAt = completedAt
            };

            _context.HabitCompletions.Add(completion);
            await _context.SaveChangesAsync();

            Console.WriteLine($"Successfully completed habit {id} at {completedAt}");
            return Ok(new { message = "Đã đánh dấu hoàn thành thói quen" });
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
            .FirstOrDefaultAsync(h => h.Id == id && h.UserId == userId);

        if (habit == null) return NotFound();

        var query = _context.HabitCompletions
            .Where(c => c.HabitId == id);

        if (startDate.HasValue)
            query = query.Where(c => c.CompletedAt >= startDate.Value);

        if (endDate.HasValue)
            query = query.Where(c => c.CompletedAt <= endDate.Value);

        var completions = await query
            .OrderByDescending(c => c.CompletedAt)
            .Select(c => new
            {
                Id = c.Id,
                CompletedAt = c.CompletedAt,
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
        var habit = await _context.Habits
            .FirstOrDefaultAsync(h => h.Id == habitId && h.UserId == userId);

        if (habit == null) return NotFound("Habit not found");

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

