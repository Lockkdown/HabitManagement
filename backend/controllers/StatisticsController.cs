using backend.Data;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers;

/// <summary>
/// Controller xử lý các API endpoints liên quan đến thống kê thói quen.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class StatisticsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<User> _userManager;
    private readonly ILogger<StatisticsController> _logger;

    public StatisticsController(
        ApplicationDbContext context,
        UserManager<User> userManager,
        ILogger<StatisticsController> logger)
    {
        _context = context;
        _userManager = userManager;
        _logger = logger;
    }

    /// <summary>
    /// Lấy thống kê tổng quan của người dùng
    /// </summary>
    [HttpGet("overview")]
    public async Task<IActionResult> GetOverviewStatistics()
    {
        try
        {
            var userId = _userManager.GetUserId(User);
            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized();
            }

            var habits = await _context.Habits
                .Include(h => h.Completions)
                .Where(h => h.UserId == userId && h.IsActive)
                .ToListAsync();

            var totalHabits = habits.Count;
            var currentDate = DateTime.UtcNow.Date;
            var currentMonth = new DateTime(currentDate.Year, currentDate.Month, 1);
            var daysInMonth = DateTime.DaysInMonth(currentDate.Year, currentDate.Month);

            // Tính % hoàn thành trung bình trong tháng hiện tại
            var completionRate = 0.0;
            if (totalHabits > 0)
            {
                var totalPossibleCompletions = 0;
                var totalActualCompletions = 0;

                foreach (var habit in habits)
                {
                    var habitStartDate = habit.StartDate.Date;
                    var habitEndDate = habit.EndDate?.Date ?? currentDate;
                    
                    // Tính số ngày có thể hoàn thành trong tháng
                    var startOfPeriod = habitStartDate > currentMonth ? habitStartDate : currentMonth;
                    var endOfPeriod = habitEndDate < currentDate ? habitEndDate : currentDate;
                    
                    if (startOfPeriod <= endOfPeriod)
                    {
                        var daysInPeriod = (endOfPeriod - startOfPeriod).Days + 1;
                        totalPossibleCompletions += daysInPeriod;
                        
                        // Đếm số ngày thực tế hoàn thành
                        var completionsInMonth = habit.Completions
                            .Where(c => c.CompletedAt.Date >= currentMonth && c.CompletedAt.Date <= currentDate)
                            .Count();
                        totalActualCompletions += completionsInMonth;
                    }
                }

                if (totalPossibleCompletions > 0)
                {
                    completionRate = (double)totalActualCompletions / totalPossibleCompletions * 100;
                }
            }

            // Tính streak hiện tại và dài nhất
            var currentStreak = CalculateCurrentStreak(habits, currentDate);
            var longestStreak = CalculateLongestStreak(habits);

            // Tính số ngày hoạt động trong tháng
            var activeDaysInMonth = habits
                .SelectMany(h => h.Completions)
                .Where(c => c.CompletedAt.Date >= currentMonth && c.CompletedAt.Date <= currentDate)
                .Select(c => c.CompletedAt.Date)
                .Distinct()
                .Count();

            var statistics = new
            {
                CompletionRate = Math.Round(completionRate, 1),
                CurrentStreak = currentStreak,
                LongestStreak = longestStreak,
                TotalHabits = totalHabits,
                ActiveDaysInMonth = activeDaysInMonth,
                DaysInMonth = daysInMonth
            };

            return Ok(statistics);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi lấy thống kê tổng quan");
            return StatusCode(500, new { message = "Lỗi server khi lấy thống kê" });
        }
    }

    /// <summary>
    /// Lấy dữ liệu heatmap cho tất cả thói quen
    /// </summary>
    [HttpGet("heatmap")]
    public async Task<IActionResult> GetHeatmapData([FromQuery] int days = 365)
    {
        try
        {
            var userId = _userManager.GetUserId(User);
            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized();
            }

            var endDate = DateTime.UtcNow.Date;
            var startDate = endDate.AddDays(-days + 1);

            var habits = await _context.Habits
                .Include(h => h.Completions)
                .Include(h => h.Category)
                .Where(h => h.UserId == userId && h.IsActive)
                .ToListAsync();

            var heatmapData = habits.Select(habit => new
            {
                HabitId = habit.Id,
                HabitName = habit.Name,
                Description = habit.Description,
                Category = new
                {
                    habit.Category.Id,
                    habit.Category.Name,
                    habit.Category.Color,
                    habit.Category.Icon
                },
                CompletionData = GenerateHeatmapData(habit, startDate, endDate)
            }).ToList();

            return Ok(heatmapData);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi lấy dữ liệu heatmap");
            return StatusCode(500, new { message = "Lỗi server khi lấy dữ liệu heatmap" });
        }
    }

    /// <summary>
    /// Lấy dữ liệu chi tiết cho một thói quen cụ thể
    /// </summary>
    [HttpGet("habit/{habitId}/details")]
    public async Task<IActionResult> GetHabitDetails(int habitId, [FromQuery] int days = 365)
    {
        try
        {
            var userId = _userManager.GetUserId(User);
            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized();
            }

            var habit = await _context.Habits
                .Include(h => h.Completions)
                .Include(h => h.Category)
                .FirstOrDefaultAsync(h => h.Id == habitId && h.UserId == userId);

            if (habit == null)
            {
                return NotFound(new { message = "Không tìm thấy thói quen" });
            }

            var endDate = DateTime.UtcNow.Date;
            var startDate = endDate.AddDays(-days + 1);

            var completionData = GenerateHeatmapData(habit, startDate, endDate);
            var currentStreak = CalculateHabitCurrentStreak(habit, endDate);
            var longestStreak = CalculateHabitLongestStreak(habit);
            var totalCompletions = habit.Completions.Count;

            var details = new
            {
                HabitId = habit.Id,
                HabitName = habit.Name,
                Description = habit.Description,
                Category = new
                {
                    habit.Category.Id,
                    habit.Category.Name,
                    habit.Category.Color,
                    habit.Category.Icon
                },
                CurrentStreak = currentStreak,
                LongestStreak = longestStreak,
                TotalCompletions = totalCompletions,
                CompletionData = completionData
            };

            return Ok(details);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi lấy chi tiết thói quen {HabitId}", habitId);
            return StatusCode(500, new { message = "Lỗi server khi lấy chi tiết thói quen" });
        }
    }

    #region Private Helper Methods

    private int CalculateCurrentStreak(List<Habit> habits, DateTime currentDate)
    {
        var allCompletionDates = habits
            .SelectMany(h => h.Completions)
            .Select(c => c.CompletedAt.Date)
            .Distinct()
            .OrderByDescending(d => d)
            .ToList();

        if (!allCompletionDates.Any())
            return 0;

        var streak = 0;
        var checkDate = currentDate;

        // Kiểm tra từ hôm nay trở về trước
        while (allCompletionDates.Contains(checkDate))
        {
            streak++;
            checkDate = checkDate.AddDays(-1);
        }

        return streak;
    }

    private int CalculateLongestStreak(List<Habit> habits)
    {
        var allCompletionDates = habits
            .SelectMany(h => h.Completions)
            .Select(c => c.CompletedAt.Date)
            .Distinct()
            .OrderBy(d => d)
            .ToList();

        if (!allCompletionDates.Any())
            return 0;

        var longestStreak = 0;
        var currentStreak = 1;

        for (int i = 1; i < allCompletionDates.Count; i++)
        {
            if (allCompletionDates[i] == allCompletionDates[i - 1].AddDays(1))
            {
                currentStreak++;
            }
            else
            {
                longestStreak = Math.Max(longestStreak, currentStreak);
                currentStreak = 1;
            }
        }

        return Math.Max(longestStreak, currentStreak);
    }

    private int CalculateHabitCurrentStreak(Habit habit, DateTime currentDate)
    {
        var completionDates = habit.Completions
            .Select(c => c.CompletedAt.Date)
            .Distinct()
            .OrderByDescending(d => d)
            .ToList();

        if (!completionDates.Any())
            return 0;

        var streak = 0;
        var checkDate = currentDate;

        while (completionDates.Contains(checkDate))
        {
            streak++;
            checkDate = checkDate.AddDays(-1);
        }

        return streak;
    }

    private int CalculateHabitLongestStreak(Habit habit)
    {
        var completionDates = habit.Completions
            .Select(c => c.CompletedAt.Date)
            .Distinct()
            .OrderBy(d => d)
            .ToList();

        if (!completionDates.Any())
            return 0;

        var longestStreak = 0;
        var currentStreak = 1;

        for (int i = 1; i < completionDates.Count; i++)
        {
            if (completionDates[i] == completionDates[i - 1].AddDays(1))
            {
                currentStreak++;
            }
            else
            {
                longestStreak = Math.Max(longestStreak, currentStreak);
                currentStreak = 1;
            }
        }

        return Math.Max(longestStreak, currentStreak);
    }

    private List<object> GenerateHeatmapData(Habit habit, DateTime startDate, DateTime endDate)
    {
        var completionDates = habit.Completions
            .Select(c => c.CompletedAt.Date)
            .ToHashSet();

        var heatmapData = new List<object>();
        var currentDate = startDate;

        while (currentDate <= endDate)
        {
            heatmapData.Add(new
            {
                Date = currentDate.ToString("yyyy-MM-dd"),
                IsCompleted = completionDates.Contains(currentDate),
                Intensity = completionDates.Contains(currentDate) ? 1 : 0
            });

            currentDate = currentDate.AddDays(1);
        }

        return heatmapData;
    }

    #endregion
}