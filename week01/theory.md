Tuần 01 — Tổng Quan Kiến Trúc MIPS và Mô Hình Lập Trình

Mục tiêu
- Hiểu triết lý RISC và đặc trưng ISA của MIPS.
- Nắm mô hình lập trình: thanh ghi, bộ nhớ, không gian lệnh.
- Nhận diện cú pháp cơ bản, phân đoạn `.data`/`.text`, nhãn và lệnh giả.
- Làm quen công cụ MARS/QtSPIM, quy trình assemble–run.

1) Triết lý RISC và MIPS ISA
- RISC (Reduced Instruction Set Computer) ưu tiên tập lệnh đơn giản, độ dài lệnh cố định, đường ống dễ tối ưu.
- MIPS (Microprocessor without Interlocked Pipeline Stages) là một ISA RISC điển hình: lệnh 32-bit, load/store, số thanh ghi đa dạng.
- Đường ống 5 giai đoạn cổ điển: IF, ID, EX, MEM, WB, là cơ sở phân tích hiệu năng.

2) Mô hình lập trình MIPS
- Thanh ghi đa dụng: 32 thanh ghi 32-bit: `$0..$31` với các tên quy ước: `$zero, $at, $v0-$v1, $a0-$a3, $t0-$t7, $s0-$s7, $t8-$t9, $k0-$k1, $gp, $sp, $fp, $ra`.
- Nguyên tắc load/store: phép toán số học/logic chỉ hoạt động trên thanh ghi; truy cập bộ nhớ dùng `lw`, `sw`, `lb`, `sb`, ...
- Không gian địa chỉ phẳng 32-bit trong mô phỏng; bộ nhớ văn bản (.text) chứa lệnh, dữ liệu (.data/.bss) chứa biến.

3) Cú pháp và phân đoạn chương trình
- `.data`: khai báo dữ liệu tĩnh (hằng, chuỗi, mảng). Ví dụ: `.asciiz`, `.word`, `.space`.
- `.text`: mã lệnh, nơi đặt điểm vào `main:` (MARS/QtSPIM mặc định tìm nhãn `main`).
- Nhãn (label) để định vị lệnh/dữ liệu; dùng trong nhảy, rẽ nhánh, hoặc địa chỉ dữ liệu.
- Lệnh giả (pseudo-instruction) do assembler mở rộng (ví dụ `move`, `li`, `la`), ánh xạ sang 1+ lệnh gốc.

4) Chu trình biên dịch/assemble/liên kết/mô phỏng
- Trên MARS/QtSPIM: nạp mã `.s` → assemble (dịch) → nạp vào bộ nhớ mô phỏng → chạy/đặt breakpoint.
- Không có bước liên kết phức tạp như hệ thống thực, nhưng cần phân đoạn đúng và nhãn nhất quán.

5) Quy ước thanh ghi (ABI tinh gọn)
- `$zero`: luôn 0; ghi vào bị bỏ qua.
- `$v0-$v1`: giá trị trả về hàm; `$a0-$a3`: 4 tham số đầu.
- `$t0-$t9`: caller-saved (tạm), `$s0-$s7`: callee-saved (bảo toàn qua lời gọi hàm).
- `$sp`: stack pointer; `$fp`/`$s8`: frame pointer (tuỳ chọn); `$ra`: return address.

6) Cú pháp lệnh cơ bản
- Số học/logic: `add/sub/and/or/xor/slt` hoạt động trên thanh ghi.
- Tức thời (immediate): `addi/ori/xori/slti` với hằng 16-bit (ký hiệu thập lục phân: `0x...`).
- Tải/lưu: `lw/sw` (word), `lh/lhu`, `lb/lbu` (sign/zero-extend), địa chỉ hoá base+offset: `lw $t0, 8($sp)`.
- Điều khiển: `beq/bne` (so sánh bằng/khác), `bgtz/blez/bltz/bgez` (quan hệ với 0), `j/jal/jr` (nhảy/tới hàm/quay lại).

