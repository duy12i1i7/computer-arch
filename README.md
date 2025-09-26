Khung Môn Học: Kiến Trúc Máy Tính (MIPS)

Khung chương trình 12 tuần tập trung vào kiến trúc máy tính thông qua ngôn ngữ lắp ráp MIPS (MARS/SPIM). Mỗi tuần bao gồm:

- `theory.md`: Ghi chép lý thuyết chi tiết, chuyên sâu (chỉ lý thuyết)
- `example.s`: Ví dụ MIPS ngắn gọn minh họa đúng trọng tâm tuần

Bạn có thể duyệt theo thư mục `week01` → `week12`.

## Công cụ khuyến nghị
- MARS (MIPS Assembler and Runtime Simulator)
- Hoặc SPIM/QtSPIM

## Cách chạy ví dụ
- MARS: Mở file `example.s`, Assemble (`F3`), Run (`F5`).
- QtSPIM: File → Open `example.s`, sau đó Run.

## Lộ trình 12 tuần
- Week 01: Tổng quan MIPS, mô hình lập trình, công cụ
- Week 02: Biểu diễn dữ liệu, số bù 2, endianness, căn chỉnh bộ nhớ
- Week 03: Định dạng lệnh MIPS (R/I/J), ISA, thanh ghi
- Week 04: Điều khiển luồng: rẽ nhánh, vòng lặp, so sánh
- Week 05: Thủ tục, quy ước gọi hàm, stack frame
- Week 06: Bộ nhớ, địa chỉ hóa, mảng/chuỗi/cấu trúc
- Week 07: Số học và logic: cộng/trừ/nhân/chia, dịch bit, dấu
- Week 08: Pipeline cơ bản: các giai đoạn, mô hình thực thi
- Week 09: Hazards: data/control/structural; bypassing/forwarding
- Week 10: Phân cấp bộ nhớ: cache, locality, hit/miss, AMAT
- Week 11: Ngoại lệ/ngắt, syscall, kiểm soát đặc quyền
- Week 12: Hiệu năng: CPI, Amdahl, phân tích bottleneck

Lưu ý: Các file lý thuyết chỉ chứa nội dung lý thuyết; phần ví dụ chỉ nhằm minh họa ngắn gọn khái niệm tuần đó.
