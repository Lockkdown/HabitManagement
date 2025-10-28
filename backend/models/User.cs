using Microsoft.AspNetCore.Identity;

namespace backend.Models;

public class User : IdentityUser
{
    public string FullName { get; set; } = string.Empty;
    public DateTime? DateOfBirth { get; set; }
    public string ThemePreference { get; set; } = "dark";
    public string LanguageCode { get; set; } = "vi";
    public bool NotificationEnabled { get; set; } = true;
    public bool ReminderEnabled { get; set; } = true;
    public string ReminderTime { get; set; } = "08:00";
    
    // 2FA properties
    public string? TwoFactorSecret { get; set; }
    public bool TwoFactorSetupCompleted { get; set; } = false;
}
