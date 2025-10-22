using Microsoft.AspNetCore.Identity;

namespace backend.Data;

/// <summary>
/// Class để khởi tạo dữ liệu ban đầu (seed data) cho database.
/// </summary>
public static class SeedData
{
    /// <summary>
    /// Khởi tạo các roles mặc định trong hệ thống.
    /// </summary>
    /// <param name="serviceProvider">Service provider để lấy RoleManager</param>
    public static async Task InitializeRolesAsync(IServiceProvider serviceProvider)
    {
        var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole>>();

        // Danh sách các roles cần tạo
        string[] roleNames = { "Admin", "User" };

        foreach (var roleName in roleNames)
        {
            // Kiểm tra xem role đã tồn tại chưa
            var roleExist = await roleManager.RoleExistsAsync(roleName);
            if (!roleExist)
            {
                // Tạo role mới nếu chưa tồn tại
                await roleManager.CreateAsync(new IdentityRole(roleName));
                Console.WriteLine($"Role '{roleName}' đã được tạo");
            }
        }
    }
}
