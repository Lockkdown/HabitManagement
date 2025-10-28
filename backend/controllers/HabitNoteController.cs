using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using backend.Data;
using backend.Models;
using backend.Models.Dtos;
using System.Security.Claims;

namespace backend.Controllers;

/// <summary>
/// Controller quản lý ghi chú nhật ký thói quen.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class HabitNoteController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public HabitNoteController(ApplicationDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Lấy tất cả ghi chú của một thói quen.
    /// </summary>
    /// <param name="habitId">ID của thói quen</param>
    [HttpGet("habit/{habitId}")]
    public async Task<ActionResult<IEnumerable<HabitNoteResponseDto>>> GetHabitNotes(int habitId)
    {
        try
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            // Kiểm tra thói quen có thuộc về user hiện tại không
            var habit = await _context.Habits
                .FirstOrDefaultAsync(h => h.Id == habitId && h.UserId == userId);
            
            if (habit == null)
                return NotFound("Thói quen không tồn tại hoặc bạn không có quyền truy cập.");

            var notes = await _context.HabitNotes
                .Where(n => n.HabitId == habitId)
                .Include(n => n.Habit)
                .OrderByDescending(n => n.Date)
                .ToListAsync();

            var noteDtos = notes.Select(n => new HabitNoteResponseDto
            {
                Id = n.Id,
                HabitId = n.HabitId,
                HabitName = n.Habit.Name,
                Date = n.Date,
                Content = n.Content,
                Mood = n.Mood,
                MoodEmoji = GetMoodEmoji(n.Mood),
                CreatedAt = n.CreatedAt,
                UpdatedAt = n.UpdatedAt
            }).ToList();

            return Ok(noteDtos);
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Lỗi server: {ex.Message}");
        }
    }

    /// <summary>
    /// Lấy ghi chú của một thói quen trong ngày cụ thể.
    /// </summary>
    /// <param name="habitId">ID của thói quen</param>
    /// <param name="date">Ngày cần lấy ghi chú (yyyy-MM-dd)</param>
    [HttpGet("habit/{habitId}/date/{date}")]
    public async Task<ActionResult<HabitNoteResponseDto>> GetHabitNoteByDate(int habitId, DateTime date)
    {
        try
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            // Kiểm tra thói quen có thuộc về user hiện tại không
            var habit = await _context.Habits
                .FirstOrDefaultAsync(h => h.Id == habitId && h.UserId == userId);
            
            if (habit == null)
                return NotFound("Thói quen không tồn tại hoặc bạn không có quyền truy cập.");

            var note = await _context.HabitNotes
                .Include(n => n.Habit)
                .FirstOrDefaultAsync(n => n.HabitId == habitId && n.Date.Date == date.Date);

            if (note == null)
                return NotFound("Không tìm thấy ghi chú cho ngày này.");

            var noteDto = new HabitNoteResponseDto
            {
                Id = note.Id,
                HabitId = note.HabitId,
                HabitName = note.Habit.Name,
                Date = note.Date,
                Content = note.Content,
                Mood = note.Mood,
                MoodEmoji = GetMoodEmoji(note.Mood),
                CreatedAt = note.CreatedAt,
                UpdatedAt = note.UpdatedAt
            };

            return Ok(noteDto);
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Lỗi server: {ex.Message}");
        }
    }

    /// <summary>
    /// Tạo ghi chú mới cho thói quen.
    /// </summary>
    /// <param name="createDto">Thông tin ghi chú mới</param>
    [HttpPost]
    public async Task<ActionResult<HabitNoteResponseDto>> CreateHabitNote(CreateHabitNoteDto createDto)
    {
        try
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            // Kiểm tra thói quen có thuộc về user hiện tại không
            var habit = await _context.Habits
                .FirstOrDefaultAsync(h => h.Id == createDto.HabitId && h.UserId == userId);
            
            if (habit == null)
                return NotFound("Thói quen không tồn tại hoặc bạn không có quyền truy cập.");

            // Kiểm tra đã có ghi chú cho ngày này chưa
            var existingNote = await _context.HabitNotes
                .FirstOrDefaultAsync(n => n.HabitId == createDto.HabitId && n.Date.Date == createDto.Date.Date);

            if (existingNote != null)
                return BadRequest("Đã có ghi chú cho thói quen này trong ngày. Vui lòng cập nhật ghi chú hiện có.");

            var note = new HabitNote
            {
                HabitId = createDto.HabitId,
                Date = createDto.Date.Date, // Chỉ lưu ngày, không lưu giờ
                Content = createDto.Content,
                Mood = createDto.Mood,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.HabitNotes.Add(note);
            await _context.SaveChangesAsync();

            // Load lại để có thông tin Habit
            await _context.Entry(note).Reference(n => n.Habit).LoadAsync();

            var noteDto = new HabitNoteResponseDto
            {
                Id = note.Id,
                HabitId = note.HabitId,
                HabitName = note.Habit.Name,
                Date = note.Date,
                Content = note.Content,
                Mood = note.Mood,
                MoodEmoji = GetMoodEmoji(note.Mood),
                CreatedAt = note.CreatedAt,
                UpdatedAt = note.UpdatedAt
            };

            return CreatedAtAction(nameof(GetHabitNoteByDate), 
                new { habitId = note.HabitId, date = note.Date.ToString("yyyy-MM-dd") }, 
                noteDto);
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Lỗi server: {ex.Message}");
        }
    }

    /// <summary>
    /// Cập nhật ghi chú thói quen.
    /// </summary>
    /// <param name="id">ID của ghi chú</param>
    /// <param name="updateDto">Thông tin cập nhật</param>
    [HttpPut("{id}")]
    public async Task<ActionResult<HabitNoteResponseDto>> UpdateHabitNote(int id, UpdateHabitNoteDto updateDto)
    {
        try
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            var note = await _context.HabitNotes
                .Include(n => n.Habit)
                .FirstOrDefaultAsync(n => n.Id == id);

            if (note == null)
                return NotFound("Ghi chú không tồn tại.");

            // Kiểm tra quyền sở hữu
            if (note.Habit.UserId != userId)
                return Forbid("Bạn không có quyền chỉnh sửa ghi chú này.");

            // Cập nhật thông tin
            if (!string.IsNullOrEmpty(updateDto.Content))
                note.Content = updateDto.Content;
            
            if (updateDto.Mood.HasValue)
                note.Mood = updateDto.Mood;

            note.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            var noteDto = new HabitNoteResponseDto
            {
                Id = note.Id,
                HabitId = note.HabitId,
                HabitName = note.Habit.Name,
                Date = note.Date,
                Content = note.Content,
                Mood = note.Mood,
                MoodEmoji = GetMoodEmoji(note.Mood),
                CreatedAt = note.CreatedAt,
                UpdatedAt = note.UpdatedAt
            };

            return Ok(noteDto);
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Lỗi server: {ex.Message}");
        }
    }

    /// <summary>
    /// Xóa ghi chú thói quen.
    /// </summary>
    /// <param name="id">ID của ghi chú</param>
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteHabitNote(int id)
    {
        try
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            var note = await _context.HabitNotes
                .Include(n => n.Habit)
                .FirstOrDefaultAsync(n => n.Id == id);

            if (note == null)
                return NotFound("Ghi chú không tồn tại.");

            // Kiểm tra quyền sở hữu
            if (note.Habit.UserId != userId)
                return Forbid("Bạn không có quyền xóa ghi chú này.");

            _context.HabitNotes.Remove(note);
            await _context.SaveChangesAsync();

            return NoContent();
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Lỗi server: {ex.Message}");
        }
    }

    /// <summary>
    /// Lấy ID của người dùng hiện tại từ JWT token.
    /// </summary>
    private string? GetCurrentUserId()
    {
        return User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    }

    /// <summary>
    /// Chuyển đổi mức độ cảm xúc thành emoji.
    /// </summary>
    /// <param name="mood">Mức độ cảm xúc (1-5)</param>
    /// <returns>Emoji tương ứng</returns>
    private string? GetMoodEmoji(int? mood)
    {
        return mood switch
        {
            1 => "😢", // Rất buồn
            2 => "😞", // Buồn
            3 => "😐", // Bình thường
            4 => "😊", // Vui
            5 => "😄", // Rất vui
            _ => null
        };
    }
}