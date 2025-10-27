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
        /// <summary>
        ///  dùng để kiểm tra một ngày cụ thể (ví dụ hôm nay) có nằm trong lịch trình (schedule)
        ///  của một thói quen hay không.
        /// </summary>
        /// <returns></returns>
        private static bool IsDateInSchedule(HabitSchedule s, DateTime date, DateTime habitStartDate)
        {
            switch (s.FrequencyType)
            {
                // Kiểm tra theo ngày
                case "Daily":
                    if (s.FrequencyValue <= 0) return false;
                    var diff = (date.Date - habitStartDate.Date).Days;
                    return diff >= 0 && diff % s.FrequencyValue == 0;

                // Kiểm tra theo tuần
                case "Weekly":
                    if (string.IsNullOrEmpty(s.DaysOfWeek)) return false;

                    // Phương pháp 1: Kiểm tra theo mã ngày (Mon, Tue, ...)
                    try
                    {
                        var dayCode = date.DayOfWeek.ToString().Substring(0, 3); // Lấy mã ngày
                        var weekDays = s.DaysOfWeek.Split(',').Select(x => x.Trim()); // Tách chuỗi thành danh sách
                        var result = weekDays.Contains(dayCode); // Kiểm tra có trong danh sách không
                        Console.WriteLine($"IsDateInSchedule Weekly check (method 1): Today is {dayCode}, selected days are {s.DaysOfWeek}, result = {result}");
                        return result;
                        // Nếu thành công, trả về kết quả
                    }
                    catch (Exception ex)
                    {
                        // Phương pháp 2: Kiểm tra theo số ngày (1-7)
                        try
                        {
                            int dayOfWeek = date.DayOfWeek == DayOfWeek.Sunday ? 7 : (int)date.DayOfWeek; // Chuyển đổi DayOfWeek sang số (Thứ 2 = 1, ..., Chủ nhật = 7)
                            var weekDays = s.DaysOfWeek.Split(',').Select(x => int.Parse(x.Trim())); // Tách chuỗi và chuyển thành số
                            var result = weekDays.Contains(dayOfWeek); // Kiểm tra có trong danh sách không
                            Console.WriteLine($"IsDateInSchedule Weekly check (method 2): Today is day {dayOfWeek}, selected days are {s.DaysOfWeek}, result = {result}");
                            return result;
                        }
                        catch (Exception innerEx)
                        {
                            Console.WriteLine($"Error in IsDateInSchedule Weekly check: {innerEx.Message}");
                            return false;
                        }
                    }

                // Kiểm tra theo tháng
                case "Monthly":
                    try
                    {
                        var result = date.Day == s.DayOfMonth; // Kiểm tra ngày trong tháng
                        Console.WriteLine($"IsDateInSchedule Monthly check: Today is day {date.Day}, selected day is {s.DayOfMonth}, result = {result}");
                        return result;
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Error in IsDateInSchedule Monthly check: {ex.Message}");
                        return false;
                    }

                default:
                    return false;
            }
        }

        // Lấy danh sách thói quen cần làm hôm nay
        public async Task<List<HabitResponseDto>> GetHabitsDueTodayAsync(string userId, DateTime selectedDate) 
        //Nhận vào userId → xác định người dùng.
        {
            try
            {
                Console.WriteLine($"GetHabitsDueTodayAsync called for userId: {userId}");
                var today = selectedDate.Date;
                Console.WriteLine($"Today: {today}");

                // Lấy tất cả habits của user đang hoạt động
                var habits = await _context.Habits
                    .Where(h => h.UserId == userId && h.IsActive)
                    .Include(h => h.Category)
                    .ToListAsync();

                // In thông tin debug
                Console.WriteLine($"Found {habits.Count} active habits for user {userId}");

                var dueTodayHabits = new List<HabitResponseDto>();// Tạo danh sách kết quả các thói quen 
                
                // Duyệt qua từng habit để kiểm tra
                foreach (var habit in habits)
                {
                    Console.WriteLine($"Processing habit: {habit.Name} (Frequency: {habit.Frequency})");
                    
                    // Lấy tất cả schedules của habit này
                    var schedules = await _context.HabitSchedules
                        .Where(s => s.HabitId == habit.Id && s.IsActive)
                        .ToListAsync();

                    Console.WriteLine($"Found {schedules.Count} schedules for habit {habit.Name}");

                    var shouldPerform = false;
                    
                    // Kiểm tra dựa trên frequency và ngày
                    bool checkedByFrequency = false;
                    
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
                    
                    // Nếu không có schedules hoặc không tìm thấy schedule phù hợp, kiểm tra dựa trên frequency
                    if (!shouldPerform)
                    {
                        // Kiểm tra dựa trên frequency và ngày
                        switch (habit.Frequency.ToLower())
                        {
                            case "daily":
                                shouldPerform = true;
                                Console.WriteLine($"Daily habit {habit.Name} should perform today");
                                break;

                            case "weekly":
                                if (!string.IsNullOrEmpty(habit.DaysOfWeek))
                                {
                                    try
                                    {
                                        // Chuyển đổi ngày trong tuần hiện tại sang số (1-7)
                                        int dayOfWeek = today.DayOfWeek == DayOfWeek.Sunday ? 7 : (int)today.DayOfWeek;
                                        Console.WriteLine($"Weekly habit check: Today is day {dayOfWeek} ({today.DayOfWeek}), DaysOfWeek = {habit.DaysOfWeek}");
                                        
                                        // Phương pháp đơn giản: Kiểm tra nếu chuỗi chứa ngày hiện tại
                                        if (habit.DaysOfWeek.Contains(dayOfWeek.ToString()))
                                        {
                                            shouldPerform = true;
                                            Console.WriteLine($"Weekly habit {habit.Name} should perform today (simple check)");
                                        }
                                        else
                                        {
                                            // Thử các phương pháp phức tạp hơn
                                            try
                                            {
                                                var cleaned = habit.DaysOfWeek.Replace("[", "").Replace("]", "").Replace(" ", "");
                                                var weekDays = cleaned.Split(',')
                                                    .Select(x => int.Parse(x))
                                                    .ToList();

                                                shouldPerform = weekDays.Contains(dayOfWeek);
                                                Console.WriteLine($"Weekly habit check (cleaned): shouldPerform = {shouldPerform}");
                                            }
                                            catch (Exception parseEx)
                                            {
                                                Console.WriteLine($"Error parsing DaysOfWeek for habit {habit.Name}: {parseEx.Message}");
                                                shouldPerform = false;
                                            }
                                        }
                                    }
                                    catch (Exception ex)
                                    {
                                        Console.WriteLine($"Error in weekly habit check for habit {habit.Name}: {ex.Message}");
                                        shouldPerform = false;
                                    }
                                }
                                else
                                {
                                    shouldPerform = false;
                                    Console.WriteLine($"Weekly habit {habit.Name} has no DaysOfWeek specified");
                                }
                                break;

                            case "monthly":
                                if (!string.IsNullOrEmpty(habit.DaysOfMonth))
                                {
                                    try
                                    {
                                        Console.WriteLine($"Monthly habit check: Today is day {today.Day}, DaysOfMonth = {habit.DaysOfMonth}");
                                        
                                        // Phương pháp đơn giản: Kiểm tra nếu chuỗi chứa ngày hiện tại
                                        if (habit.DaysOfMonth.Contains(today.Day.ToString()))
                                        {
                                            shouldPerform = true;
                                            Console.WriteLine($"Monthly habit {habit.Name} should perform today (simple check)");
                                        }
                                        else
                                        {
                                            // Thử các phương pháp phức tạp hơn
                                            try
                                            {
                                                var cleaned = habit.DaysOfMonth.Replace("[", "").Replace("]", "").Replace(" ", "");
                                                var monthDays = cleaned.Split(',')
                                                    .Select(x => int.Parse(x))
                                                    .ToList();

                                                shouldPerform = monthDays.Contains(today.Day);
                                                Console.WriteLine($"Monthly habit check (cleaned): shouldPerform = {shouldPerform}");
                                            }
                                            catch (Exception parseEx)
                                            {
                                                Console.WriteLine($"Error parsing DaysOfMonth for habit {habit.Name}: {parseEx.Message}");
                                                // Thử kiểm tra nếu DaysOfMonth chỉ chứa một số
                                                try
                                                {
                                                    int singleDay = int.Parse(habit.DaysOfMonth.Trim());
                                                    shouldPerform = today.Day == singleDay;
                                                    Console.WriteLine($"Monthly habit check (single day): shouldPerform = {shouldPerform}");
                                                }
                                                catch (Exception ex2)
                                                {
                                                    Console.WriteLine($"Final error parsing DaysOfMonth: {ex2.Message}");
                                                    shouldPerform = false;
                                                }
                                            }
                                        }
                                    }
                                    catch (Exception ex)
                                    {
                                        Console.WriteLine($"Error in monthly habit check for habit {habit.Name}: {ex.Message}");
                                        shouldPerform = false;
                                    }
                                }
                                else
                                {
                                    shouldPerform = false;
                                    Console.WriteLine($"Monthly habit {habit.Name} has no DaysOfMonth specified");
                                }
                                break;

                            default:
                                shouldPerform = ShouldHabitBePerformedToday(habit, today);
                                break;
                        }

                        Console.WriteLine($"Habit {habit.Name} (Frequency: {habit.Frequency}) check: {shouldPerform}");
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
            // Kiểm tra ngày bắt đầu và kết thúc
            if (habit.StartDate > today) return false;
            if (habit.EndDate.HasValue && habit.EndDate.Value < today) return false;
            
            // Logic dựa trên frequency và các ngày cụ thể
        switch (habit.Frequency.ToLower())
        {
            case "daily":   
                return true;
                
            case "weekly":
                // Kiểm tra các ngày trong tuần được chọn
                if (!string.IsNullOrEmpty(habit.DaysOfWeek))
                {
                    try
                    {
                        var selectedDays = System.Text.Json.JsonSerializer.Deserialize<List<int>>(habit.DaysOfWeek);
                        // Chuyển đổi DayOfWeek sang số (Thứ 2 = 1, Thứ 3 = 2, ..., Chủ nhật = 7)
                        int dayOfWeekNumber = today.DayOfWeek == DayOfWeek.Sunday ? 7 : (int)today.DayOfWeek;
                        var result = selectedDays != null && selectedDays.Contains(dayOfWeekNumber);
                        
                        // In thông tin debug
                        Console.WriteLine($"ShouldHabitBePerformedToday - Weekly: Today is day {dayOfWeekNumber}, selected days are {habit.DaysOfWeek}, result = {result}");
                        
                        return result;
                    }
                    catch (Exception ex)
                    {
                        // Nếu có lỗi khi parse JSON, thử phương pháp khác
                        Console.WriteLine($"Error parsing DaysOfWeek in ShouldHabitBePerformedToday: {ex.Message}");
                        try {
                            var weekDays = habit.DaysOfWeek.Replace("[", "").Replace("]", "").Split(',').Select(x => int.Parse(x.Trim()));
                            int dayOfWeekNumber = today.DayOfWeek == DayOfWeek.Sunday ? 7 : (int)today.DayOfWeek;
                            var result = weekDays.Contains(dayOfWeekNumber);
                            Console.WriteLine($"Weekly habit check (method 2): Today is day {dayOfWeekNumber}, selected days are {habit.DaysOfWeek}, result = {result}");
                            return result;
                        }
                        catch (Exception innerEx) {
                            Console.WriteLine($"Error in method 2 for habit {habit.Name}: {innerEx.Message}");
                            // Fallback về ngày bắt đầu
                            return today.DayOfWeek == habit.StartDate.DayOfWeek;
                        }
                    }
                }
                // Fallback về ngày bắt đầu nếu không có thông tin cụ thể
                return today.DayOfWeek == habit.StartDate.DayOfWeek;
                
            case "monthly":
                // Kiểm tra các ngày trong tháng được chọn
                if (!string.IsNullOrEmpty(habit.DaysOfMonth))
                {
                    try
                    {
                        var selectedDays = System.Text.Json.JsonSerializer.Deserialize<List<int>>(habit.DaysOfMonth);
                        var result = selectedDays != null && selectedDays.Contains(today.Day);
                        
                        // In thông tin debug
                        Console.WriteLine($"ShouldHabitBePerformedToday - Monthly: Today is day {today.Day}, selected days are {habit.DaysOfMonth}, result = {result}");
                        
                        return result;
                    }
                    catch (Exception ex)
                    {
                        // Nếu có lỗi khi parse JSON, thử phương pháp khác
                        Console.WriteLine($"Error parsing DaysOfMonth in ShouldHabitBePerformedToday: {ex.Message}");
                        try {
                            var monthDays = habit.DaysOfMonth.Replace("[", "").Replace("]", "").Split(',').Select(x => int.Parse(x.Trim()));
                            var result = monthDays.Contains(today.Day);
                            Console.WriteLine($"Monthly habit check (method 2): Today is day {today.Day}, selected days are {habit.DaysOfMonth}, result = {result}");
                            return result;
                        }
                        catch (Exception innerEx) {
                            Console.WriteLine($"Error in method 2 for habit {habit.Name}: {innerEx.Message}");
                            // Fallback về ngày bắt đầu
                            return today.Day == habit.StartDate.Day;
                        }
                    }
                }
                // Fallback về ngày bắt đầu nếu không có thông tin cụ thể
                return today.Day == habit.StartDate.Day;
                
            case "custom":
                // Xử lý tần suất tùy chỉnh
                if (habit.CustomFrequencyValue.HasValue && !string.IsNullOrEmpty(habit.CustomFrequencyUnit))
                {
                    var value = habit.CustomFrequencyValue.Value;
                    var unit = habit.CustomFrequencyUnit.ToLower();
                    
                    if (value <= 0) return false;
                    
                    var diff = (today.Date - habit.StartDate.Date).TotalDays;
                    if (diff < 0) return false;
                    
                    switch (unit)
                    {
                        case "day":
                        case "days":
                            return diff % value == 0;
                            
                        case "week":
                        case "weeks":
                            return diff % (value * 7) == 0;
                            
                        case "month":
                        case "months":
                            // Tính số tháng giữa hai ngày
                            var monthsDiff = (today.Year - habit.StartDate.Year) * 12 + today.Month - habit.StartDate.Month;
                            return monthsDiff % value == 0 && today.Day == habit.StartDate.Day;
                    }
                }
                
                // Mặc định 3 ngày một lần nếu không có thông tin cụ thể
                var frequencyDays = 3;
                var daysDiff = (today.Date - habit.StartDate.Date).Days;
                return daysDiff >= 0 && daysDiff % frequencyDays == 0;
                
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
