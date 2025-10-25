using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using backend.Data;
using backend.Models;
using backend.Models.Dtos;

namespace backend.Services
{
    public class HabitScheduleService
    {
        private readonly ApplicationDbContext _context;

        public HabitScheduleService(ApplicationDbContext context)
        {
            _context = context;
        }

        //  Lấy danh sách lịch trình của habit
        public async Task<List<HabitScheduleDto>> GetHabitSchedulesByHabitIdAsync(int habitId)
        {
            var schedules = await _context.HabitSchedules
                .Where(hs => hs.HabitId == habitId)
                .ToListAsync();

            return schedules.Select(ToDto).ToList();
        }

        //  Lấy một lịch trình cụ thể
        public async Task<HabitScheduleDto?> GetHabitScheduleByIdAsync(int id)
        {
            var schedule = await _context.HabitSchedules.FindAsync(id);
            return schedule == null ? null : ToDto(schedule);
        }

        //  Tạo lịch trình mới
        public async Task<HabitScheduleDto?> CreateHabitScheduleAsync(HabitScheduleDto dto)
        {
            var habitExists = await _context.Habits.AnyAsync(h => h.Id == dto.HabitId);
            if (!habitExists) return null; // Không tạo nếu habit không tồn tại

            var schedule = new HabitSchedule
            {
                HabitId = dto.HabitId,
                FrequencyType = dto.FrequencyType,
                FrequencyValue = dto.FrequencyValue,
                DaysOfWeek = dto.DaysOfWeek,
                DayOfMonth = dto.DayOfMonth,
                IsActive = dto.IsActive
            };

            _context.HabitSchedules.Add(schedule);
            await _context.SaveChangesAsync();

            dto.Id = schedule.Id;
            return dto;
        }

        //  Cập nhật lịch trình
        public async Task<bool> UpdateHabitScheduleAsync(int id, HabitScheduleDto dto)
        {
            var schedule = await _context.HabitSchedules.FindAsync(id);
            if (schedule == null) return false;

            schedule.FrequencyType = dto.FrequencyType;
            schedule.FrequencyValue = dto.FrequencyValue;
            schedule.DaysOfWeek = dto.DaysOfWeek;
            schedule.DayOfMonth = dto.DayOfMonth;
            schedule.IsActive = dto.IsActive;

            _context.Entry(schedule).State = EntityState.Modified;
            await _context.SaveChangesAsync();
            return true;
        }

        //  Xóa lịch trình
        public async Task<bool> DeleteHabitScheduleAsync(int id)
        {
            var schedule = await _context.HabitSchedules.FindAsync(id);
            if (schedule == null) return false;

            _context.HabitSchedules.Remove(schedule);
            await _context.SaveChangesAsync();
            return true;
        }

        //  Kiểm tra xem habit có cần thực hiện vào ngày cụ thể không
        public async Task<bool> ShouldHabitBePerformedOnDateAsync(int habitId, DateTime date)
        {
            var schedules = await _context.HabitSchedules
                .Where(hs => hs.HabitId == habitId && hs.IsActive)
                .ToListAsync();

            if (!schedules.Any()) return false;

            var startDate = await _context.Habits
                .Where(h => h.Id == habitId)
                .Select(h => h.StartDate)
                .FirstOrDefaultAsync();

            if (startDate == default) return false;

            foreach (var s in schedules)
            {
                if (IsDateInSchedule(s, date, startDate))
                    return true;
            }
            return false;
        }

        //  Kiểm tra xem ngày có nằm trong lịch trình không
        private static bool IsDateInSchedule(HabitSchedule s, DateTime date, DateTime habitStartDate)
        {
            switch (s.FrequencyType)
            {
                case "Daily":
                    if (s.FrequencyValue <= 0) return false;
                    var diff = (date.Date - habitStartDate.Date).Days;
                    return diff >= 0 && diff % s.FrequencyValue == 0;

                case "Weekly":
                    if (string.IsNullOrEmpty(s.DaysOfWeek)) return false;
                    var dayCode = date.DayOfWeek.ToString().Substring(0, 3);
                    var weekDays = s.DaysOfWeek.Split(',').Select(x => x.Trim());
                    return weekDays.Contains(dayCode);

                case "Monthly":
                    return date.Day == s.DayOfMonth;

                default:
                    return false;
            }
        }