7) Bộ nhớ, căn chỉnh, endianness (giới thiệu)
- Căn chỉnh word (4 byte) giúp truy cập hiệu quả; truy cập lệch hàng có thể bị cấm hoặc chậm.
- Endianness: MARS/QtSPIM giả lập little-endian thường gặp; cần hiểu khi đọc/ghi byte/word.

8) Lệnh giả thông dụng và ánh xạ
- `li $t0, 100` → có thể thành `addi` hoặc `lui`+`ori` tuỳ hằng.
- `la $t0, label` → thường `lui`+`ori` hoặc `addi` với `$gp`.
- `move $t0, $t1` → ánh xạ `addu $t0, $t1, $zero`.

9) Chuẩn hoá cấu trúc chương trình
- Template cơ bản:
```assembly
.data
    # Khai báo dữ liệu tĩnh
    msg: .asciiz "Hello World\n"
    array: .word 1, 2, 3, 4, 5
    buffer: .space 100

.text
.globl main
main:
    # Prologue (nếu cần)
    addiu $sp, $sp, -8
    sw $ra, 4($sp)
    sw $fp, 0($sp)
    move $fp, $sp
    
    # Mã chương trình chính
    
    # Epilogue
    move $sp, $fp
    lw $fp, 0($sp)
    lw $ra, 4($sp)
    addiu $sp, $sp, 8
    jr $ra
```

10) Chi tiết về Thanh ghi và ABI MIPS
- **$zero ($0)**: Hằng số 0, không thể ghi đè
- **$at ($1)**: Reserved cho Assembler, không dùng trong code người dùng
- **$v0-$v1 ($2-$3)**: Giá trị trả về từ hàm, syscall codes
- **$a0-$a3 ($4-$7)**: 4 tham số đầu tiên của hàm
- **$t0-$t7 ($8-$15)**: Caller-saved temporary registers  
- **$s0-$s7 ($16-$23)**: Callee-saved saved registers
- **$t8-$t9 ($24-$25)**: Thêm 2 temporary registers
- **$k0-$k1 ($26-$27)**: Reserved cho kernel/OS
- **$gp ($28)**: Global Pointer (trỏ tới vùng dữ liệu tĩnh)
- **$sp ($29)**: Stack Pointer (đỉnh stack)
- **$fp/$s8 ($30)**: Frame Pointer (tuỳ chọn)
- **$ra ($31)**: Return Address (địa chỉ trở về)

11) Chi tiết về Instruction Set Architecture (ISA)
MIPS32 có khoảng 60+ lệnh cơ bản, chia thành các nhóm:
- **Arithmetic/Logic**: add, addu, sub, subu, and, or, xor, nor, slt, sltu
- **Immediate**: addi, addiu, andi, ori, xori, slti, sltiu
- **Shift**: sll, srl, sra, sllv, srlv, srav
- **Load/Store**: lw, lh, lhu, lb, lbu, sw, sh, sb
- **Branch**: beq, bne, bgtz, blez, bltz, bgez
- **Jump**: j, jal, jr, jalr
- **Multiply/Divide**: mult, multu, div, divu, mfhi, mflo
- **Coprocessor**: mfc0, mtc0 (truy cập CP0)

12) Đặc điểm RISC so với CISC
**RISC (MIPS) advantages:**
- Lệnh đơn giản, thời gian thực thi dự đoán được
- Pipeline dễ thiết kế và tối ưu hóa
- Decode nhanh do format cố định
- Nhiều thanh ghi (32 GPR)
- Load/Store architecture tách biệt memory access

**CISC (x86) so sánh:**
- Lệnh phức tạp, độ dài thay đổi
- Addressing modes đa dạng
- Ít thanh ghi hơn nhưng mạnh hơn
- Memory-to-memory operations

