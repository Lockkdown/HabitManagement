using backend.Models.Dtos;
using backend.Services;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

/// <summary>
/// Controller xử lý các API endpoints liên quan đến xác thực (đăng ký, đăng nhập).
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AuthService _authService;
    private readonly ILogger<AuthController> _logger;

    /// <summary>
    /// Khởi tạo AuthController với các dependencies cần thiết.
    /// </summary>
    /// <param name="authService">Service xử lý logic xác thực</param>
    /// <param name="logger">Logger để ghi log</param>
    public AuthController(AuthService authService, ILogger<AuthController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    /// <summary>
    /// Đăng ký người dùng mới.
    /// </summary>
    /// <param name="registerDto">Thông tin đăng ký của người dùng</param>
    /// <returns>
    /// 200 OK nếu đăng ký thành công.
    /// 400 BadRequest nếu thông tin không hợp lệ hoặc đã tồn tại.
    /// </returns>
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterDto registerDto)
    {
        try
        {
            // Gọi service để xử lý đăng ký
            var (success, errors) = await _authService.RegisterAsync(registerDto);

            if (!success)
            {
                return BadRequest(new { message = "Đăng ký thất bại", errors });
            }

            return Ok(new { message = "Đăng ký thành công" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi đăng ký người dùng");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi đăng ký" });
        }
    }

    /// <summary>
    /// Đăng nhập người dùng.
    /// </summary>
    /// <param name="loginDto">Thông tin đăng nhập (email, password)</param>
    /// <returns>
    /// 200 OK với AuthResponseDto (chứa tokens và thông tin user) nếu đăng nhập thành công.
    /// 401 Unauthorized nếu email hoặc password không đúng.
    /// </returns>
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto loginDto)
    {
        try
        {
            // Gọi service để xác thực và tạo tokens
            var response = await _authService.LoginAsync(loginDto);

            if (response == null)
            {
                return Unauthorized(new { message = "Email hoặc mật khẩu không đúng" });
            }

            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi đăng nhập");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi đăng nhập" });
        }
    }

    /// <summary>
    /// Xử lý yêu cầu quên mật khẩu.
    /// Gửi email chứa link reset mật khẩu đến người dùng.
    /// </summary>
    /// <param name="forgotPasswordDto">Thông tin email của người dùng</param>
    /// <returns>200 OK với tokenId để app có thể polling status</returns>
    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDto forgotPasswordDto)
    {
        try
        {
            var tokenId = await _authService.ForgotPasswordAsync(forgotPasswordDto);

            // Trả về tokenId để app có thể polling status
            return Ok(new 
            { 
                message = "Nếu email tồn tại trong hệ thống, một email xác nhận đã được gửi đi",
                tokenId = tokenId
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi xử lý quên mật khẩu");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi xử lý yêu cầu" });
        }
    }

    /// <summary>
    /// Verify token reset password khi user click link trong email.
    /// Endpoint này sẽ được gọi từ browser khi user click link.
    /// </summary>
    /// <param name="tokenId">Token ID từ query string</param>
    /// <returns>HTML page thông báo thành công hoặc thất bại</returns>
    [HttpGet("verify-reset-token")]
    public IActionResult VerifyResetToken([FromQuery] string tokenId)
    {
        try
        {
            var success = _authService.VerifyResetToken(tokenId);

            if (success)
            {
                var html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Xác nhận thành công</title>
    <style>
        body { font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
        .container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 10px 40px rgba(0,0,0,0.2); text-align: center; max-width: 400px; }
        .success-icon { font-size: 60px; color: #4CAF50; margin-bottom: 20px; }
        h1 { color: #333; margin: 0 0 10px 0; font-size: 24px; }
        p { color: #666; line-height: 1.6; margin: 0 0 20px 0; }
        .app-name { color: #2196F3; font-weight: bold; }
    </style>
</head>
<body>
    <div class='container'>
        <div class='success-icon'>✓</div>
        <h1>Xác nhận thành công!</h1>
        <p>Yêu cầu đặt lại mật khẩu của bạn đã được xác nhận.</p>
        <p>Vui lòng quay lại ứng dụng <span class='app-name'>Habit Management</span> trên điện thoại để tiếp tục.</p>
        <p style='font-size: 12px; color: #999; margin-top: 30px;'>Bạn có thể đóng trang này.</p>
    </div>
</body>
</html>";
                return Content(html, "text/html");
            }
            else
            {
                var html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Xác nhận thất bại</title>
    <style>
        body { font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); }
        .container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 10px 40px rgba(0,0,0,0.2); text-align: center; max-width: 400px; }
        .error-icon { font-size: 60px; color: #f44336; margin-bottom: 20px; }
        h1 { color: #333; margin: 0 0 10px 0; font-size: 24px; }
        p { color: #666; line-height: 1.6; margin: 0 0 20px 0; }
    </style>
</head>
<body>
    <div class='container'>
        <div class='error-icon'>✗</div>
        <h1>Link không hợp lệ</h1>
        <p>Link xác nhận không tồn tại hoặc đã hết hạn.</p>
        <p>Vui lòng thử lại từ đầu.</p>
    </div>
</body>
</html>";
                return Content(html, "text/html");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi verify reset token");
            return StatusCode(500, "Có lỗi xảy ra");
        }
    }

    /// <summary>
    /// Check trạng thái token reset password.
    /// App sẽ polling endpoint này để biết khi nào user đã click link trong email.
    /// </summary>
    /// <param name="tokenId">Token ID</param>
    /// <returns>Trạng thái token và token gốc nếu đã verified</returns>
    [HttpGet("check-token-status")]
    public IActionResult CheckTokenStatus([FromQuery] string tokenId)
    {
        try
        {
            var status = _authService.CheckTokenStatus(tokenId);
            return Ok(status);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi check token status");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi kiểm tra trạng thái" });
        }
    }

    /// <summary>
    /// Đặt lại mật khẩu mới cho người dùng.
    /// </summary>
    /// <param name="resetPasswordDto">Thông tin reset password (email, token, mật khẩu mới)</param>
    /// <returns>
    /// 200 OK nếu đặt lại mật khẩu thành công.
    /// 400 BadRequest nếu token không hợp lệ hoặc đã hết hạn.
    /// </returns>
    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto resetPasswordDto)
    {
        try
        {
            var (success, errors) = await _authService.ResetPasswordAsync(resetPasswordDto);

            if (!success)
            {
                return BadRequest(new { message = "Đặt lại mật khẩu thất bại", errors });
            }

            return Ok(new { message = "Đặt lại mật khẩu thành công" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi đặt lại mật khẩu");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi đặt lại mật khẩu" });
        }
    }

    /// <summary>
    /// Kiểm tra trạng thái server.
    /// Endpoint này không yêu cầu xác thực.
    /// </summary>
    /// <returns>200 OK với thông báo server đang hoạt động</returns>
    [HttpGet("ping")]
    public IActionResult Ping()
    {
        return Ok(new { message = "Habit Management API đang hoạt động", timestamp = DateTime.UtcNow });
    }
}
