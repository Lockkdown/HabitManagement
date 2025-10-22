using SendGrid;
using SendGrid.Helpers.Mail;

namespace backend.Services;

/// <summary>
/// Service xử lý việc gửi email thông qua SendGrid.
/// </summary>
public class EmailService
{
    private readonly string _apiKey;
    private readonly string _fromEmail;
    private readonly string _fromName;
    private readonly ILogger<EmailService> _logger;

    /// <summary>
    /// Khởi tạo EmailService với SendGrid API key.
    /// </summary>
    /// <param name="logger">Logger để ghi log</param>
    public EmailService(ILogger<EmailService> logger)
    {
        _logger = logger;
        _apiKey = Environment.GetEnvironmentVariable("SENDGRID_API_KEY") ?? "";
        _fromEmail = Environment.GetEnvironmentVariable("SENDGRID_FROM_EMAIL") ?? "noreply@habitmanagement.com";
        _fromName = Environment.GetEnvironmentVariable("SENDGRID_FROM_NAME") ?? "Habit Management";
    }

    /// <summary>
    /// Gửi email xác thực tài khoản cho người dùng mới.
    /// </summary>
    /// <param name="toEmail">Email người nhận</param>
    /// <param name="userName">Tên người dùng</param>
    /// <param name="confirmationLink">Link xác thực email</param>
    /// <returns>True nếu gửi thành công, False nếu thất bại</returns>
    public async Task<bool> SendEmailConfirmationAsync(string toEmail, string userName, string confirmationLink)
    {
        var subject = "Xác nhận tài khoản - Habit Management";
        var htmlContent = $@"
            <h2>Chào mừng {userName}!</h2>
            <p>Cảm ơn bạn đã đăng ký tài khoản tại Habit Management.</p>
            <p>Vui lòng nhấn vào nút bên dưới để xác nhận địa chỉ email của bạn:</p>
            <p>
                <a href='{confirmationLink}' 
                   style='display: inline-block; padding: 12px 24px; background-color: #4CAF50; 
                          color: white; text-decoration: none; border-radius: 5px; font-weight: bold;'>
                    Xác nhận Email
                </a>
            </p>
            <p>Hoặc copy link sau vào trình duyệt:</p>
            <p><a href='{confirmationLink}'>{confirmationLink}</a></p>
            <br>
            <p>Nếu bạn không thực hiện đăng ký này, vui lòng bỏ qua email này.</p>
            <p>Trân trọng,<br>Habit Management Team</p>
        ";

        return await SendEmailAsync(toEmail, subject, htmlContent);
    }

    /// <summary>
    /// Gửi email chứa token reset mật khẩu.
    /// </summary>
    /// <param name="toEmail">Email người nhận</param>
    /// <param name="userName">Tên người dùng</param>
    /// <param name="resetToken">Token reset mật khẩu (plain text, không encode)</param>
    /// <returns>True nếu gửi thành công, False nếu thất bại</returns>
    public async Task<bool> SendPasswordResetAsync(string toEmail, string userName, string resetToken)
    {
        var subject = "Đặt lại mật khẩu - Habit Management";
        var htmlContent = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
</head>
<body style='font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;'>
    <div style='background-color: #f8f9fa; border-radius: 10px; padding: 30px;'>
        <h2 style='color: #2196F3; margin-top: 0;'>Xin chào {userName},</h2>
        <p>Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn.</p>
        <p>Vui lòng <strong>copy mã xác nhận</strong> bên dưới và dán vào ứng dụng để đặt lại mật khẩu:</p>
        
        <div style='background-color: white; padding: 20px; border-radius: 8px; margin: 30px 0; border: 2px dashed #2196F3;'>
            <p style='margin: 0 0 10px 0; font-size: 14px; color: #666; text-align: center;'>
                <strong>MÃ XÁC NHẬN:</strong>
            </p>
            <div style='background-color: #f8f9fa; padding: 15px; border-radius: 5px; text-align: center;'>
                <code style='font-size: 13px; color: #2196F3; word-break: break-all; font-family: monospace; font-weight: bold;'>{resetToken}</code>
            </div>
            <p style='margin: 10px 0 0 0; font-size: 12px; color: #999; text-align: center; font-style: italic;'>
                Chọn và copy toàn bộ mã trên
            </p>
        </div>
        
        <div style='background-color: #e3f2fd; border-left: 4px solid #2196F3; padding: 12px; margin: 20px 0;'>
            <p style='margin: 0; font-size: 14px;'>
                <strong>&#128241; Hướng dẫn:</strong><br>
                1. Mở ứng dụng Habit Management<br>
                2. Dán mã xác nhận vào ô 'Mã xác nhận'<br>
                3. Nhập mật khẩu mới và xác nhận<br>
                4. Hoàn tất!
            </p>
        </div>
        
        <div style='background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 12px; margin: 20px 0;'>
            <p style='margin: 0;'><strong>&#9888; Lưu ý:</strong> Mã này chỉ có hiệu lực trong 24 giờ.</p>
        </div>
        
        <p style='font-size: 14px; color: #666;'>Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này và mật khẩu của bạn sẽ không thay đổi.</p>
        
        <hr style='border: none; border-top: 1px solid #ddd; margin: 20px 0;'>
        
        <p style='font-size: 14px; color: #666; margin-bottom: 0;'>
            Trân trọng,<br>
            <strong>Habit Management Team</strong>
        </p>
    </div>
</body>
</html>
        ";

        return await SendEmailAsync(toEmail, subject, htmlContent);
    }

