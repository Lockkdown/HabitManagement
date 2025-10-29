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

        //  Lấy danh sách lịch trình của habit
        public async Task<List<HabitScheduleDto>> GetHabitSchedulesByHabitIdAsync(int habitId)
        {
            var schedules = await _context.HabitSchedules
                .Where(hs => hs.HabitId == habitId)
                .ToListAsync();

            return schedules.Select(ToDto).ToList();
        }

        //  Lấy một lịch trình cụ thể
        public async Task<HabitScheduleDto?> GetHabitScheduleByIdAsync(int id)
        {
            var schedule = await _context.HabitSchedules.FindAsync(id);
            return schedule == null ? null : ToDto(schedule);
        }

        //  Tạo lịch trình mới
        public async Task<HabitScheduleDto?> CreateHabitScheduleAsync(HabitScheduleDto dto)
        {
            var habitExists = await _context.Habits.AnyAsync(h => h.Id == dto.HabitId);
            if (!habitExists) return null; // Không tạo nếu habit không tồn tại

            var schedule = new HabitSchedule
            {
                HabitId = dto.HabitId,
                FrequencyType = dto.FrequencyType, // Giả sử DTO gửi đúng chữ hoa/thường
                FrequencyValue = dto.FrequencyValue,
                DaysOfWeek = dto.DaysOfWeek,
                DayOfMonth = dto.DayOfMonth,
                IsActive = dto.IsActive
            };

            _context.HabitSchedules.Add(schedule);
            await _context.SaveChangesAsync();

            dto.Id = schedule.Id; // Gán lại Id vừa được tạo
            return dto;
        }

        //  Cập nhật lịch trình
        public async Task<bool> UpdateHabitScheduleAsync(int id, HabitScheduleDto dto)
        {
            var schedule = await _context.HabitSchedules.FindAsync(id);
            if (schedule == null) return false;

            schedule.FrequencyType = dto.FrequencyType; // Giả sử DTO gửi đúng chữ hoa/thường
            schedule.FrequencyValue = dto.FrequencyValue;
            schedule.DaysOfWeek = dto.DaysOfWeek;
            schedule.DayOfMonth = dto.DayOfMonth;
            schedule.IsActive = dto.IsActive;

            _context.Entry(schedule).State = EntityState.Modified;
            await _context.SaveChangesAsync();
            return true;
        }

        //  Xóa lịch trình
        public async Task<bool> DeleteHabitScheduleAsync(int id)
        {
            var schedule = await _context.HabitSchedules.FindAsync(id);
            if (schedule == null) return false;

            _context.HabitSchedules.Remove(schedule);
            await _context.SaveChangesAsync();
            return true;
        }

        //  Kiểm tra xem habit có cần thực hiện vào ngày cụ thể không
        public async Task<bool> ShouldHabitBePerformedOnDateAsync(int habitId, DateTime date)
        {
             var habit = await _context.Habits
                .Include(h => h.HabitSchedule) // Include schedule
                .FirstOrDefaultAsync(h => h.Id == habitId);

            if (habit == null || !habit.IsActive) return false;

            // Kiểm tra ngày bắt đầu/kết thúc
            if (habit.StartDate.Date > date.Date) return false; // So sánh Date
            if (habit.EndDate.HasValue && habit.EndDate.Value.Date < date.Date) return false; // So sánh Date

            // Ưu tiên kiểm tra schedule
            if (habit.HabitSchedule != null)
            {
                 return IsDateInSchedule(habit.HabitSchedule, date.Date, habit.StartDate.Date);
            }
             // Nếu không có schedule, chỉ trả về true nếu là daily
            else if (habit.Frequency.Equals("daily", StringComparison.OrdinalIgnoreCase))
            {
                 return true;
            }

            return false;
        }


        // ==========================================================
        // <<< BẮT ĐẦU CODE ĐÃ SỬA >>>
        // ==========================================================

        //  Kiểm tra xem ngày có nằm trong lịch trình không
        /// <summary>
        ///  dùng để kiểm tra một ngày cụ thể có nằm trong lịch trình (schedule)
        ///  của một thói quen hay không.
        /// </summary>
        /// <returns></returns>
        private static bool IsDateInSchedule(HabitSchedule s, DateTime date, DateTime habitStartDate)
        {
            // Thêm kiểm tra: Chỉ kiểm tra nếu ngày hiện tại >= ngày bắt đầu của thói quen
            if (date.Date < habitStartDate.Date)
            {
                Console.WriteLine($"      -> IsDateInSchedule: Date {date:yyyy-MM-dd} is before habit start date {habitStartDate:yyyy-MM-dd}. Result: false");
                return false;
            }
            // Thêm kiểm tra: Nếu schedule không active thì bỏ qua
            if (!s.IsActive)
            {
                Console.WriteLine($"      -> IsDateInSchedule: Schedule {s.Id} is not active. Result: false");
                return false;
            }

            // Chuyển FrequencyType thành chữ hoa chữ cái đầu để so sánh nhất quán
            string frequencyTypeUpper = string.IsNullOrEmpty(s.FrequencyType) ? "" :
                char.ToUpperInvariant(s.FrequencyType[0]) + s.FrequencyType.Substring(1).ToLowerInvariant();

            switch (frequencyTypeUpper) // Dùng biến đã chuẩn hóa
            {
                case "Daily":
                    if (s.FrequencyValue <= 0) {
                        Console.WriteLine($"      -> IsDateInSchedule Daily: Invalid FrequencyValue ({s.FrequencyValue}). Result: false");
                        return false;
                    }
                    var diff = (date.Date - habitStartDate.Date).Days;
                    bool dailyResult = diff >= 0 && diff % s.FrequencyValue == 0;
                    Console.WriteLine($"      -> IsDateInSchedule Daily: Date={date:yyyy-MM-dd}, Start={habitStartDate:yyyy-MM-dd}, Diff={diff}, FreqValue={s.FrequencyValue}, Result={dailyResult}");
                    return dailyResult;

                case "Weekly": // <<< SỬA LOGIC CASE NÀY >>>
                    if (string.IsNullOrEmpty(s.DaysOfWeek)) {
                        Console.WriteLine($"      -> IsDateInSchedule Weekly: DaysOfWeek is null or empty. Result: false");
                        return false;
                    }

                    try
                    {
                        // Lấy DayOfWeek enum của ngày cần kiểm tra (Sunday = 0, Monday = 1, ..., Saturday = 6)
                        DayOfWeek currentDayOfWeek = date.DayOfWeek;
                        // Log giá trị DayOfWeek gốc
                        Console.WriteLine($"      -> IsDateInSchedule Weekly: Checking date {date:yyyy-MM-dd}, DayOfWeek Enum = {currentDayOfWeek} ({(int)currentDayOfWeek})");


                        // Tách chuỗi từ database ("Mon,Wed,Fri")
                        var scheduledDayStrings = s.DaysOfWeek.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                                                     .Select(x => x.Trim().ToLowerInvariant()); // Chuyển thành chữ thường để so sánh

                        // Tạo một Dictionary để map chuỗi sang DayOfWeek enum
                        var dayMap = new Dictionary<string, DayOfWeek>(StringComparer.OrdinalIgnoreCase) // Thêm IgnoreCase cho Key
                        {
                            { "sun", DayOfWeek.Sunday },
                            { "mon", DayOfWeek.Monday },
                            { "tue", DayOfWeek.Tuesday },
                            { "wed", DayOfWeek.Wednesday },
                            { "thu", DayOfWeek.Thursday },
                            { "fri", DayOfWeek.Friday },
                            { "sat", DayOfWeek.Saturday }
                        };

                        bool shouldPerform = false;
                        foreach (var dayStr in scheduledDayStrings)
                        {
                            // Kiểm tra xem chuỗi ngày từ DB có trong map không và có khớp với ngày hiện tại không
                             Console.WriteLine($"        -> Comparing schedule day string '{dayStr}'...");
                            if (dayMap.TryGetValue(dayStr, out DayOfWeek scheduledDayEnum)) // Dùng TryGetValue an toàn hơn
                            {
                                 Console.WriteLine($"          -> Mapped '{dayStr}' to Enum: {scheduledDayEnum}");
                                if (scheduledDayEnum == currentDayOfWeek)
                                {
                                    shouldPerform = true;
                                     Console.WriteLine($"          -> MATCH FOUND!");
                                    break; // Tìm thấy khớp, không cần kiểm tra nữa
                                }
                            } else {
                                 Console.WriteLine($"          -> Could not map '{dayStr}' to a DayOfWeek Enum.");
                            }
                        }

                        Console.WriteLine($"      -> IsDateInSchedule Weekly: Final check result for '{s.DaysOfWeek}' on {currentDayOfWeek}: ShouldPerform={shouldPerform}");
                        return shouldPerform;
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"      -> Error processing DaysOfWeek ('{s.DaysOfWeek}') in IsDateInSchedule: {ex.Message}. Result: false");
                        return false; // Lỗi thì coi như không khớp
                    }
                    // <<< KẾT THÚC SỬA LOGIC CASE NÀY >>>

                case "Monthly":
                    try
                    {
                        bool monthlyResult = date.Day == s.DayOfMonth;
                        Console.WriteLine($"      -> IsDateInSchedule Monthly: Today is day {date.Day}, schedule day is {s.DayOfMonth}, Result={monthlyResult}");
                        return monthlyResult;
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"      -> Error checking DayOfMonth ({s.DayOfMonth}) in IsDateInSchedule: {ex.Message}. Result: false");
                        return false;
                    }

                default:
                    Console.WriteLine($"      -> IsDateInSchedule: Unknown FrequencyType. Original: '{s.FrequencyType}', Normalized: '{frequencyTypeUpper}' for schedule Id {s.Id}. Result: false");
                    return false;
            }
        }


        // Lấy danh sách thói quen cần làm hôm nay
        public async Task<List<HabitResponseDto>> GetHabitsDueTodayAsync(string userId, DateTime selectedDate)
        {
            try
            {
                Console.WriteLine($"GetHabitsDueTodayAsync called for userId: {userId}, selectedDate: {selectedDate:yyyy-MM-dd}");
                var today = selectedDate.Date; // Chỉ lấy phần ngày

                // Lấy tất cả habits của user đang hoạt động VÀ BAO GỒM HabitSchedule, Category, Completions
                var habits = await _context.Habits
                    .Where(h => h.UserId == userId && h.IsActive)
                    .Include(h => h.Category)      // Include Category để map DTO
                    .Include(h => h.HabitSchedule) // <<< QUAN TRỌNG: Include HabitSchedule
                    .Include(h => h.CompletionDates) // Include completions để gửi về client
                    .ToListAsync();

                Console.WriteLine($"Found {habits.Count} active habits for user {userId}");

                var dueTodayHabits = new List<HabitResponseDto>();

                foreach (var habit in habits)
                {
                    Console.WriteLine($"  Processing habit: {habit.Id} - {habit.Name}");

                    // Kiểm tra ngày bắt đầu và kết thúc chung của Habit
                    if (habit.StartDate.Date > today) { // So sánh Date
                        Console.WriteLine($"    -> Skipping: StartDate ({habit.StartDate:yyyy-MM-dd}) is after today.");
                        continue;
                    }
                    if (habit.EndDate.HasValue && habit.EndDate.Value.Date < today) { // So sánh Date
                        Console.WriteLine($"    -> Skipping: EndDate ({habit.EndDate.Value:yyyy-MM-dd}) is before today.");
                        continue;
                    }

                    bool shouldPerform = false;
                    // Ưu tiên kiểm tra bằng HabitSchedule nếu có
                    if (habit.HabitSchedule != null)
                    {
                        Console.WriteLine($"    -> Checking HabitSchedule (Id: {habit.HabitSchedule.Id}, Type: {habit.HabitSchedule.FrequencyType})");
                        if (IsDateInSchedule(habit.HabitSchedule, today, habit.StartDate))
                        {
                            shouldPerform = true;
                            Console.WriteLine($"    -> DUE today based on HabitSchedule.");
                        }
                        else {
                            Console.WriteLine($"    -> NOT due today based on HabitSchedule.");
                        }
                    }
                    else // Nếu không có HabitSchedule, thử kiểm tra bằng Frequency gốc (chỉ hỗ trợ daily)
                    {
                        Console.WriteLine($"    -> No HabitSchedule found. Checking base Frequency ('{habit.Frequency}').");
                        // Chỉ thêm nếu Frequency gốc là daily VÀ ngày hiện tại >= ngày bắt đầu
                        if (habit.Frequency.Equals("daily", StringComparison.OrdinalIgnoreCase) && today >= habit.StartDate.Date) {
                            shouldPerform = true;
                            Console.WriteLine($"    -> DUE today (Daily habit without schedule).");
                        } else {
                            Console.WriteLine($"    -> Non-daily habit without schedule OR before start date - Skipping.");
                        }
                    }

                    // Nếu habit cần thực hiện hôm nay, thêm vào danh sách kết quả
                    if(shouldPerform)
                    {
                        Console.WriteLine($"    -> Adding habit '{habit.Name}' to due today list.");
                        dueTodayHabits.Add(MapToHabitResponseDto(habit)); // Dùng hàm Map helper
                    }
                }

                Console.WriteLine($"Returning {dueTodayHabits.Count} habits due today for user {userId}");
                return dueTodayHabits;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error in GetHabitsDueTodayAsync for userId {userId}: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                return new List<HabitResponseDto>(); // Trả về rỗng để tránh crash client
            }
        }

        // === HÀM MAP HELPER ===
        private HabitResponseDto MapToHabitResponseDto(Habit habit)
        {
            // Tính toán completions (đã include CompletionDates)
            var nowUtc = DateTime.UtcNow;
            var startOfWeekUtc = nowUtc.Date.AddDays(-(int)nowUtc.DayOfWeek + (int)DayOfWeek.Monday);
            if (nowUtc.DayOfWeek == DayOfWeek.Sunday) startOfWeekUtc = startOfWeekUtc.AddDays(-7);
            var startOfMonthUtc = new DateTime(nowUtc.Year, nowUtc.Month, 1);

            var weeklyCompletions = habit.CompletionDates?.Count(c => c.CompletedAt >= startOfWeekUtc) ?? 0;
            var monthlyCompletions = habit.CompletionDates?.Count(c => c.CompletedAt >= startOfMonthUtc) ?? 0;

            return new HabitResponseDto
            {
                Id = habit.Id,
                Name = habit.Name,
                Description = habit.Description,
                 Category = habit.Category == null ? null : new CategoryResponseDto {
                    Id = habit.Category.Id,
                    Name = habit.Category.Name,
                    Color = habit.Category.Color,
                    Icon = habit.Category.Icon,
                },
                StartDate = habit.StartDate,
                EndDate = habit.EndDate,
                Frequency = habit.Frequency,
                HasReminder = habit.HasReminder,
                ReminderTime = habit.ReminderTime,
                ReminderType = habit.ReminderType,
                IsActive = habit.IsActive,
                HabitSchedule = habit.HabitSchedule == null ? null : ToDto(habit.HabitSchedule),
                CompletionDates = habit.CompletionDates?.Select(c => c.CompletedAt).ToList() ?? new List<DateTime>(),
                WeeklyCompletions = weeklyCompletions,
                MonthlyCompletions = monthlyCompletions,
                CreatedAt = habit.CreatedAt
            };
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

        // ==========================================================
        // <<< KẾT THÚC CODE ĐÃ SỬA >>>
        // ==========================================================

    } // Đóng class HabitScheduleService
} // Đóng namespace backend.Services