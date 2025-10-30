using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using backend.Models;
using backend.Models.Dtos;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.IdentityModel.Tokens;
using OtpNet;
using QRCoder;

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
            ThemePreference = "dark", // Mặc định
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

        // Gửi email chào mừng
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
        var refreshToken = await GenerateRefreshTokenAsync(user);

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
    /// Tạo Refresh Token (JWT với expiration dài hơn).
    /// </summary>
    /// <param name="user">Người dùng cần tạo refresh token</param>
    /// <returns>Refresh token dạng JWT string</returns>
    private async Task<string> GenerateRefreshTokenAsync(User user)
    {
        // Lấy roles của user
        var roles = await _userManager.GetRolesAsync(user);

        // Tạo các claims cho refresh token (tối giản, chỉ cần userId)
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id),
            new(ClaimTypes.Name, user.UserName!),
            new(ClaimTypes.Email, user.Email!),
        };

        // Thêm roles vào claims
        claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));

        // Lấy secret key từ environment variables
        var secretKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY")!;
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        // Lấy thông tin issuer, audience từ environment variables
        var issuer = Environment.GetEnvironmentVariable("JWT_ISSUER");
        var audience = Environment.GetEnvironmentVariable("JWT_AUDIENCE");
        // Refresh token có expiration dài hơn (7 ngày)
        var expirationDays = int.Parse(Environment.GetEnvironmentVariable("JWT_REFRESH_TOKEN_EXPIRATION_DAYS") ?? "7");

        // Tạo JWT refresh token
        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddDays(expirationDays),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
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

    /// <summary>
    /// Refresh access token bằng refresh token.
    /// Được gọi khi sinh trắc học thành công.
    /// </summary>
    /// <param name="refreshToken">Refresh token đã lưu</param>
    /// <returns>AuthResponseDto với access token mới</returns>
    public async Task<AuthResponseDto> RefreshTokenAsync(string refreshToken)
    {
        if (string.IsNullOrEmpty(refreshToken))
        {
            throw new Exception("Refresh token không hợp lệ");
        }

        try
        {
            // Giải mã refresh token để lấy userId
            // Refresh token cũng là JWT nhưng có expiration dài hơn
            var tokenHandler = new JwtSecurityTokenHandler();
            var secretKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY")!;
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));

            var validationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = key,
                ValidateIssuer = true,
                ValidIssuer = Environment.GetEnvironmentVariable("JWT_ISSUER"),
                ValidateAudience = true,
                ValidAudience = Environment.GetEnvironmentVariable("JWT_AUDIENCE"),
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            };

            var principal = tokenHandler.ValidateToken(refreshToken, validationParameters, out SecurityToken validatedToken);
            
            // Lấy userId từ claims
            var userId = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
            {
                throw new Exception("Không thể xác định user từ token");
            }

            // Lấy thông tin user từ database
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
            {
                throw new Exception("User không tồn tại");
            }

            // Tạo access token mới
            var newAccessToken = await GenerateAccessTokenAsync(user);
            // Giữ nguyên refresh token cũ (hoặc tạo mới nếu muốn rotation)
            var newRefreshToken = refreshToken;

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
                AccessToken = newAccessToken,
                RefreshToken = newRefreshToken,
                ExpiresAt = expiresAt
            };
        }
        catch (Exception ex)
        {
            throw new Exception($"Refresh token không hợp lệ: {ex.Message}");
        }
    }

    #region 2FA Public Methods

    /// <summary>
    /// Tạo tài khoản Admin (tự động enable 2FA)
    /// </summary>
    public async Task<(bool Success, string[] Errors, string? SecretKey, string? QrCode)> CreateAdminAsync(CreateAdminDto createAdminDto)
    {
        var user = new User
        {
            UserName = createAdminDto.Email,
            Email = createAdminDto.Email,
            FullName = createAdminDto.FullName,
            PhoneNumber = createAdminDto.PhoneNumber,
            EmailConfirmed = true, // Admin auto-confirmed
            TwoFactorEnabled = true, // Admin bắt buộc 2FA
            TwoFactorSetupCompleted = false
        };

        // Tạo Secret Key TOTP
        var secretKey = GenerateTotpSecret();
        user.TwoFactorSecret = secretKey;

        // Tạo user
        var result = await _userManager.CreateAsync(user, createAdminDto.Password);
        if (!result.Succeeded)
        {
            return (false, result.Errors.Select(e => e.Description).ToArray(), null, null);
        }

        // Gán role Admin
        var roleResult = await _userManager.AddToRoleAsync(user, "Admin");
        if (!roleResult.Succeeded)
        {
            Console.WriteLine($"Warning: Không thể gán role Admin cho {user.Email}");
        }

        // Tạo QR Code
        var qrCode = GenerateQrCode(secretKey, user.Email!);

        // TODO: Gửi email với QR Code (implement SendAdminSetup2FAEmail later)
        // _ = Task.Run(async () =>
        // {
        //     try
        //     {
        //         await _emailService.SendAdminSetup2FAEmail(user.Email!, user.FullName, qrCode, secretKey);
        //     }
        //     catch (Exception ex)
        //     {
        //         Console.WriteLine($"Warning: Không thể gửi email setup 2FA cho {user.Email}: {ex.Message}");
        //     }
        // });

        return (true, Array.Empty<string>(), secretKey, qrCode);
    }

    /// <summary>
    /// Login với hỗ trợ 2FA
    /// </summary>
    public async Task<TwoFactorLoginResponseDto?> LoginWithTwoFactorAsync(LoginDto loginDto)
    {
        // Tìm user theo email
        var user = await _userManager.FindByEmailAsync(loginDto.Email);
        if (user == null)
        {
            throw new Exception("Email hoặc mật khẩu không đúng");
        }

        // Kiểm tra xem user có bị khóa không
        var isLockedOut = await _userManager.IsLockedOutAsync(user);
        Console.WriteLine($"[AuthService] User {user.Email} - IsLockedOut: {isLockedOut}, LockoutEnd: {user.LockoutEnd}");
        
        if (isLockedOut)
        {
            throw new Exception("Tài khoản của bạn đã bị vô hiệu hóa. Vui lòng liên hệ quản trị viên.");
        }

        // Kiểm tra password
        var result = await _signInManager.CheckPasswordSignInAsync(user, loginDto.Password, false);
        if (!result.Succeeded)
        {
            if (result.IsLockedOut)
            {
                throw new Exception("Tài khoản của bạn đã bị vô hiệu hóa. Vui lòng liên hệ quản trị viên.");
            }
            throw new Exception("Email hoặc mật khẩu không đúng");
        }

        // Kiểm tra user có bật 2FA không
        if (user.TwoFactorEnabled)
        {
            // Lần đầu: cần setup 2FA
            if (!user.TwoFactorSetupCompleted)
            {
                var tempToken = GenerateTempToken(user.Id);
                var qrCode = GenerateQrCode(user.TwoFactorSecret!, user.Email!);

                return new TwoFactorLoginResponseDto
                {
                    RequiresTwoFactorSetup = true,
                    TempToken = tempToken,
                    QrCode = qrCode,
                    SecretKey = user.TwoFactorSecret
                };
            }

            // Lần sau: yêu cầu verify OTP
            var tempToken2 = GenerateTempToken(user.Id);
            return new TwoFactorLoginResponseDto
            {
                RequiresTwoFactorVerification = true,
                TempToken = tempToken2
            };
        }

        // User thường: không cần 2FA, cấp token ngay
        var accessToken = await GenerateAccessTokenAsync(user);
        var refreshToken = await GenerateRefreshTokenAsync(user);
        var expirationMinutes = int.Parse(Environment.GetEnvironmentVariable("JWT_ACCESS_TOKEN_EXPIRATION_MINUTES") ?? "30");
        var expiresAt = DateTime.UtcNow.AddMinutes(expirationMinutes);

        return new TwoFactorLoginResponseDto
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresAt = expiresAt,
            User = new AuthResponseDto
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
            }
        };
    }

    /// <summary>
    /// Verify OTP khi setup 2FA lần đầu
    /// </summary>
    public async Task<AuthResponseDto?> VerifyTwoFactorSetupAsync(VerifyTwoFactorDto verifyDto)
    {
        try
        {
            var userId = ValidateTempToken(verifyDto.TempToken);
            var user = await _userManager.FindByIdAsync(userId);
            
            if (user == null)
                return null;

            // Verify OTP
            if (!VerifyTotp(user.TwoFactorSecret!, verifyDto.Otp))
                return null;

            // Setup hoàn tất
            user.TwoFactorSetupCompleted = true;
            await _userManager.UpdateAsync(user);

            // Cấp token
            var accessToken = await GenerateAccessTokenAsync(user);
            var refreshToken = await GenerateRefreshTokenAsync(user);
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
        catch
        {
            return null;
        }
    }

    /// <summary>
    /// Verify OTP khi login lần sau
    /// </summary>
    public async Task<AuthResponseDto?> VerifyTwoFactorLoginAsync(VerifyTwoFactorDto verifyDto)
    {
        try
        {
            var userId = ValidateTempToken(verifyDto.TempToken);
            var user = await _userManager.FindByIdAsync(userId);
            
            if (user == null)
                return null;

            // Verify OTP
            if (!VerifyTotp(user.TwoFactorSecret!, verifyDto.Otp))
                return null;

            // Cấp token
            var accessToken = await GenerateAccessTokenAsync(user);
            var refreshToken = await GenerateRefreshTokenAsync(user);
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
        catch
        {
            return null;
        }
    }

    #endregion

    #region 2FA Helper Methods

    /// <summary>
    /// Tạo Secret Key TOTP (32 ký tự Base32)
    /// </summary>
    private string GenerateTotpSecret()
    {
        var key = KeyGeneration.GenerateRandomKey(32);
        return Base32Encoding.ToString(key);
    }

    /// <summary>
    /// Tạo QR Code từ Secret Key
    /// </summary>
    private string GenerateQrCode(string secretKey, string email)
    {
        try
        {
            var qrGenerator = new QRCodeGenerator();
            var otpAuthUrl = $"otpauth://totp/HabitManagement:{email}?secret={secretKey}&issuer=HabitManagement";
            var qrCodeData = qrGenerator.CreateQrCode(otpAuthUrl, QRCodeGenerator.ECCLevel.Q);
            
            var qrCode = new PngByteQRCode(qrCodeData);
            var qrCodeImage = qrCode.GetGraphic(10);
            
            return Convert.ToBase64String(qrCodeImage);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error generating QR code: {ex.Message}");
            return string.Empty;
        }
    }

    /// <summary>
    /// Verify OTP từ TOTP
    /// </summary>
    private bool VerifyTotp(string secretKey, string otp)
    {
        try
        {
            var bytes = Base32Encoding.ToBytes(secretKey);
            var totp = new Totp(bytes);
            
            return totp.VerifyTotp(otp, out long timeStepMatched, VerificationWindow.RfcSpecifiedNetworkDelay);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error verifying TOTP: {ex.Message}");
            return false;
        }
    }

    /// <summary>
    /// Tạo temporary token (JWT ngắn hạn 5 phút)
    /// </summary>
    private string GenerateTempToken(string userId)
    {
        var secretKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY")!;
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, userId),
            new("TokenType", "Temporary")
        };

        var token = new JwtSecurityToken(
            issuer: Environment.GetEnvironmentVariable("JWT_ISSUER"),
            audience: Environment.GetEnvironmentVariable("JWT_AUDIENCE"),
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(5), // 5 phút
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    /// <summary>
    /// Validate temporary token và lấy userId
    /// </summary>
    private string ValidateTempToken(string tempToken)
    {
        try
        {
            var secretKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY")!;
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));

            var tokenHandler = new JwtSecurityTokenHandler();
            var validationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = Environment.GetEnvironmentVariable("JWT_ISSUER"),
                ValidAudience = Environment.GetEnvironmentVariable("JWT_AUDIENCE"),
                IssuerSigningKey = key
            };

            var principal = tokenHandler.ValidateToken(tempToken, validationParameters, out SecurityToken validatedToken);
            var userId = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userId))
                throw new Exception("Invalid token: UserId not found");

            return userId;
        }
        catch (Exception ex)
        {
            throw new UnauthorizedAccessException($"Invalid temporary token: {ex.Message}");
        }
    }

    #endregion
}
