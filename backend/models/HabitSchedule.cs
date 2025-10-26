using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace backend.Models
{
    /// <summary>
    /// Bảng HabitSchedule mô tả lịch lặp lại của một thói quen.
    /// Dùng để xác định thói quen xuất hiện vào những ngày nào trong lịch (Daily, Weekly, Monthly...).
    /// </summary>
    public class HabitSchedule
    {
        [Key]
        public int Id { get; set; }

        // Liên kết với bảng Habit (1 Habit có thể có nhiều cấu hình lịch)
        [Required]
        [ForeignKey("Habit")]
        public int HabitId { get; set; }

        /// <summary>
        /// Loại chu kỳ lặp: "Daily", "Weekly", "Monthly".
        /// Daily  -> Lặp mỗi X ngày.
        /// Weekly -> Lặp vào các ngày cố định trong tuần.
        /// Monthly -> Lặp vào một ngày cố định trong tháng.
        /// </summary>
        [Required]
        [StringLength(20)]
        public string FrequencyType { get; set; } = "Daily";

        /// <summary>
        /// Khoảng cách giữa các lần lặp.
        /// - Với Daily: số ngày giữa các lần thực hiện (1 = mỗi ngày, 2 = cách 2 ngày, 3 = cách 3 ngày...)
        /// - Với Weekly: số tuần giữa các chu kỳ (1 = mỗi tuần, 2 = cách 2 tuần)
        /// - Với Monthly: số tháng giữa các chu kỳ (1 = mỗi tháng, 2 = cách 2 tháng)
        /// </summary>
        [Range(1, 365)]
        public int FrequencyValue { get; set; } = 1;

        /// <summary>
        /// Nếu loại là Weekly, dùng để chỉ định những ngày trong tuần thực hiện.
        /// Ví dụ: "Mon,Wed,Fri" (Thứ 2, 4, 6)
        /// Nếu không phải Weekly, có thể để trống.
        /// </summary>
        [StringLength(50)]
        public string DaysOfWeek { get; set; } = string.Empty;

        /// <summary>
        /// Nếu loại là Monthly, dùng để chỉ định ngày trong tháng (1–31).
        /// Nếu không phải Monthly, có thể để trống hoặc = 0.
        /// </summary>
        [Range(0, 31)]
        public int DayOfMonth { get; set; }

        /// <summary>
        /// Cho biết lịch này có đang được kích hoạt hay không.
        /// Dùng khi người dùng tạm dừng một thói quen.
        /// </summary>
        public bool IsActive { get; set; } = true;

        // Navigation Property: kết nối ngược về Habit
        public virtual Habit Habit { get; set; } = null!;
    }
}
