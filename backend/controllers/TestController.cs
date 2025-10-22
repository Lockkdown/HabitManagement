using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

/// <summary>
/// Controller tạm thời để test các chức năng trong development.
/// CHỈ hoạt động trong môi trường Development.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class TestController : ControllerBase
{
    /// <summary>
    /// Hiển thị trang test reset password.
    /// Endpoint này sẽ nhận token và email từ link trong email.
    /// </summary>
    [HttpGet("reset-password")]
    public IActionResult ResetPasswordPage([FromQuery] string token, [FromQuery] string email)
    {
        var html = $@"
<!DOCTYPE html>
<html lang='vi'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Đặt lại mật khẩu</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            max-width: 500px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }}
        .container {{
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }}
        h2 {{
            color: #2196F3;
            margin-top: 0;
        }}
        .form-group {{
            margin-bottom: 15px;
        }}
        label {{
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }}
        input {{
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            box-sizing: border-box;
        }}
        button {{
            width: 100%;
            padding: 12px;
            background-color: #2196F3;
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            margin-top: 10px;
        }}
        button:hover {{
            background-color: #1976D2;
        }}
        .info {{
            background-color: #e3f2fd;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 20px;
            font-size: 14px;
        }}
        .message {{
            padding: 15px;
            border-radius: 5px;
            margin-top: 15px;
            display: none;
        }}
        .success {{
            background-color: #d4edda;
            color: #155724;
        }}
        .error {{
            background-color: #f8d7da;
            color: #721c24;
        }}
    </style>
</head>
<body>
    <div class='container'>
        <h2>🔐 Đặt lại mật khẩu</h2>
        
        <div class='info'>
            <strong>Email:</strong> {email}<br>
            <strong>Token hợp lệ:</strong> ✅
        </div>

        <form id='resetForm'>
            <div class='form-group'>
                <label>Mật khẩu mới:</label>
                <input type='password' id='newPassword' required minlength='6'>
            </div>
            
            <div class='form-group'>
                <label>Xác nhận mật khẩu:</label>
                <input type='password' id='confirmPassword' required minlength='6'>
            </div>
            
            <button type='submit'>Đặt lại mật khẩu</button>
        </form>

        <div id='message' class='message'></div>
    </div>

    <script>
        document.getElementById('resetForm').addEventListener('submit', async (e) => {{
            e.preventDefault();
            
            const newPassword = document.getElementById('newPassword').value;
            const confirmPassword = document.getElementById('confirmPassword').value;
            const messageDiv = document.getElementById('message');
            
            if (newPassword !== confirmPassword) {{
                messageDiv.className = 'message error';
                messageDiv.textContent = '❌ Mật khẩu và xác nhận mật khẩu không khớp!';
                messageDiv.style.display = 'block';
                return;
            }}
            
            try {{
                const response = await fetch('/api/auth/reset-password', {{
                    method: 'POST',
                    headers: {{
                        'Content-Type': 'application/json'
                    }},
                    body: JSON.stringify({{
                        email: '{email}',
                        token: '{token}',
                        newPassword: newPassword,
                        confirmPassword: confirmPassword
                    }})
                }});
                
                const data = await response.json();
                
                if (response.ok) {{
                    messageDiv.className = 'message success';
                    messageDiv.textContent = '✅ ' + data.message;
                    messageDiv.style.display = 'block';
                    document.getElementById('resetForm').reset();
                    
                    setTimeout(() => {{
                        messageDiv.textContent += ' Bạn có thể đóng trang này.';
                    }}, 1000);
                }} else {{
                    messageDiv.className = 'message error';
                    messageDiv.textContent = '❌ ' + data.message;
                    if (data.errors) {{
                        messageDiv.textContent += '\\n' + data.errors.join('\\n');
                    }}
                    messageDiv.style.display = 'block';
                }}
            }} catch (error) {{
                messageDiv.className = 'message error';
                messageDiv.textContent = '❌ Có lỗi xảy ra: ' + error.message;
                messageDiv.style.display = 'block';
            }}
        }});
    </script>
</body>
</html>
        ";

        return Content(html, "text/html");
    }
}
