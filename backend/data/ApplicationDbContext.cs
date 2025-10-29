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
    /// DbSet cho danh mục thói quen.
    /// </summary>
    public DbSet<Category> Categories { get; set; } = null!; // Nên khởi tạo với null!

    /// <summary>
    /// DbSet cho thói quen.
    /// </summary>
    public DbSet<Habit> Habits { get; set; } = null!; // Nên khởi tạo với null!

    /// <summary>
    /// DbSet cho lần hoàn thành thói quen.
    /// </summary>
    public DbSet<HabitCompletion> HabitCompletions { get; set; } = null!; // Nên khởi tạo với null!

    /// <summary>
    /// DbSet cho lịch trình thói quen.
    /// </summary>
    public DbSet<HabitSchedule> HabitSchedules { get; set; } = null!; // Nên khởi tạo với null!

    /// <summary>
    /// DbSet cho ghi chú nhật ký thói quen.
    /// </summary>
    public DbSet<HabitNote> HabitNotes { get; set; } = null!; // Nên khởi tạo với null!


    /// <summary>
    /// Cấu hình các entity models khi khởi tạo database schema.
    /// </summary>
    /// <param name="builder">ModelBuilder để cấu hình entities</param>
    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // Cấu hình Category
        builder.Entity<Category>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Color).IsRequired().HasMaxLength(7);
            entity.Property(e => e.Icon).IsRequired().HasMaxLength(50);
            // entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETUTCDATE()"); // Dùng UtcNow trong model thay thế
            // entity.Property(e => e.UpdatedAt).HasDefaultValueSql("GETUTCDATE()"); // Dùng UtcNow trong model thay thế

            // Relationship với User
            entity.HasOne(e => e.User)
                .WithMany() // User có thể có nhiều Category
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade); // Xóa Category nếu User bị xóa
        });

        // Cấu hình Habit
        builder.Entity<Habit>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Description).HasMaxLength(1000);
            entity.Property(e => e.Frequency).IsRequired().HasMaxLength(20);
            entity.Property(e => e.CustomFrequencyUnit).HasMaxLength(20);
            entity.Property(e => e.ReminderType).HasMaxLength(20);
            // entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
            // entity.Property(e => e.UpdatedAt).HasDefaultValueSql("GETUTCDATE()");

            // Relationship với User
            entity.HasOne(e => e.User)
                .WithMany() // User có thể có nhiều Habit
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade); // Xóa Habit nếu User bị xóa

            // Relationship với Category
            entity.HasOne(e => e.Category)
                .WithMany(c => c.Habits) // Category có nhiều Habit
                .HasForeignKey(e => e.CategoryId)
                .OnDelete(DeleteBehavior.Restrict); // Không cho xóa Category nếu còn Habit

            // <<< --- SỬA ĐỔI QUAN HỆ VỚI COMPLETIONS --- >>>
            // Relationship với HabitCompletion (đổi tên collection)
            entity.HasMany(e => e.CompletionDates) // Sử dụng tên mới CompletionDates
                .WithOne(c => c.Habit)
                .HasForeignKey(c => c.HabitId)
                .OnDelete(DeleteBehavior.Cascade); // Xóa Completions nếu Habit bị xóa

            // <<< --- THÊM CẤU HÌNH QUAN HỆ MỘT-MỘT VỚI SCHEDULE --- >>>
            entity.HasOne(h => h.HabitSchedule)    // Mỗi Habit có một Schedule (hoặc không)
                  .WithOne(s => s.Habit)         // Mỗi Schedule thuộc về một Habit
                  .HasForeignKey<HabitSchedule>(s => s.HabitId) // Khóa ngoại là HabitId trong HabitSchedule
                  .OnDelete(DeleteBehavior.Cascade); // Xóa Schedule nếu Habit bị xóa
        });

        // Cấu hình HabitCompletion
        builder.Entity<HabitCompletion>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Notes).HasMaxLength(500);
            // entity.Property(e => e.CompletedAt).HasDefaultValueSql("GETUTCDATE()"); // Nên gán khi tạo

            // Relationship với Habit đã được cấu hình ở trên (WithMany(h => h.CompletionDates))
        });

        // Cấu hình HabitSchedule (Chỉ cần định nghĩa nếu có cấu hình đặc biệt, khóa ngoại đã được định nghĩa ở Habit)
        builder.Entity<HabitSchedule>(entity =>
        {
             entity.HasKey(e => e.Id);
             entity.Property(e => e.FrequencyType).IsRequired().HasMaxLength(20);
             entity.Property(e => e.DaysOfWeek).HasMaxLength(50); // Có thể null
             // Không cần cấu hình quan hệ lại ở đây vì đã làm ở Habit
        });


        // Cấu hình HabitNote
        builder.Entity<HabitNote>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Content).IsRequired().HasMaxLength(1000);
            entity.Property(e => e.Date).IsRequired().HasColumnType("date");
            // entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
            // entity.Property(e => e.UpdatedAt).HasDefaultValueSql("GETUTCDATE()");

            // Relationship với Habit
            entity.HasOne(e => e.Habit)
                .WithMany() // Habit có thể có nhiều Note (nhưng chỉ 1/ngày do unique index)
                .HasForeignKey(e => e.HabitId)
                .OnDelete(DeleteBehavior.Cascade); // Xóa Note nếu Habit bị xóa

            // Unique constraint: một thói quen chỉ có một ghi chú mỗi ngày
            entity.HasIndex(e => new { e.HabitId, e.Date })
                .IsUnique()
                .HasDatabaseName("IX_HabitNotes_HabitId_Date");
        });

        // Tạo indexes để tối ưu performance
        builder.Entity<Category>()
            .HasIndex(e => e.UserId);

        builder.Entity<Habit>()
            .HasIndex(e => e.UserId);

        builder.Entity<Habit>()
            .HasIndex(e => e.CategoryId);

        builder.Entity<HabitCompletion>()
            .HasIndex(e => e.HabitId);

        builder.Entity<HabitCompletion>()
            .HasIndex(e => e.CompletedAt);

         builder.Entity<HabitSchedule>() // Thêm Index cho HabitSchedule
            .HasIndex(e => e.HabitId);

        builder.Entity<HabitNote>()
            .HasIndex(e => e.HabitId);

        builder.Entity<HabitNote>()
            .HasIndex(e => e.Date);
    }
}