13) Thiết kế Pipeline 5-stage cổ điển
MIPS được thiết kế đặc biệt để hỗ trợ pipeline hiệu quả:
- **IF (Instruction Fetch)**: Lấy lệnh từ I-Cache, PC+4
- **ID (Instruction Decode)**: Decode opcode, đọc register file
- **EX (Execute)**: ALU operations, branch resolution
- **MEM (Memory)**: D-Cache access cho load/store
- **WB (Write Back)**: Ghi kết quả về register file

14) Memory Model và Address Space
```
0xFFFFFFFF ┌─────────────┐
           │   Kernel    │
0x80000000 ├─────────────┤
           │    Stack    │ ← $sp
           │      ↓      │
           │             │
           │      ↑      │
           │    Heap     │ ← sbrk()
0x10010000 ├─────────────┤
           │    Data     │ ← .data, .bss
0x10000000 ├─────────────┤
           │    Text     │ ← .text
0x00400000 ├─────────────┤
           │  Reserved   │
0x00000000 └─────────────┘
```

15) Endianness và Byte Ordering
MIPS hỗ trợ cả Little và Big Endian, nhưng MARS mặc định Little Endian:
```
Word: 0x12345678
Address: 0x1000

Little Endian:    Big Endian:
0x1000: 0x78      0x1000: 0x12
0x1001: 0x56      0x1001: 0x34  
0x1002: 0x34      0x1002: 0x56
0x1003: 0x12      0x1003: 0x78
```

16) Alignment và Performance
- Words (4 bytes) phải align tại địa chỉ chia hết cho 4
- Halfwords (2 bytes) align tại địa chỉ chẵn  
- Misaligned access có thể gây exception hoặc performance penalty
- Compiler thường thêm padding để đảm bảo alignment

17) Assembler Directives
- **.align n**: Căn chỉnh tại boundary 2^n
- **.ascii**: Chuỗi không có null terminator
- **.asciiz**: Chuỗi có null terminator
- **.byte**: 8-bit values
- **.half**: 16-bit values  
- **.word**: 32-bit values
- **.space n**: Reserve n bytes
- **.globl label**: Make label globally visible
- **.eqv name, value**: Define symbolic constant

18) Linking và Loading Process
Mặc dù MARS/SPIM đơn giản hóa, quá trình thực tế bao gồm:
1. **Assembly**: .s → .o (object file với symbol table)
2. **Linking**: Kết hợp multiple .o files, resolve symbols
3. **Loading**: OS nạp executable vào memory, setup stack/heap
4. **Execution**: Jump to entry point (main)

19) Debugging và Profiling
MARS cung cấp nhiều tool debug:
- **Breakpoints**: Dừng tại địa chỉ/label cụ thể
- **Step execution**: Chạy từng lệnh
- **Memory viewer**: Xem nội dung memory real-time
- **Register viewer**: Monitor register values
- **Syscall tracer**: Theo dõi system calls

20) Performance Considerations từ Assembly Level
- **Instruction selection**: Chọn lệnh hiệu quả nhất
- **Register allocation**: Tối ưu việc sử dụng registers
- **Memory layout**: Organize data cho cache efficiency
- **Branch prediction**: Minimize mispredicted branches
- **Instruction scheduling**: Avoid pipeline hazards

Kết luận nâng cao
MIPS ISA được thiết kế với triết lý "simple is better", nhưng đơn giản không có nghĩa là không mạnh mẽ. Architecture này đã chứng minh khả năng scale từ embedded systems đến supercomputers. Hiểu sâu về MIPS giúp nắm bắt fundamental principles áp dụng cho mọi modern processor architecture.
- Khởi điểm `main:` rõ ràng; tách dữ liệu `.data` và logic `.text`.
- Đặt nhãn, comment tiếng Việt rõ ràng; dùng quy ước tên thanh ghi ABI.

Kết luận
- Tuần này đặt nền cho lập trình MIPS: triết lý RISC, mô hình thanh ghi/bộ nhớ, cú pháp và công cụ. Tuần sau đi sâu biểu diễn dữ liệu và tác động tới lệnh tải/lưu, dấu, và mở rộng.