    /// <summary>
    /// Gửi email chứa link xác nhận reset mật khẩu.
    /// User chỉ cần click link để xác nhận, không cần copy/paste token.
    /// </summary>
    /// <param name="toEmail">Email người nhận</param>
    /// <param name="userName">Tên người dùng</param>
    /// <param name="verifyLink">Link xác nhận reset mật khẩu</param>
    /// <returns>True nếu gửi thành công, False nếu thất bại</returns>
    public async Task<bool> SendPasswordResetWithLinkAsync(string toEmail, string userName, string verifyLink)
    {
        var subject = "Đặt lại mật khẩu - Habit Management";
        var htmlContent = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
</head>
<body style='font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;'>
    <div style='background-color: #f8f9fa; border-radius: 10px; padding: 30px;'>
        <h2 style='color: #2196F3; margin-top: 0;'>Xin chào {userName},</h2>
        <p>Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn.</p>
        <p>Vui lòng <strong>nhấn nút bên dưới</strong> để xác nhận yêu cầu:</p>
        
        <div style='text-align: center; margin: 30px 0;'>
            <a href='{verifyLink}' 
               style='display: inline-block; padding: 15px 40px; background-color: #2196F3; 
                      color: white !important; text-decoration: none; border-radius: 8px; font-weight: bold;
                      font-size: 18px; box-shadow: 0 4px 6px rgba(33, 150, 243, 0.3);'>
                &#10003; Xác nhận đặt lại mật khẩu
            </a>
        </div>
        
        <div style='background-color: #e3f2fd; border-left: 4px solid #2196F3; padding: 12px; margin: 20px 0;'>
            <p style='margin: 0; font-size: 14px;'>
                <strong>&#128241; Sau khi xác nhận:</strong><br>
                1. Ứng dụng trên điện thoại sẽ tự động nhận được thông báo<br>
                2. Bạn sẽ được yêu cầu nhập mật khẩu mới<br>
                3. Hoàn tất!
            </p>
        </div>
        
        <div style='background-color: white; padding: 15px; border-radius: 5px; margin: 20px 0;'>
            <p style='margin: 5px 0; font-size: 12px; color: #666;'>Hoặc copy link sau vào trình duyệt:</p>
            <p style='margin: 5px 0; word-break: break-all; font-size: 12px;'>
                <a href='{verifyLink}' style='color: #2196F3;'>{verifyLink}</a>
            </p>
        </div>
        
        <div style='background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 12px; margin: 20px 0;'>
            <p style='margin: 0;'><strong>&#9888; Lưu ý:</strong> Link này chỉ có hiệu lực trong 24 giờ.</p>
        </div>
        
        <p style='font-size: 14px; color: #666;'>Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này và mật khẩu của bạn sẽ không thay đổi.</p>
        
        <hr style='border: none; border-top: 1px solid #ddd; margin: 20px 0;'>
        
        <p style='font-size: 14px; color: #666; margin-bottom: 0;'>
            Trân trọng,<br>
            <strong>Habit Management Team</strong>
        </p>
    </div>
</body>
</html>
        ";

        return await SendEmailAsync(toEmail, subject, htmlContent);
    }

    /// <summary>
    /// Gửi email chào mừng sau khi đăng ký thành công (không yêu cầu xác thực).
    /// </summary>
    /// <param name="toEmail">Email người nhận</param>
    /// <param name="userName">Tên người dùng</param>
    /// <returns>True nếu gửi thành công, False nếu thất bại</returns>
    public async Task<bool> SendWelcomeEmailAsync(string toEmail, string userName)
    {
        var subject = "Chào mừng đến với Habit Management!";
        var htmlContent = $@"
            <h2>Chào mừng {userName}!</h2>
            <p>Cảm ơn bạn đã đăng ký tài khoản tại Habit Management.</p>
            <p>Chúng tôi rất vui khi bạn tham gia cộng đồng của chúng tôi!</p>
            <p>Hãy bắt đầu xây dựng những thói quen tốt cho bản thân ngay hôm nay.</p>
            <br>
            <p>Chúc bạn có trải nghiệm tuyệt vời!</p>
            <p>Trân trọng,<br>Habit Management Team</p>
        ";

        return await SendEmailAsync(toEmail, subject, htmlContent);
    }

    /// <summary>
    /// Phương thức chung để gửi email qua SendGrid.
    /// </summary>
    /// <param name="toEmail">Email người nhận</param>
    /// <param name="subject">Tiêu đề email</param>
    /// <param name="htmlContent">Nội dung HTML của email</param>
    /// <returns>True nếu gửi thành công, False nếu thất bại</returns>
    private async Task<bool> SendEmailAsync(string toEmail, string subject, string htmlContent)
    {
        try
        {
            if (string.IsNullOrEmpty(_apiKey))
            {
                _logger.LogWarning("SendGrid API Key chưa được cấu hình");
                return false;
            }

            var client = new SendGridClient(_apiKey);
            var from = new EmailAddress(_fromEmail, _fromName);
            var to = new EmailAddress(toEmail);
            var msg = MailHelper.CreateSingleEmail(from, to, subject, "", htmlContent);

            var response = await client.SendEmailAsync(msg);

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation($"Email đã được gửi thành công tới {toEmail}");
                return true;
            }
            else
            {
                var body = await response.Body.ReadAsStringAsync();
                _logger.LogError($"Gửi email thất bại. Status: {response.StatusCode}, Body: {body}");
                return false;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Lỗi khi gửi email tới {toEmail}");
            return false;
        }
    }
}
