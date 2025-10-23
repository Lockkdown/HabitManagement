using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using backend.Data;
using backend.Models;
using backend.Models.Dtos;
using System.Security.Claims;

namespace backend.Controllers;

/// <summary>
/// Controller quản lý danh mục thói quen.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CategoryController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public CategoryController(ApplicationDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Lấy danh sách tất cả danh mục của người dùng hiện tại.
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<CategoryResponseDto>>> GetCategories()
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var categories = await _context.Categories
            .Where(c => c.UserId == userId)
            .Select(c => new CategoryResponseDto
            {
                Id = c.Id,
                Name = c.Name,
                Color = c.Color,
                Icon = c.Icon,
                HabitCount = c.Habits.Count,
                CreatedAt = c.CreatedAt
            })
            .ToListAsync();

        return Ok(categories);
    }

    /// <summary>
    /// Lấy thông tin chi tiết của một danh mục.
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<CategoryResponseDto>> GetCategory(int id)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var category = await _context.Categories
            .Where(c => c.Id == id && c.UserId == userId)
            .Select(c => new CategoryResponseDto
            {
                Id = c.Id,
                Name = c.Name,
                Color = c.Color,
                Icon = c.Icon,
                HabitCount = c.Habits.Count,
                CreatedAt = c.CreatedAt
            })
            .FirstOrDefaultAsync();

        if (category == null) return NotFound();

        return Ok(category);
    }

    /// <summary>
    /// Tạo danh mục mới.
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<CategoryResponseDto>> CreateCategory(CreateCategoryDto dto)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var category = new Category
        {
            Name = dto.Name,
            Color = dto.Color,
            Icon = dto.Icon,
            UserId = userId,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.Categories.Add(category);
        await _context.SaveChangesAsync();

        var response = new CategoryResponseDto
        {
            Id = category.Id,
            Name = category.Name,
            Color = category.Color,
            Icon = category.Icon,
            HabitCount = 0,
            CreatedAt = category.CreatedAt
        };

        return CreatedAtAction(nameof(GetCategory), new { id = category.Id }, response);
    }

    /// <summary>
    /// Cập nhật danh mục.
    /// </summary>
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateCategory(int id, UpdateCategoryDto dto)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var category = await _context.Categories
            .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId);

        if (category == null) return NotFound();

        if (dto.Name != null) category.Name = dto.Name;
        if (dto.Color != null) category.Color = dto.Color;
        if (dto.Icon != null) category.Icon = dto.Icon;
        category.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return NoContent();
    }

    /// <summary>
    /// Xóa danh mục.
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteCategory(int id)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var category = await _context.Categories
            .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId);

        if (category == null) return NotFound();

        // Kiểm tra xem danh mục có thói quen nào không
        var hasHabits = await _context.Habits.AnyAsync(h => h.CategoryId == id);
        if (hasHabits)
        {
            return BadRequest("Không thể xóa danh mục có chứa thói quen");
        }

        _context.Categories.Remove(category);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    /// <summary>
    /// Lấy danh sách danh mục mặc định (để người dùng có thể tạo thói quen ngay).
    /// </summary>
    [HttpGet("default")]
    public ActionResult<IEnumerable<CategoryResponseDto>> GetDefaultCategories()
    {
        var defaultCategories = new List<CategoryResponseDto>
        {
            new() { Id = -1, Name = "Sức khỏe", Color = "#FF6B6B", Icon = "heart", HabitCount = 0, CreatedAt = DateTime.UtcNow },
            new() { Id = -2, Name = "Học tập", Color = "#4ECDC4", Icon = "book", HabitCount = 0, CreatedAt = DateTime.UtcNow },
            new() { Id = -3, Name = "Công việc", Color = "#45B7D1", Icon = "briefcase", HabitCount = 0, CreatedAt = DateTime.UtcNow },
            new() { Id = -4, Name = "Thể thao", Color = "#96CEB4", Icon = "dumbbell", HabitCount = 0, CreatedAt = DateTime.UtcNow },
            new() { Id = -5, Name = "Giải trí", Color = "#FFEAA7", Icon = "music", HabitCount = 0, CreatedAt = DateTime.UtcNow },
            new() { Id = -6, Name = "Gia đình", Color = "#DDA0DD", Icon = "home", HabitCount = 0, CreatedAt = DateTime.UtcNow },
            new() { Id = -7, Name = "Khác", Color = "#A8A8A8", Icon = "more-horizontal", HabitCount = 0, CreatedAt = DateTime.UtcNow }
        };

        return Ok(defaultCategories);
    }

    /// <summary>
    /// Lấy ID của người dùng hiện tại từ JWT token.
    /// </summary>
    private string? GetCurrentUserId()
    {
        return User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    }
}

