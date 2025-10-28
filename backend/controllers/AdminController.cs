using backend.Models;
using backend.Models.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers;

/// <summary>
/// Controller cho Admin quản lý users
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")] // Chỉ Admin mới access được
public class AdminController : ControllerBase
{
    private readonly UserManager<User> _userManager;
    private readonly ILogger<AdminController> _logger;

    public AdminController(
        UserManager<User> userManager,
        ILogger<AdminController> logger)
    {
        _userManager = userManager;
        _logger = logger;
    }

    /// <summary>
    /// Lấy danh sách tất cả users
    /// </summary>
    [HttpGet("users")]
    public async Task<IActionResult> GetAllUsers()
    {
        try
        {
            var users = await _userManager.Users.ToListAsync();
            var userListDtos = new List<UserListDto>();

            foreach (var user in users)
            {
                var roles = await _userManager.GetRolesAsync(user);
                
                userListDtos.Add(new UserListDto
                {
                    Id = user.Id,
                    Username = user.UserName ?? "",
                    Email = user.Email ?? "",
                    FullName = user.FullName,
                    PhoneNumber = user.PhoneNumber,
                    EmailConfirmed = user.EmailConfirmed,
                    LockoutEnabled = user.LockoutEnabled,
                    LockoutEnd = user.LockoutEnd,
                    Roles = roles.ToList(),
                    TwoFactorEnabled = user.TwoFactorEnabled,
                    TwoFactorSetupCompleted = user.TwoFactorSetupCompleted,
                });
            }

            return Ok(userListDtos);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi lấy danh sách users");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi lấy danh sách users" });
        }
    }

    /// <summary>
    /// Lấy chi tiết một user
    /// </summary>
    [HttpGet("users/{userId}")]
    public async Task<IActionResult> GetUserDetail(string userId)
    {
        try
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
            {
                return NotFound(new { message = "Không tìm thấy user" });
            }

            var roles = await _userManager.GetRolesAsync(user);

            var userDto = new UserListDto
            {
                Id = user.Id,
                Username = user.UserName ?? "",
                Email = user.Email ?? "",
                FullName = user.FullName,
                PhoneNumber = user.PhoneNumber,
                EmailConfirmed = user.EmailConfirmed,
                LockoutEnabled = user.LockoutEnabled,
                LockoutEnd = user.LockoutEnd,
                Roles = roles.ToList(),
                TwoFactorEnabled = user.TwoFactorEnabled,
                TwoFactorSetupCompleted = user.TwoFactorSetupCompleted,
            };

            return Ok(userDto);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi lấy chi tiết user");
            return StatusCode(500, new { message = "Có lỗi xảy ra" });
        }
    }

    /// <summary>
    /// Kích hoạt/Vô hiệu hóa tài khoản user
    /// </summary>
    [HttpPost("users/{userId}/toggle-lockout")]
    public async Task<IActionResult> ToggleLockout(string userId)
    {
        try
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
            {
                return NotFound(new { message = "Không tìm thấy user" });
            }

            // Kiểm tra không cho lock chính mình
            var currentUserId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == currentUserId)
            {
                return BadRequest(new { message = "Không thể khóa tài khoản của chính mình" });
            }

            // Toggle lockout
            if (user.LockoutEnd != null && user.LockoutEnd > DateTimeOffset.UtcNow)
            {
                // Đang bị khóa → Mở khóa
                await _userManager.SetLockoutEndDateAsync(user, null);
                return Ok(new { message = "Đã mở khóa tài khoản", isLocked = false });
            }
            else
            {
                // Chưa bị khóa → Khóa (100 năm)
                await _userManager.SetLockoutEndDateAsync(user, DateTimeOffset.UtcNow.AddYears(100));
                return Ok(new { message = "Đã khóa tài khoản", isLocked = true });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi toggle lockout user");
            return StatusCode(500, new { message = "Có lỗi xảy ra" });
        }
    }

    /// <summary>
    /// Reset mật khẩu user về mặc định
    /// </summary>
    [HttpPost("users/{userId}/reset-password")]
    public async Task<IActionResult> ResetPassword(string userId)
    {
        try
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
            {
                return NotFound(new { message = "Không tìm thấy user" });
            }

            // Reset về mật khẩu mặc định: User@123
            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            var result = await _userManager.ResetPasswordAsync(user, token, "User@123");

            if (result.Succeeded)
            {
                return Ok(new 
                { 
                    message = "Đã reset mật khẩu thành công", 
                    newPassword = "User@123" 
                });
            }

            return BadRequest(new 
            { 
                message = "Reset mật khẩu thất bại", 
                errors = result.Errors.Select(e => e.Description) 
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi reset password");
            return StatusCode(500, new { message = "Có lỗi xảy ra" });
        }
    }

    /// <summary>
    /// Xóa user
    /// </summary>
    [HttpDelete("users/{userId}")]
    public async Task<IActionResult> DeleteUser(string userId)
    {
        try
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
            {
                return NotFound(new { message = "Không tìm thấy user" });
            }

            // Kiểm tra không cho xóa chính mình
            var currentUserId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == currentUserId)
            {
                return BadRequest(new { message = "Không thể xóa tài khoản của chính mình" });
            }

            var result = await _userManager.DeleteAsync(user);
            if (result.Succeeded)
            {
                return Ok(new { message = "Đã xóa user thành công" });
            }

            return BadRequest(new 
            { 
                message = "Xóa user thất bại", 
                errors = result.Errors.Select(e => e.Description) 
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi xóa user");
            return StatusCode(500, new { message = "Có lỗi xảy ra" });
        }
    }

    /// <summary>
    /// Gán role cho user (Admin/User)
    /// </summary>
    [HttpPost("users/assign-role")]
    public async Task<IActionResult> AssignRole([FromBody] UpdateUserRoleDto dto)
    {
        try
        {
            var user = await _userManager.FindByIdAsync(dto.UserId);
            if (user == null)
            {
                return NotFound(new { message = "Không tìm thấy user" });
            }

            // Validate role
            if (dto.Role != "Admin" && dto.Role != "User")
            {
                return BadRequest(new { message = "Role chỉ có thể là 'Admin' hoặc 'User'" });
            }

            // Kiểm tra không cho tự gỡ quyền Admin của mình
            var currentUserId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (dto.UserId == currentUserId && dto.Role == "User")
            {
                return BadRequest(new { message = "Không thể gỡ quyền Admin của chính mình" });
            }

            // Xóa tất cả roles hiện tại
            var currentRoles = await _userManager.GetRolesAsync(user);
            await _userManager.RemoveFromRolesAsync(user, currentRoles);

            // Thêm role mới
            await _userManager.AddToRoleAsync(user, dto.Role);

            return Ok(new { message = $"Đã gán role '{dto.Role}' thành công" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi gán role");
            return StatusCode(500, new { message = "Có lỗi xảy ra" });
        }
    }
}