        // Lấy danh sách thói quen cần làm hôm nay
        public async Task<List<HabitResponseDto>> GetHabitsDueTodayAsync(string userId)
        {
            try
            {
                Console.WriteLine($"GetHabitsDueTodayAsync called for userId: {userId}");
                var today = DateTime.UtcNow.Date;
                Console.WriteLine($"Today: {today}");
                
                // Lấy tất cả habits của user
                var habits = await _context.Habits
                    .Where(h => h.UserId == userId && h.IsActive)
                    .Include(h => h.Category)
                    .ToListAsync();

                Console.WriteLine($"Found {habits.Count} active habits for user {userId}");

                var dueTodayHabits = new List<HabitResponseDto>();

                foreach (var habit in habits)
                {
                    Console.WriteLine($"Processing habit: {habit.Name} (Frequency: {habit.Frequency})");
                    
                    // Lấy tất cả schedules của habit này
                    var schedules = await _context.HabitSchedules
                        .Where(s => s.HabitId == habit.Id && s.IsActive)
                        .ToListAsync();

                    Console.WriteLine($"Found {schedules.Count} schedules for habit {habit.Name}");

                    var shouldPerform = false;
                    
                    // Nếu có schedules, kiểm tra theo schedule
                    if (schedules.Any())
                    {
                        foreach (var schedule in schedules)
                        {
                            if (IsDateInSchedule(schedule, today, habit.StartDate))
                            {
                                shouldPerform = true;
                                Console.WriteLine($"Habit {habit.Name} should perform today based on schedule");
                                break;
                            }
                        }
                    }
                    else
                    {
                        // Nếu không có schedules, fallback về logic cũ dựa trên frequency
                        shouldPerform = ShouldHabitBePerformedToday(habit, today);
                        Console.WriteLine($"Habit {habit.Name} fallback check: {shouldPerform}");
                    }

                    if (shouldPerform)
                    {
                        Console.WriteLine($"Adding habit {habit.Name} to due today list");
                        
                        // Tính toán completions một cách an toàn
                        var weeklyCompletions = 0;
                        var monthlyCompletions = 0;
                        
                        List<DateTime> completionDates = new List<DateTime>();
                        try
                        {
                            weeklyCompletions = await _context.HabitCompletions
                                .CountAsync(c => c.HabitId == habit.Id && 
                                           c.CompletedAt >= DateTime.UtcNow.AddDays(-7));
                            monthlyCompletions = await _context.HabitCompletions
                                .CountAsync(c => c.HabitId == habit.Id && 
                                           c.CompletedAt >= DateTime.UtcNow.AddDays(-30));
                            
                            // Get completion dates for this habit
                            completionDates = await _context.HabitCompletions
                                .Where(c => c.HabitId == habit.Id)
                                .Select(c => c.CompletedAt)
                                .OrderBy(d => d)
                                .ToListAsync();
                        }
                        catch
                        {
                            // Nếu có lỗi với completions, set về 0
                            weeklyCompletions = 0;
                            monthlyCompletions = 0;
                            completionDates = new List<DateTime>();
                        }

                        dueTodayHabits.Add(new HabitResponseDto
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
                }

                Console.WriteLine($"Returning {dueTodayHabits.Count} habits due today");
                return dueTodayHabits;
            }
            catch (Exception ex)
            {
                // Log lỗi và trả về danh sách rỗng
                Console.WriteLine($"Error in GetHabitsDueTodayAsync: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                return new List<HabitResponseDto>();
            }
        }

        // Helper method để kiểm tra habit có nên thực hiện hôm nay không (fallback logic)
        private static bool ShouldHabitBePerformedToday(Models.Habit habit, DateTime today)
        {
            // Logic fallback dựa trên frequency cũ
            switch (habit.Frequency.ToLower())
            {
                case "daily":
                    return true; // Mỗi ngày
                case "weekly":
                    // Kiểm tra xem hôm nay có phải ngày trong tuần của habit không
                    return today.DayOfWeek == habit.StartDate.DayOfWeek;
                case "monthly":
                    // Kiểm tra xem hôm nay có phải ngày trong tháng của habit không
                    return today.Day == habit.StartDate.Day;
                default:
                    return true; // Mặc định là daily
            }
        }

        // Helper chuyển Model → DTO
        private static HabitScheduleDto ToDto(HabitSchedule hs)
        {
            return new HabitScheduleDto
            {
                Id = hs.Id,
                HabitId = hs.HabitId,
                FrequencyType = hs.FrequencyType,
                FrequencyValue = hs.FrequencyValue,
                DaysOfWeek = hs.DaysOfWeek,
                DayOfMonth = hs.DayOfMonth,
                IsActive = hs.IsActive
            };
        }
    }
}
