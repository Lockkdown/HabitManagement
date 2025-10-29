using backend.Data;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System; // Thêm using System
using System.Collections.Generic; // Thêm using
using System.Linq; // Thêm using
using System.Threading.Tasks; // Thêm using
using Microsoft.Extensions.Logging; // Thêm using ILogger

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
                .Include(h => h.CompletionDates) // <<< SỬA: Completions -> CompletionDates
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
                var totalPossibleCompletionsInMonth = 0.0; // Dùng double để chia chính xác
                var totalActualCompletionsInMonth = 0;

                foreach (var habit in habits)
                {
                    var habitStartDate = habit.StartDate.Date;
                    var habitEndDate = habit.EndDate?.Date ?? currentDate; // Ngày kết thúc hiệu lực là hôm nay nếu null

                    // Chỉ tính những ngày trong tháng hiện tại mà habit còn hiệu lực
                    var firstDayOfMonth = currentMonth;
                    var lastDayOfMonth = currentMonth.AddMonths(1).AddDays(-1);

                    var periodStart = habitStartDate > firstDayOfMonth ? habitStartDate : firstDayOfMonth;
                    var periodEnd = habitEndDate < lastDayOfMonth ? habitEndDate : lastDayOfMonth;

                    if (periodStart <= periodEnd)
                    {
                         // Đếm số ngày habit cần thực hiện trong khoảng thời gian này của tháng
                         // (Logic này cần được cải thiện để chính xác với weekly/monthly)
                         // Tạm tính dựa trên số ngày cho đơn giản
                         var daysActiveInMonth = (periodEnd - periodStart).Days + 1;
                         totalPossibleCompletionsInMonth += daysActiveInMonth; // Tạm cộng dồn số ngày

                         // Đếm số lần hoàn thành thực tế trong tháng
                         var completionsInMonth = habit.CompletionDates // <<< SỬA: Completions -> CompletionDates
                             .Count(c => c.CompletedAt.Date >= firstDayOfMonth && c.CompletedAt.Date <= lastDayOfMonth);
                         totalActualCompletionsInMonth += completionsInMonth;
                    }
                }

                if (totalPossibleCompletionsInMonth > 0)
                {
                    completionRate = (double)totalActualCompletionsInMonth / totalPossibleCompletionsInMonth * 100;
                }
            }

            // Tính streak hiện tại và dài nhất (dựa trên tất cả habit)
            var currentStreak = CalculateCurrentStreak(habits, currentDate);
            var longestStreak = CalculateLongestStreak(habits);

            // Tính số ngày hoạt động trong tháng (có ít nhất 1 habit hoàn thành)
            var activeDaysInMonth = habits
                .SelectMany(h => h.CompletionDates) // <<< SỬA: Completions -> CompletionDates
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
                .Include(h => h.CompletionDates) // <<< SỬA: Completions -> CompletionDates
                .Include(h => h.Category)
                .Where(h => h.UserId == userId && h.IsActive)
                .ToListAsync();

            var heatmapData = habits.Select(habit => new
            {
                HabitId = habit.Id,
                HabitName = habit.Name,
                Description = habit.Description,
                Category = new // Kiểm tra null cho Category
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
                .Include(h => h.CompletionDates) // <<< SỬA: Completions -> CompletionDates
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
            var totalCompletions = habit.CompletionDates.Count; // <<< SỬA: Completions -> CompletionDates

            var details = new
            {
                HabitId = habit.Id,
                HabitName = habit.Name,
                Description = habit.Description,
                Category = new // Kiểm tra null cho Category
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

    // Helper tính streak hiện tại (dựa trên tất cả habit)
    private int CalculateCurrentStreak(List<Habit> habits, DateTime currentDate)
    {
        var allCompletionDates = habits
            .SelectMany(h => h.CompletionDates) // <<< SỬA: Completions -> CompletionDates
            .Select(c => c.CompletedAt.Date)
            .Distinct()
            .OrderByDescending(d => d)
            .ToList();

        if (!allCompletionDates.Any())
            return 0;

        var streak = 0;
        var checkDate = currentDate;

        // Bỏ qua ngày hôm nay nếu chưa hoàn thành habit nào
        if (!allCompletionDates.Contains(checkDate)) {
             checkDate = checkDate.AddDays(-1); // Bắt đầu kiểm tra từ hôm qua
        }

        while (allCompletionDates.Contains(checkDate))
        {
            streak++;
            checkDate = checkDate.AddDays(-1);
        }

        return streak;
    }

    // Helper tính streak dài nhất (dựa trên tất cả habit)
    private int CalculateLongestStreak(List<Habit> habits)
    {
        var allCompletionDates = habits
            .SelectMany(h => h.CompletionDates) // <<< SỬA: Completions -> CompletionDates
            .Select(c => c.CompletedAt.Date)
            .Distinct()
            .OrderBy(d => d)
            .ToList();

        if (!allCompletionDates.Any())
            return 0;

        var longestStreak = 0;
        var currentStreak = 0; // Khởi tạo là 0

        for (int i = 0; i < allCompletionDates.Count; i++)
        {
             // Bắt đầu streak mới hoặc ngày đầu tiên
            if (i == 0 || allCompletionDates[i] != allCompletionDates[i - 1].AddDays(1))
            {
                 currentStreak = 1;
            }
             // Tiếp tục streak
            else
            {
                currentStreak++;
            }
             longestStreak = Math.Max(longestStreak, currentStreak);
        }

        return longestStreak;
    }

     // Helper tính streak hiện tại cho 1 habit
    private int CalculateHabitCurrentStreak(Habit habit, DateTime currentDate)
    {
        var completionDates = habit.CompletionDates // <<< SỬA: Completions -> CompletionDates
            .Select(c => c.CompletedAt.Date)
            .Distinct()
            .OrderByDescending(d => d)
            .ToList();

        if (!completionDates.Any())
            return 0;

        var streak = 0;
        var checkDate = currentDate;

         // Bỏ qua ngày hôm nay nếu chưa hoàn thành
        if (!completionDates.Contains(checkDate)) {
             checkDate = checkDate.AddDays(-1);
        }


        while (completionDates.Contains(checkDate))
        {
            streak++;
            checkDate = checkDate.AddDays(-1);
        }

        return streak;
    }

    // Helper tính streak dài nhất cho 1 habit
    private int CalculateHabitLongestStreak(Habit habit)
    {
        var completionDates = habit.CompletionDates // <<< SỬA: Completions -> CompletionDates
            .Select(c => c.CompletedAt.Date)
            .Distinct()
            .OrderBy(d => d)
            .ToList();

        if (!completionDates.Any())
            return 0;

        var longestStreak = 0;
        var currentStreak = 0; // Khởi tạo là 0

        for (int i = 0; i < completionDates.Count; i++)
        {
             if (i == 0 || completionDates[i] != completionDates[i - 1].AddDays(1))
            {
                 currentStreak = 1;
            }
            else
            {
                currentStreak++;
            }
             longestStreak = Math.Max(longestStreak, currentStreak);
        }

        return longestStreak;
    }

     // Helper tạo dữ liệu heatmap cho 1 habit
    private List<object> GenerateHeatmapData(Habit habit, DateTime startDate, DateTime endDate)
    {
        // Lấy ngày hoàn thành trong khoảng thời gian yêu cầu
        var completionDates = habit.CompletionDates // <<< SỬA: Completions -> CompletionDates
             .Where(c => c.CompletedAt.Date >= startDate && c.CompletedAt.Date <= endDate)
            .Select(c => c.CompletedAt.Date)
            .ToHashSet(); // Dùng HashSet để kiểm tra nhanh

        var heatmapData = new List<object>();
        var currentDate = startDate;

        while (currentDate <= endDate)
        {
             // Chỉ thêm dữ liệu nếu ngày này >= ngày bắt đầu của habit
             if (currentDate >= habit.StartDate.Date && (!habit.EndDate.HasValue || currentDate <= habit.EndDate.Value.Date))
             {
                 heatmapData.Add(new
                 {
                     Date = currentDate.ToString("yyyy-MM-dd"),
                     IsCompleted = completionDates.Contains(currentDate),
                     // Intensity có thể phức tạp hơn nếu bạn muốn thể hiện mức độ hoàn thành
                     Intensity = completionDates.Contains(currentDate) ? 1 : 0
                 });
             }

            currentDate = currentDate.AddDays(1);
        }

        return heatmapData;
    }

    #endregion
}