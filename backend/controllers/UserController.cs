using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using backend.Models;
using backend.Models.Dtos;
using System.Security.Claims;

namespace backend.Controllers;

/// <summary>
/// Controller quản lý thông tin người dùng.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UserController : ControllerBase
{
    private readonly UserManager<User> _userManager;
    private readonly ILogger<UserController> _logger;

    public UserController(UserManager<User> userManager, ILogger<UserController> logger)
    {
        _userManager = userManager;
        _logger = logger;
    }

    /// <summary>
    /// Lấy thông tin profile của người dùng hiện tại.
    /// </summary>
    /// <returns>Thông tin profile người dùng</returns>
    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim))
            {
                return Unauthorized(new { message = "Token không hợp lệ" });
            }

            var user = await _userManager.FindByIdAsync(userIdClaim);
            if (user == null)
            {
                return NotFound(new { message = "Không tìm thấy người dùng" });
            }

            var profile = new
            {
                userId = user.Id,
                username = user.UserName,
                fullName = user.FullName,
                email = user.Email,
                phoneNumber = user.PhoneNumber,
                themePreference = user.ThemePreference,
                languageCode = user.LanguageCode,
                dateOfBirth = user.DateOfBirth,
                notificationEnabled = user.NotificationEnabled,
                reminderEnabled = user.ReminderEnabled,
                reminderTime = user.ReminderTime
            };

            return Ok(profile);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi lấy thông tin profile người dùng");
            return StatusCode(500, new { message = "Lỗi server nội bộ" });
        }
    }

    /// <summary>
    /// Cập nhật thông tin profile của người dùng hiện tại.
    /// </summary>
    /// <param name="updateDto">Thông tin cần cập nhật</param>
    /// <returns>Kết quả cập nhật</returns>
    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateUserProfileDto updateDto)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim))
            {
                return Unauthorized(new { message = "Token không hợp lệ" });
            }

            var user = await _userManager.FindByIdAsync(userIdClaim);
            if (user == null)
            {
                return NotFound(new { message = "Không tìm thấy người dùng" });
            }

            // Kiểm tra username trùng lặp nếu có thay đổi
            if (!string.IsNullOrEmpty(updateDto.Username) && updateDto.Username != user.UserName)
            {
                var existingUser = await _userManager.FindByNameAsync(updateDto.Username);
                if (existingUser != null && existingUser.Id != user.Id)
                {
                    return BadRequest(new { message = "Tên người dùng đã tồn tại" });
                }
                
                var setUsernameResult = await _userManager.SetUserNameAsync(user, updateDto.Username);
                if (!setUsernameResult.Succeeded)
                {
                    return BadRequest(new { message = "Không thể cập nhật tên người dùng", errors = setUsernameResult.Errors });
                }
            }

            // Kiểm tra email trùng lặp nếu có thay đổi
            if (!string.IsNullOrEmpty(updateDto.Email) && updateDto.Email != user.Email)
            {
                var existingUser = await _userManager.FindByEmailAsync(updateDto.Email);
                if (existingUser != null && existingUser.Id != user.Id)
                {
                    return BadRequest(new { message = "Email đã tồn tại" });
                }
                
                var setEmailResult = await _userManager.SetEmailAsync(user, updateDto.Email);
                if (!setEmailResult.Succeeded)
                {
                    return BadRequest(new { message = "Không thể cập nhật email", errors = setEmailResult.Errors });
                }
            }

            // Cập nhật các trường khác
            if (!string.IsNullOrEmpty(updateDto.FullName))
                user.FullName = updateDto.FullName;

            if (!string.IsNullOrEmpty(updateDto.PhoneNumber))
                user.PhoneNumber = updateDto.PhoneNumber;

            if (!string.IsNullOrEmpty(updateDto.ThemePreference))
                user.ThemePreference = updateDto.ThemePreference;

            if (!string.IsNullOrEmpty(updateDto.LanguageCode))
                user.LanguageCode = updateDto.LanguageCode;

            // Cập nhật cài đặt thông báo và nhắc nhở
            if (updateDto.NotificationEnabled.HasValue)
            {
                user.NotificationEnabled = updateDto.NotificationEnabled.Value;
            }

            if (updateDto.ReminderEnabled.HasValue)
            {
                user.ReminderEnabled = updateDto.ReminderEnabled.Value;
            }

            if (!string.IsNullOrEmpty(updateDto.ReminderTime))
            {
                user.ReminderTime = updateDto.ReminderTime;
            }

            var updateResult = await _userManager.UpdateAsync(user);
            if (!updateResult.Succeeded)
            {
                return BadRequest(new { message = "Không thể cập nhật thông tin", errors = updateResult.Errors });
            }

            _logger.LogInformation($"Đã cập nhật thông tin người dùng {user.Id}");

            return Ok(new { message = "Cập nhật thông tin thành công" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi cập nhật thông tin người dùng");
            return StatusCode(500, new { message = "Lỗi server nội bộ" });
        }
    }
}