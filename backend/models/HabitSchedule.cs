using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace backend.Models
{
    /// <summary>
    /// Bảng HabitSchedule mô tả lịch lặp lại của một thói quen.
    /// Dùng để xác định thói quen xuất hiện vào những ngày nào trong lịch.
    /// Mối quan hệ Một-Một với Habit.
    /// </summary>
    public class HabitSchedule
    {
        [Key]
        public int Id { get; set; }

        // Liên kết với bảng Habit (Khóa ngoại cho quan hệ 1-1)
        [Required]
        // [ForeignKey("Habit")] // ForeignKey attribute thường dùng cho quan hệ 1-nhiều, có thể bỏ ở đây nếu dùng Fluent API
        public int HabitId { get; set; }

        /// <summary>
        /// Loại chu kỳ lặp: "Daily", "Weekly", "Monthly".
        /// </summary>
        [Required]
        [StringLength(20)]
        public string FrequencyType { get; set; } = "Daily"; // Giữ nguyên chữ hoa để khớp IsDateInSchedule

        /// <summary>
        /// Khoảng cách giữa các lần lặp.
        /// - Daily: số ngày (1 = mỗi ngày, 2 = cách ngày)
        /// - Weekly: số tuần (1 = mỗi tuần) - Thường là 1
        /// - Monthly: số tháng (1 = mỗi tháng) - Thường là 1
        /// </summary>
        [Range(1, 365)]
        public int FrequencyValue { get; set; } = 1;

        /// <summary>
        /// Nếu loại là Weekly, dùng để chỉ định những ngày trong tuần thực hiện.
        /// Ví dụ: "Mon,Wed,Fri" (Thứ 2, 4, 6 theo chuẩn ISO đã thống nhất)
        /// </summary>
        [StringLength(50)]
        public string? DaysOfWeek { get; set; } // Đã là string? (nullable)

        // ==========================================================
        // <<< SỬA ĐỔI TẠI ĐÂY >>>
        // ==========================================================
        /// <summary>
        /// Nếu loại là Monthly, dùng để chỉ định các ngày trong tháng (1–31).
        /// Ví dụ: "1,15,30" (Lưu dưới dạng chuỗi)
        /// </summary>
        [StringLength(100)] // Cho phép lưu nhiều ngày (vd: "1,2,3...31")
        public string? DaysOfMonth { get; set; } // <<< SỬA: Từ int DayOfMonth thành string? DaysOfMonth
        // ==========================================================
    
        /// <summary>
        /// Cho biết lịch này có đang được kích hoạt hay không.
        /// </summary>
        public bool IsActive { get; set; } = true;

        // Navigation Property: kết nối ngược về Habit (cho quan hệ 1-1)
        public virtual Habit Habit { get; set; } = null!;
    }
}