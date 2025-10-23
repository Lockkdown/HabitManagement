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
    public DbSet<Category> Categories { get; set; }

    /// <summary>
    /// DbSet cho thói quen.
    /// </summary>
    public DbSet<Habit> Habits { get; set; }

    /// <summary>
    /// DbSet cho lần hoàn thành thói quen.
    /// </summary>
    public DbSet<HabitCompletion> HabitCompletions { get; set; }

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
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
            entity.Property(e => e.UpdatedAt).HasDefaultValueSql("GETUTCDATE()");

            // Relationship với User
            entity.HasOne(e => e.User)
                  .WithMany()
                  .HasForeignKey(e => e.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
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
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
            entity.Property(e => e.UpdatedAt).HasDefaultValueSql("GETUTCDATE()");

            // Relationship với User
            entity.HasOne(e => e.User)
                  .WithMany()
                  .HasForeignKey(e => e.UserId)
                  .OnDelete(DeleteBehavior.Cascade);

            // Relationship với Category
            entity.HasOne(e => e.Category)
                  .WithMany(c => c.Habits)
                  .HasForeignKey(e => e.CategoryId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        // Cấu hình HabitCompletion
        builder.Entity<HabitCompletion>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Notes).HasMaxLength(500);
            entity.Property(e => e.CompletedAt).HasDefaultValueSql("GETUTCDATE()");

            // Relationship với Habit
            entity.HasOne(e => e.Habit)
                  .WithMany(h => h.Completions)
                  .HasForeignKey(e => e.HabitId)
                  .OnDelete(DeleteBehavior.Cascade);
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
    }
}
