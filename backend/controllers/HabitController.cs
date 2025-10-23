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
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var habits = await _context.Habits
            .Where(h => h.UserId == userId)
            .Include(h => h.Category)
            .Select(h => new HabitResponseDto
            {
                Id = h.Id,
                Name = h.Name,
                Description = h.Description,
                Category = new CategoryResponseDto
                {
                    Id = h.Category.Id,
                    Name = h.Category.Name,
                    Color = h.Category.Color,
                    Icon = h.Category.Icon,
                    HabitCount = 0,
                    CreatedAt = h.Category.CreatedAt
                },
                StartDate = h.StartDate,
                EndDate = h.EndDate,
                Frequency = h.Frequency,
                HasReminder = h.HasReminder,
                ReminderTime = h.ReminderTime,
                ReminderType = h.ReminderType,
                IsActive = h.IsActive,
                WeeklyCompletions = _context.HabitCompletions
                    .Count(c => c.HabitId == h.Id && 
                               c.CompletedAt >= DateTime.UtcNow.AddDays(-7)),
                MonthlyCompletions = _context.HabitCompletions
                    .Count(c => c.HabitId == h.Id && 
                               c.CompletedAt >= DateTime.UtcNow.AddDays(-30)),
                CreatedAt = h.CreatedAt
            })
            .ToListAsync();

        return Ok(habits);
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
            .Select(h => new HabitResponseDto
            {
                Id = h.Id,
                Name = h.Name,
                Description = h.Description,
                Category = new CategoryResponseDto
                {
                    Id = h.Category.Id,
                    Name = h.Category.Name,
                    Color = h.Category.Color,
                    Icon = h.Category.Icon,
                    HabitCount = 0,
                    CreatedAt = h.Category.CreatedAt
                },
                StartDate = h.StartDate,
                EndDate = h.EndDate,
                Frequency = h.Frequency,
                HasReminder = h.HasReminder,
                ReminderTime = h.ReminderTime,
                ReminderType = h.ReminderType,
                IsActive = h.IsActive,
                WeeklyCompletions = _context.HabitCompletions
                    .Count(c => c.HabitId == h.Id && 
                               c.CompletedAt >= DateTime.UtcNow.AddDays(-7)),
                MonthlyCompletions = _context.HabitCompletions
                    .Count(c => c.HabitId == h.Id && 
                               c.CompletedAt >= DateTime.UtcNow.AddDays(-30)),
                CreatedAt = h.CreatedAt
            })
            .FirstOrDefaultAsync();

        if (habit == null) return NotFound();

        return Ok(habit);
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

        var habit = new Habit
        {
            Name = dto.Name,
            Description = dto.Description,
            CategoryId = dto.CategoryId,
            UserId = userId,
            StartDate = dto.StartDate,
            EndDate = dto.EndDate,
            Frequency = dto.Frequency,
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
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var habit = await _context.Habits
            .FirstOrDefaultAsync(h => h.Id == id && h.UserId == userId);

        if (habit == null) return NotFound();

        var completion = new HabitCompletion
        {
            HabitId = id,
            Notes = dto.Notes,
            CompletedAt = dto.CompletedAt ?? DateTime.UtcNow
        };

        _context.HabitCompletions.Add(completion);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Đã đánh dấu hoàn thành thói quen" });
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
    /// Lấy ID của người dùng hiện tại từ JWT token.
    /// </summary>
    private string? GetCurrentUserId()
    {
        return User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    }
}

