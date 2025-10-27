using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using backend.Services;
using backend.Models.Dtos;
using backend.Data;
using System.Security.Claims;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class HabitScheduleController : ControllerBase
    {
        private readonly HabitScheduleService _habitScheduleService;
        private readonly ApplicationDbContext _context;

        public HabitScheduleController(HabitScheduleService habitScheduleService, ApplicationDbContext context)
        {
            _habitScheduleService = habitScheduleService;
            _context = context;
        }

        // ✅ GET: api/HabitSchedule/habit/{habitId}
        [HttpGet("habit/{habitId}")]
        public async Task<ActionResult<List<HabitScheduleDto>>> GetHabitSchedulesByHabitId(int habitId)
        {
            var schedules = await _habitScheduleService.GetHabitSchedulesByHabitIdAsync(habitId);
            return Ok(schedules);
        }

        // ✅ GET: api/HabitSchedule/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<HabitScheduleDto>> GetHabitSchedule(int id)
        {
            var schedule = await _habitScheduleService.GetHabitScheduleByIdAsync(id);

            if (schedule == null)
                return NotFound();

            return Ok(schedule);
        }

        // ✅ POST: api/HabitSchedule
        [HttpPost]
        public async Task<ActionResult<HabitScheduleDto>> CreateHabitSchedule(HabitScheduleDto scheduleDto)
        {
            var createdSchedule = await _habitScheduleService.CreateHabitScheduleAsync(scheduleDto);
            if (createdSchedule == null)
                return BadRequest("Không thể tạo lịch trình thói quen");

            return CreatedAtAction(nameof(GetHabitSchedule), new { id = createdSchedule.Id }, createdSchedule);
        }

        // ✅ PUT: api/HabitSchedule/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateHabitSchedule(int id, HabitScheduleDto scheduleDto)
        {
            var result = await _habitScheduleService.UpdateHabitScheduleAsync(id, scheduleDto);

            if (!result)
                return NotFound();

            return NoContent();
        }

        // ✅ DELETE: api/HabitSchedule/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteHabitSchedule(int id)
        {
            var result = await _habitScheduleService.DeleteHabitScheduleAsync(id);

            if (!result)
                return NotFound();

            return NoContent();
        }

        // ✅ GET: api/HabitSchedule/check/{habitId}/{date}
        [HttpGet("check/{habitId}/{date}")]
        public async Task<ActionResult<bool>> CheckHabitForDate(int habitId, DateTime date)
        {
            var shouldPerform = await _habitScheduleService.ShouldHabitBePerformedOnDateAsync(habitId, date);
            return Ok(shouldPerform);
        }

        // ✅ GET: api/HabitSchedule/due-today/{userId}?date=2023-10-26
        // Lấy danh sách thói quen cần làm vào ngày được chọn của user
        [HttpGet("due-today/{userId}")]
        public async Task<ActionResult<List<HabitResponseDto>>> GetHabitsDueToday(string userId, [FromQuery] DateTime? date = null)
        {
            try
            {
                // Sử dụng ngày được chọn hoặc ngày hiện tại nếu không có
                DateTime selectedDate = date ?? DateTime.Today;
                Console.WriteLine($"GetHabitsDueToday called for userId: {userId}, date: {selectedDate:yyyy-MM-dd}");

                var habits = await _habitScheduleService.GetHabitsDueTodayAsync(userId, selectedDate);
                return Ok(habits);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"GetHabitsDueToday error: {ex.Message}");
                return StatusCode(500, new { message = "Lỗi server: " + ex.Message });
            }
        }

        // ✅ GET: api/HabitSchedule/debug
        [HttpGet("debug")]
        public async Task<ActionResult<object>> DebugHabits()
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                    return Unauthorized("Không thể xác định user từ token.");

                var allHabits = await _context.Habits
                    .Where(h => h.UserId == userId)
                    .Include(h => h.Category)
                    .ToListAsync();

                var activeHabits = allHabits.Where(h => h.IsActive).ToList();
                var schedules = await _context.HabitSchedules
                    .Where(s => s.HabitId != 0)
                    .ToListAsync();

                return Ok(new
                {
                    userId,
                    totalHabits = allHabits.Count,
                    activeHabits = activeHabits.Count,
                    totalSchedules = schedules.Count,
                    habits = activeHabits.Select(h => new
                    {
                        id = h.Id,
                        name = h.Name,
                        frequency = h.Frequency,
                        startDate = h.StartDate,
                        isActive = h.IsActive,
                        category = h.Category?.Name
                    }).ToList()
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Debug error: " + ex.Message });
            }
        }

        // ✅ GET: api/HabitSchedule/test-auth
        [HttpGet("test-auth")]
        public ActionResult<object> TestAuth()
        {
            try
            {
                var userId = GetCurrentUserId();
                var username = User.FindFirst(ClaimTypes.Name)?.Value;
                var email = User.FindFirst(ClaimTypes.Email)?.Value;

                return Ok(new
                {
                    isAuthenticated = User.Identity?.IsAuthenticated ?? false,
                    userId,
                    username,
                    email,
                    claims = User.Claims.Select(c => new { c.Type, c.Value }).ToList()
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Test auth error: " + ex.Message });
            }
        }

        // ✅ Hỗ trợ lấy userId từ token
        private string? GetCurrentUserId()
        {
            return User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        }
    }
}
