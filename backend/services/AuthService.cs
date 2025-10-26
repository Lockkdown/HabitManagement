using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using backend.Models;
using backend.Models.Dtos;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.IdentityModel.Tokens;

namespace backend.Services;

/// <summary>
/// Service xử lý logic xác thực và quản lý người dùng.
/// </summary>
public class AuthService
{
    private readonly UserManager<User> _userManager;
    private readonly SignInManager<User> _signInManager;
    private readonly IConfiguration _configuration;
    private readonly EmailService _emailService;
    private readonly IMemoryCache _cache;

    /// <summary>
    /// Khởi tạo AuthService với các dependencies cần thiết.
    /// </summary>
    /// <param name="userManager">UserManager để quản lý người dùng</param>
    /// <param name="signInManager">SignInManager để xử lý đăng nhập</param>
    /// <param name="configuration">Configuration để đọc settings</param>
    /// <param name="emailService">EmailService để gửi email</param>
    /// <param name="cache">MemoryCache để lưu trạng thái tạm thời</param>
    public AuthService(
        UserManager<User> userManager,
        SignInManager<User> signInManager,
        IConfiguration configuration,
        EmailService emailService,
        IMemoryCache cache)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _configuration = configuration;
        _emailService = emailService;
        _cache = cache;
    }

    /// <summary>
    /// Đăng ký người dùng mới vào hệ thống.
    /// </summary>
    /// <param name="registerDto">Thông tin đăng ký của người dùng</param>
    /// <returns>Kết quả đăng ký (thành công/thất bại) và thông báo lỗi nếu có</returns>
    public async Task<(bool Success, string[] Errors)> RegisterAsync(RegisterDto registerDto)
    {
        // Tạo đối tượng User mới từ thông tin đăng ký
        var user = new User
        {
            UserName = registerDto.Username,
            Email = registerDto.Email,
            FullName = registerDto.FullName,
            PhoneNumber = registerDto.PhoneNumber,
            DateOfBirth = registerDto.DateOfBirth,
            ThemePreference = "light", // Mặc định
            LanguageCode = "vi" // Mặc định Tiếng Việt
        };

        // Tạo user trong database với mật khẩu đã hash
        var result = await _userManager.CreateAsync(user, registerDto.Password);

        if (!result.Succeeded)
        {
            return (false, result.Errors.Select(e => e.Description).ToArray());
        }

        // Gán role "User" cho người dùng mới
        var roleResult = await _userManager.AddToRoleAsync(user, "User");
        if (!roleResult.Succeeded)
        {
            // Nếu gán role thất bại, ghi log nhưng vẫn cho đăng ký thành công
            Console.WriteLine($"Warning: Không thể gán role User cho {user.Email}");
        }

        // Gửi email chào mừng (không chờ kết quả, không làm crash nếu lỗi)
        _ = Task.Run(async () =>
        {
            try
            {
                await _emailService.SendWelcomeEmailAsync(user.Email!, user.FullName);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Warning: Không thể gửi email chào mừng cho {user.Email}: {ex.Message}");
            }
        });

        return (true, Array.Empty<string>());
    }

    /// <summary>
    /// Xác thực thông tin đăng nhập và tạo tokens.
    /// </summary>
    /// <param name="loginDto">Thông tin đăng nhập (email, password)</param>
    /// <returns>AuthResponseDto nếu thành công, null nếu thất bại</returns>
    public async Task<AuthResponseDto?> LoginAsync(LoginDto loginDto)
    {
        // Tìm user theo email
        var user = await _userManager.FindByEmailAsync(loginDto.Email);
        if (user == null)
        {
            return null;
        }

        // Kiểm tra password
        var result = await _signInManager.CheckPasswordSignInAsync(user, loginDto.Password, false);
        if (!result.Succeeded)
        {
            return null;
        }

        // Tạo Access Token và Refresh Token
        var accessToken = await GenerateAccessTokenAsync(user);
        var refreshToken = GenerateRefreshToken();

        // Lưu Refresh Token vào database (sẽ implement sau)
        // await SaveRefreshTokenAsync(user.Id, refreshToken);

        // Tính thời gian hết hạn của Access Token
        var expirationMinutes = int.Parse(Environment.GetEnvironmentVariable("JWT_ACCESS_TOKEN_EXPIRATION_MINUTES") ?? "30");
        var expiresAt = DateTime.UtcNow.AddMinutes(expirationMinutes);

        return new AuthResponseDto
        {
            UserId = user.Id,
            Username = user.UserName!,
            Email = user.Email!,
            FullName = user.FullName,
            ThemePreference = user.ThemePreference,
            LanguageCode = user.LanguageCode,
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresAt = expiresAt
        };
    }

    /// <summary>
    /// Tạo Access Token (JWT) cho người dùng.
    /// </summary>
    /// <param name="user">Người dùng cần tạo token</param>
    /// <returns>JWT token dạng string</returns>
    private async Task<string> GenerateAccessTokenAsync(User user)
    {
        // Lấy roles của user
        var roles = await _userManager.GetRolesAsync(user);

        // Tạo các claims (thông tin) sẽ được nhúng vào token
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id),
            new(ClaimTypes.Name, user.UserName!),
            new(ClaimTypes.Email, user.Email!),
            new("FullName", user.FullName),
        };

        // Thêm roles vào claims
        claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));

        // Lấy secret key từ environment variables
        var secretKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY")!;
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        // Lấy thông tin issuer, audience và expiration từ environment variables
        var issuer = Environment.GetEnvironmentVariable("JWT_ISSUER");
        var audience = Environment.GetEnvironmentVariable("JWT_AUDIENCE");
        var expirationMinutes = int.Parse(Environment.GetEnvironmentVariable("JWT_ACCESS_TOKEN_EXPIRATION_MINUTES") ?? "30");

        // Tạo JWT token
        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(expirationMinutes),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    /// <summary>
    /// Tạo Refresh Token ngẫu nhiên.
    /// </summary>
    /// <returns>Refresh token dạng string</returns>
    private string GenerateRefreshToken()
    {
        // Tạo một chuỗi ngẫu nhiên 64 ký tự làm refresh token
        var randomBytes = new byte[64];
        using var rng = System.Security.Cryptography.RandomNumberGenerator.Create();
        rng.GetBytes(randomBytes);
        return Convert.ToBase64String(randomBytes);
    }

    /// <summary>
    /// Xử lý yêu cầu quên mật khẩu, gửi email chứa link reset.
    /// </summary>
    /// <param name="forgotPasswordDto">Thông tin email của người dùng</param>
    /// <returns>TokenId để app có thể polling status, hoặc null nếu thất bại</returns>
    public async Task<string?> ForgotPasswordAsync(ForgotPasswordDto forgotPasswordDto)
    {
        // Tìm user theo email
        var user = await _userManager.FindByEmailAsync(forgotPasswordDto.Email);
        
        // Tạo tokenId duy nhất để tracking (tránh leak thông tin về user tồn tại hay không)
        var tokenId = Guid.NewGuid().ToString("N");
        
        if (user == null)
        {
            // Không tìm thấy user, nhưng vẫn trả về tokenId giả để tránh leak thông tin
            // Token này sẽ không bao giờ được verify
            return tokenId;
        }

        // Tạo token reset password
        var token = await _userManager.GeneratePasswordResetTokenAsync(user);

        // Lưu mapping tokenId -> {email, token, verified} vào cache (expire sau 24h)
        var cacheKey = $"reset_token_{tokenId}";
        var tokenData = new
        {
            Email = user.Email,
            Token = token,
            IsVerified = false,
            CreatedAt = DateTime.UtcNow
        };
        _cache.Set(cacheKey, tokenData, TimeSpan.FromHours(24));

        // Tạo link verification (khi click sẽ mark token là verified)
        var baseUrl = Environment.GetEnvironmentVariable("API_BASE_URL") ?? "http://localhost:5224";
        var verifyLink = $"{baseUrl}/api/auth/verify-reset-token?tokenId={tokenId}";

        // Gửi email chứa link verification
        await _emailService.SendPasswordResetWithLinkAsync(user.Email!, user.FullName, verifyLink);

        return tokenId;
    }

    /// <summary>
    /// Verify token reset password khi user click link trong email.
    /// </summary>
    /// <param name="tokenId">Token ID từ link</param>
    /// <returns>True nếu verify thành công</returns>
    public bool VerifyResetToken(string tokenId)
    {
        var cacheKey = $"reset_token_{tokenId}";
        
        if (!_cache.TryGetValue(cacheKey, out dynamic? tokenData) || tokenData == null)
        {
            return false;
        }

        // Update trạng thái thành verified
        var updatedData = new
        {
            Email = tokenData.Email?.ToString() ?? "",
            Token = tokenData.Token?.ToString() ?? "",
            IsVerified = true,
            CreatedAt = (tokenData.CreatedAt as DateTime?) ?? DateTime.UtcNow,
            VerifiedAt = DateTime.UtcNow
        };
        
        _cache.Set(cacheKey, updatedData, TimeSpan.FromHours(24));
        
        return true;
    }

    /// <summary>
    /// Check trạng thái token reset password.
    /// </summary>
    /// <param name="tokenId">Token ID</param>
    /// <returns>Thông tin trạng thái token</returns>
    public TokenStatusResponse CheckTokenStatus(string tokenId)
    {
        var cacheKey = $"reset_token_{tokenId}";
        
        if (!_cache.TryGetValue(cacheKey, out dynamic? tokenData) || tokenData == null)
        {
            return new TokenStatusResponse
            {
                IsVerified = false,
                Message = "Token không tồn tại hoặc đã hết hạn"
            };
        }

        bool isVerified = (tokenData.IsVerified?.Equals(true)) == true;
        
        return new TokenStatusResponse
        {
            IsVerified = isVerified,
            Token = isVerified ? tokenData.Token?.ToString() : null,
            Message = isVerified 
                ? "Token đã được xác nhận, bạn có thể đặt lại mật khẩu" 
                : "Đang chờ xác nhận từ email"
        };
    }

    /// <summary>
    /// Đặt lại mật khẩu mới cho người dùng.
    /// </summary>
    /// <param name="resetPasswordDto">Thông tin reset password (email, token, mật khẩu mới)</param>
    /// <returns>Kết quả reset (thành công/thất bại) và thông báo lỗi nếu có</returns>
    public async Task<(bool Success, string[] Errors)> ResetPasswordAsync(ResetPasswordDto resetPasswordDto)
    {
        // Tìm user theo email
        var user = await _userManager.FindByEmailAsync(resetPasswordDto.Email);
        if (user == null)
        {
            return (false, new[] { "Email không tồn tại trong hệ thống" });
        }

        // Reset password với token
        var result = await _userManager.ResetPasswordAsync(user, resetPasswordDto.Token, resetPasswordDto.NewPassword);

        if (!result.Succeeded)
        {
            return (false, result.Errors.Select(e => e.Description).ToArray());
        }

        return (true, Array.Empty<string>());
    }
}
