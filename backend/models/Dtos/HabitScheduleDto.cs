using System.ComponentModel.DataAnnotations;

namespace backend.Models.Dtos
{
    /// <summary>
    /// DTO cho HabitSchedule mô tả lịch lặp lại của một thói quen.
    /// Dùng để xác định thói quen xuất hiện vào những ngày nào trong lịch (Daily, Weekly, Monthly...).
    /// </summary>
    public class HabitScheduleDto
    {
        public int Id { get; set; }
        
        public int HabitId { get; set; }

        /// <summary>
        /// Loại chu kỳ lặp: "Daily", "Weekly", "Monthly".
        /// </summary>
        [Required]
        [StringLength(20)]
        public string FrequencyType { get; set; } = "Daily";

        /// <summary>
        /// Khoảng cách giữa các lần lặp.
        /// </summary>
        [Range(1, 365)]
        public int FrequencyValue { get; set; } = 1;

        /// <summary>
        /// Nếu loại là Weekly, dùng để chỉ định những ngày trong tuần thực hiện.
        /// Ví dụ: "Mon,Wed,Fri"
        /// </summary>
        [StringLength(50)]
        public string? DaysOfWeek { get; set; } // Đã là string? (nullable)

        // ==========================================================
        // <<< SỬA ĐỔI TẠI ĐÂY >>>
        // ==========================================================
        /// <summary>
        /// Nếu loại là Monthly, dùng để chỉ định ngày trong tháng (1–31).
        /// Ví dụ: "1,15,30" (Lưu dưới dạng chuỗi)
        /// </summary>
        [StringLength(100)] // Cho phép lưu nhiều ngày (vd: "1,2,3...31")
        public string? DaysOfMonth { get; set; } // <<< SỬA: Từ int DayOfMonth thành string? DaysOfMonth
        // ==========================================================
        
        /// <summary>
        /// Cho biết lịch này có đang được kích hoạt hay không.
        /// </summary>
        public bool IsActive { get; set; } = true;
    }
}