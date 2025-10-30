using backend.Data;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;

namespace backend.Controllers;

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

    [HttpGet("overview")]
    public async Task<IActionResult> GetOverviewStatistics()
    {
        try
        {
            var userId = _userManager.GetUserId(User);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var habits = await _context.Habits
                .Include(h => h.CompletionDates)
                .Where(h => h.UserId == userId && h.IsActive)
                .ToListAsync();

            Console.WriteLine($"=== STATISTICS DEBUG ===");
            Console.WriteLine($"UserId: {userId}");
            Console.WriteLine($"Total active habits: {habits.Count}");
            
            foreach (var habit in habits)
            {
                Console.WriteLine($"Habit {habit.Id} '{habit.Name}': {habit.CompletionDates.Count} completions");
                foreach (var completion in habit.CompletionDates.Take(5))
                {
                    Console.WriteLine($"  - Completed at: {completion.CompletedAt} (UTC)");
                }
            }

            var totalHabits = habits.Count;
            // FIX CRITICAL: Dùng local time thay vì UTC để tránh timezone issue
            // VN (UTC+7): 31/10 05:59 → UTC: 30/10 22:59 → .Date = 30/10 (SAI!)
            var currentDate = DateTime.Now.Date; // Local time
            var currentMonth = new DateTime(currentDate.Year, currentDate.Month, 1);
            var daysInMonth = DateTime.DaysInMonth(currentDate.Year, currentDate.Month);
            
            Console.WriteLine($"Current Date (LOCAL): {currentDate}");
            Console.WriteLine($"Current Date (UTC): {DateTime.UtcNow.Date}");
            Console.WriteLine($"Current Month Start: {currentMonth}");

            double completionRate = 0.0;
            double totalPossibleCompletionsInMonth = 0.0;
            int totalActualCompletionsInMonth = 0;

            if (totalHabits > 0)
            {

                foreach (var habit in habits)
                {
                    var habitStartDate = habit.StartDate.Date;
                    // FIX CRITICAL: Không giới hạn habitEndDate bởi currentDate
                    // Vì currentDate có thể là hôm qua (timezone issue)
                    var habitEndDate = habit.EndDate?.Date ?? DateTime.MaxValue.Date;

                    var firstDayOfMonth = currentMonth;
                    var lastDayOfMonth = currentMonth.AddMonths(1).AddDays(-1);

                    var periodStart = habitStartDate > firstDayOfMonth ? habitStartDate : firstDayOfMonth;
                    var periodEnd = habitEndDate < lastDayOfMonth ? habitEndDate : lastDayOfMonth;

                    Console.WriteLine($"Habit {habit.Id} '{habit.Name}':");
                    Console.WriteLine($"  StartDate: {habitStartDate}, EndDate: {habitEndDate}");
                    Console.WriteLine($"  Period: {periodStart} -> {periodEnd}");
                    Console.WriteLine($"  Frequency: {habit.Frequency}");

                    if (periodStart <= periodEnd)
                    {
                        // Tính số lần có thể hoàn thành dựa trên tần suất
                        int possibleCompletions = 0;

                        switch (habit.Frequency?.ToLower())
                        {
                            case "daily":
                                possibleCompletions = (periodEnd - periodStart).Days + 1;
                                break;

                            case "weekly":
                                var weeks = 0;
                                var checkDate = periodStart;
                                while (checkDate <= periodEnd)
                                {
                                    if (checkDate.DayOfWeek == habitStartDate.DayOfWeek)
                                        weeks++;
                                    checkDate = checkDate.AddDays(1);
                                }
                                possibleCompletions = weeks;
                                break;

                            case "monthly":
                                var months = 0;
                                var monthCheck = periodStart;
                                while (monthCheck <= periodEnd)
                                {
                                    if (monthCheck.Day == habitStartDate.Day ||
                                        (habitStartDate.Day > DateTime.DaysInMonth(monthCheck.Year, monthCheck.Month)
                                         && monthCheck.Day == DateTime.DaysInMonth(monthCheck.Year, monthCheck.Month)))
                                    {
                                        months++;
                                    }
                                    monthCheck = monthCheck.AddDays(1);
                                }
                                possibleCompletions = months;
                                break;

                            default:
                                possibleCompletions = (periodEnd - periodStart).Days + 1;
                                break;
                        }

                        totalPossibleCompletionsInMonth += possibleCompletions;

                        // FIX: Chỉ đếm completions TRONG period (từ periodStart -> periodEnd)
                        // Không đếm completions trước StartDate hoặc sau EndDate
                        var completionsInMonth = habit.CompletionDates
                            .Count(c => c.CompletedAt.Date >= periodStart && c.CompletedAt.Date <= periodEnd);

                        Console.WriteLine($"  Possible completions: {possibleCompletions}");
                        Console.WriteLine($"  Actual completions in period: {completionsInMonth}");

                        totalActualCompletionsInMonth += completionsInMonth;
                    }
                    else
                    {
                        Console.WriteLine($"  SKIPPED: periodStart > periodEnd");
                    }
                }

                if (totalPossibleCompletionsInMonth > 0)
                {
                    completionRate = (double)totalActualCompletionsInMonth / totalPossibleCompletionsInMonth * 100;
                    completionRate = Math.Min(completionRate, 100.0);
                } else {
                    Console.WriteLine("WARNING: totalPossibleCompletionsInMonth is 0!");
                }
            } else {
                Console.WriteLine("No habits found or totalHabits is 0");
            }

            var currentStreak = CalculateCurrentStreak(habits, currentDate);
            var longestStreak = CalculateLongestStreak(habits);
            
            Console.WriteLine($"Completion Rate: {completionRate:F1}%");
            Console.WriteLine($"Current Streak: {currentStreak}");
            Console.WriteLine($"Longest Streak: {longestStreak}");
            Console.WriteLine($"Total Actual Completions in Month: {totalActualCompletionsInMonth}");
            Console.WriteLine($"Total Possible Completions in Month: {totalPossibleCompletionsInMonth}");
            Console.WriteLine($"=========================");

            // FIX: Convert UTC to Local time trước khi đếm active days
            var activeDaysInMonth = habits
                .SelectMany(h => h.CompletionDates)
                .Select(c => c.CompletedAt.ToLocalTime().Date)
                .Where(d => d >= currentMonth && d <= currentDate)
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

    [HttpGet("heatmap")]
    public async Task<IActionResult> GetHeatmapData([FromQuery] int days = 365)
    {
        try
        {
            var userId = _userManager.GetUserId(User);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            // FIX: Dùng local time để tránh timezone issue
            var endDate = DateTime.Now.Date;
            var startDate = endDate.AddDays(-days + 1);

            var habits = await _context.Habits
                .Include(h => h.CompletionDates)
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
                    Id = habit.Category?.Id ?? 0,
                    Name = habit.Category?.Name ?? "N/A",
                    Color = habit.Category?.Color ?? "#808080",
                    Icon = habit.Category?.Icon ?? "help"
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

    [HttpGet("habit/{habitId}/details")]
    public async Task<IActionResult> GetHabitDetails(int habitId, [FromQuery] int days = 365)
    {
        try
        {
            var userId = _userManager.GetUserId(User);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var habit = await _context.Habits
                .Include(h => h.CompletionDates)
                .Include(h => h.Category)
                .FirstOrDefaultAsync(h => h.Id == habitId && h.UserId == userId);

            if (habit == null)
                return NotFound(new { message = "Không tìm thấy thói quen" });

            // FIX: Dùng local time để tránh timezone issue
            var endDate = DateTime.Now.Date;
            var startDate = endDate.AddDays(-days + 1);

            var completionData = GenerateHeatmapData(habit, startDate, endDate);
            var currentStreak = CalculateHabitCurrentStreak(habit, endDate);
            var longestStreak = CalculateHabitLongestStreak(habit);
            var totalCompletions = habit.CompletionDates.Count;

            var details = new
            {
                HabitId = habit.Id,
                HabitName = habit.Name,
                Description = habit.Description,
                Category = new
                {
                    Id = habit.Category?.Id ?? 0,
                    Name = habit.Category?.Name ?? "N/A",
                    Color = habit.Category?.Color ?? "#808080",
                    Icon = habit.Category?.Icon ?? "help"
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
        // FIX: Convert UTC to Local time trước khi lấy .Date
        var allCompletionDates = habits
            .SelectMany(h => h.CompletionDates)
            .Select(c => c.CompletedAt.ToLocalTime().Date)
            .Distinct()
            .OrderByDescending(d => d)
            .ToList();

        if (!allCompletionDates.Any())
            return 0;

        var streak = 0;
        var checkDate = currentDate;

        if (!allCompletionDates.Contains(checkDate))
            checkDate = checkDate.AddDays(-1);

        while (allCompletionDates.Contains(checkDate))
        {
            streak++;
            checkDate = checkDate.AddDays(-1);
        }

        return streak;
    }

    private int CalculateLongestStreak(List<Habit> habits)
    {
        // FIX: Convert UTC to Local time trước khi lấy .Date
        var allCompletionDates = habits
            .SelectMany(h => h.CompletionDates)
            .Select(c => c.CompletedAt.ToLocalTime().Date)
            .Distinct()
            .OrderBy(d => d)
            .ToList();

        if (!allCompletionDates.Any())
            return 0;

        var longestStreak = 0;
        var currentStreak = 0;

        for (int i = 0; i < allCompletionDates.Count; i++)
        {
            if (i == 0 || allCompletionDates[i] != allCompletionDates[i - 1].AddDays(1))
                currentStreak = 1;
            else
                currentStreak++;

            longestStreak = Math.Max(longestStreak, currentStreak);
        }

        return longestStreak;
    }

    private int CalculateHabitCurrentStreak(Habit habit, DateTime currentDate)
    {
        // FIX: Convert UTC to Local time
        var completionDates = habit.CompletionDates
            .Select(c => c.CompletedAt.ToLocalTime().Date)
            .Distinct()
            .OrderByDescending(d => d)
            .ToList();

        if (!completionDates.Any())
            return 0;

        var streak = 0;
        var checkDate = currentDate;

        if (!completionDates.Contains(checkDate))
            checkDate = checkDate.AddDays(-1);

        while (completionDates.Contains(checkDate))
        {
            streak++;
            checkDate = checkDate.AddDays(-1);
        }

        return streak;
    }

    private int CalculateHabitLongestStreak(Habit habit)
    {
        // FIX: Convert UTC to Local time
        var completionDates = habit.CompletionDates
            .Select(c => c.CompletedAt.ToLocalTime().Date)
            .Distinct()
            .OrderBy(d => d)
            .ToList();

        if (!completionDates.Any())
            return 0;

        var longestStreak = 0;
        var currentStreak = 0;

        for (int i = 0; i < completionDates.Count; i++)
        {
            if (i == 0 || completionDates[i] != completionDates[i - 1].AddDays(1))
                currentStreak = 1;
            else
                currentStreak++;

            longestStreak = Math.Max(longestStreak, currentStreak);
        }

        return longestStreak;
    }

    private List<object> GenerateHeatmapData(Habit habit, DateTime startDate, DateTime endDate)
    {
        // FIX: Convert UTC to Local time cho heatmap
        var completionDates = habit.CompletionDates
            .Select(c => c.CompletedAt.ToLocalTime().Date)
            .Where(d => d >= startDate && d <= endDate)
            .ToHashSet();

        var heatmapData = new List<object>();
        var currentDate = startDate;

        while (currentDate <= endDate)
        {
            if (currentDate >= habit.StartDate.Date &&
                (!habit.EndDate.HasValue || currentDate <= habit.EndDate.Value.Date))
            {
                heatmapData.Add(new
                {
                    Date = currentDate.ToString("yyyy-MM-dd"),
                    IsCompleted = completionDates.Contains(currentDate),
                    Intensity = completionDates.Contains(currentDate) ? 1 : 0
                });
            }

            currentDate = currentDate.AddDays(1);
        }

        return heatmapData;
    }

    #endregion
}
