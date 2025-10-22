using backend.Models;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace backend.Data;

/// <summary>
/// DbContext chính cho ứng dụng, quản lý kết nối và tương tác với database.
/// Kế thừa từ IdentityDbContext để tích hợp ASP.NET Core Identity.
/// </summary>
public class ApplicationDbContext : IdentityDbContext<User>
{
    /// <summary>
    /// Khởi tạo một instance mới của ApplicationDbContext.
    /// </summary>
    /// <param name="options">Các tùy chọn cấu hình cho DbContext</param>
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    /// <summary>
    /// Cấu hình các entity models khi khởi tạo database schema.
    /// </summary>
    /// <param name="builder">ModelBuilder để cấu hình entities</param>
    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // Có thể thêm các cấu hình bổ sung cho entities ở đây nếu cần
        // Ví dụ: thiết lập indexes, relationships, constraints...
    }
}
