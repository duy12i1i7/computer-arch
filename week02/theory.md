Tuần 02 — Biểu Diễn Dữ Liệu, Bù-2, Endianness, Căn Chỉnh

Mục tiêu
- Hiểu biểu diễn nhị phân, thập lục phân, và ánh xạ sang thanh ghi/bộ nhớ.
- Nắm số có dấu (bù-2), không dấu, phát hiện tràn.
- Phân biệt sign-extend vs zero-extend; tác động của `lb/lbu`, `lh/lhu`.
- Hiểu endianness và căn chỉnh bộ nhớ khi load/store.

1) Biểu diễn nhị phân và cơ số 16
- Nhị phân: cơ số 2; mỗi bit 0/1. Thập lục phân: cơ số 16 (0..F) cô đọng 4 bit.
- Ví dụ: `0xFF` = `1111 1111` = 255 (không dấu). Khi diễn giải có dấu (bù-2), `0xFF` đại diện -1 (8-bit).
- Chuyển đổi: dùng nhóm nibble (4 bit) ↔ 1 hex.

2) Số có dấu — Bù-2 (Two’s complement)
- Với N-bit, miền không dấu: [0 .. 2^N - 1]; miền có dấu: [-2^(N-1) .. 2^(N-1) - 1].
- Bù-2 của x: đảo bit (one’s complement) rồi cộng 1. Ví dụ: +5 (8-bit) = 0000 0101; -5 = 1111 1011.
- Phép cộng/trừ có dấu khớp với phần cứng cộng nhị phân; phát hiện tràn có dấu khi hai toán hạng cùng dấu, kết quả khác dấu.

3) Sign extension và Zero extension
- Load byte/ký tự có dấu: `lb` (sign-extend lên 32-bit); không dấu: `lbu` (zero-extend).
- Load halfword: `lh` vs `lhu`; tương tự sign/zero-extend.
- Immediate 16-bit trong `addi/ori`… có thể sign-extend (tuỳ lệnh), ảnh hưởng khi kết hợp `lui`/`ori` để nạp hằng 32-bit.

4) Endianness
- Little-endian: byte có trọng số thấp ở địa chỉ thấp (x86, MIPS mô phỏng thường là little).
- Big-endian: byte có trọng số cao ở địa chỉ thấp (một số hệ thống mạng/nhúng cũ).
- Khi đọc/ghi byte/half/word bằng địa chỉ cụ thể, phải nhất quán endianness.

5) Căn chỉnh bộ nhớ (Alignment)
- Word (4 byte) thường yêu cầu địa chỉ bội số của 4 để truy cập hiệu quả.
- Truy cập lệch (misaligned) có thể gây exception hoặc bị giả lập chậm.
- Tổ chức struct/array nên cân nhắc căn chỉnh để tối ưu băng thông bộ nhớ/đường ống.

6) Lệnh tải/lưu và phạm vi hằng số
- `lw/sw` (word), `lh/lhu`, `lb/lbu`, `sh/sb` (store half/byte). Địa chỉ hiệu dụng: `base + offset` (offset 16-bit có dấu).
- `addi` sign-extend 16-bit; để nạp hằng 32-bit: `lui` (nạp 16-bit cao), sau đó `ori`/`addi` nạp 16-bit thấp.
- `andi/ori/xori` dùng zero-extend cho immediate.

7) Tràn (Overflow)
- Phép cộng/trừ có dấu: `add/sub` gây exception khi tràn; biến thể không kiểm tra tràn `addu/subu` dùng cho không dấu hoặc khi bỏ qua tràn.
- Nhân/chia: đặt kết quả 64-bit trong HI/LO; tràn được lưu ở miền rộng hơn.

8) Ảnh hưởng tới thiết kế lệnh và hiệu năng
- Tách biệt có dấu/không dấu cho phép phần cứng đơn giản (RISC), điều khiển qua đường dữ liệu sign/zero-extend.
- Căn chỉnh phù hợp giúp giảm chu kỳ truy cập và xung đột pipeline/bộ nhớ.

9) Floating Point Representation (IEEE 754) - Khái niệm
Mặc dù MIPS32 có coprocessor riêng cho FPU, nhưng hiểu cơ bản về IEEE 754:
```
Single Precision (32-bit):
Sign(1) | Exponent(8) | Mantissa(23)

Double Precision (64-bit):  
Sign(1) | Exponent(11) | Mantissa(52)
```

10) Advanced Two's Complement Operations
**Phát hiện tràn trong phép cộng có dấu:**
```assembly
# Kiểm tra tràn khi cộng $t0 và $t1
add $t2, $t0, $t1    # Có thể gây exception nếu tràn
# Hoặc dùng addu và kiểm tra manual:
addu $t2, $t0, $t1
# Check: nếu sign($t0) = sign($t1) != sign($t2) → overflow
```

**Mở rộng dấu manual:**
```assembly
# Sign extend 16-bit value trong $t0 lên 32-bit
sll $t0, $t0, 16    # Dịch lên 16 bit cao
sra $t0, $t0, 16    # Dịch về, sign extend
```

11) Bit Manipulation Techniques
**Bitmask operations:**
```assembly
# Set bit n: x |= (1 << n)
li $t1, 1
sll $t1, $t1, n     # $t1 = 1 << n  
or $t0, $t0, $t1    # $t0 |= (1 << n)

# Clear bit n: x &= ~(1 << n)
li $t1, 1
sll $t1, $t1, n     # $t1 = 1 << n
nor $t1, $t1, $zero # $t1 = ~(1 << n)
and $t0, $t0, $t1   # $t0 &= ~(1 << n)

# Toggle bit n: x ^= (1 << n)
li $t1, 1
sll $t1, $t1, n
xor $t0, $t0, $t1

# Test bit n: if (x & (1 << n))
li $t1, 1
sll $t1, $t1, n
and $t2, $t0, $t1   # $t2 = 0 nếu bit n = 0
```

12) Memory Layout và Alignment chi tiết
**Alignment rules:**
- `char` (1 byte): Alignment = 1
- `short` (2 bytes): Alignment = 2  
- `int/float` (4 bytes): Alignment = 4
- `long long/double` (8 bytes): Alignment = 8
- `struct`: Alignment = max(alignment của các member)

**Padding example:**
```c
struct example {
    char c;     // offset 0, size 1
    // 3 bytes padding
    int i;      // offset 4, size 4  
    char d;     // offset 8, size 1
    // 3 bytes padding để struct size = 12 (multiple of 4)
};
```

13) Endianness trong thực tế
**Network Byte Order:**
- Network protocols dùng Big Endian ("Network Byte Order")
- Functions: `htonl()`, `htons()`, `ntohl()`, `ntohs()`

**MIPS Endianness Configuration:**
- MIPS architecture hỗ trợ cả hai
- Bit CP0.Status.RE (Reverse Endian) để switch
- Trong MARS: luôn Little Endian

**Endian Conversion Example:**
```assembly
# Swap bytes trong word $t0 (32-bit endian conversion)
# Input: $t0 = 0x12345678
# Output: $t0 = 0x78563412

andi $t1, $t0, 0xFF     # $t1 = 0x78
sll $t1, $t1, 24        # $t1 = 0x78000000

srl $t2, $t0, 8
andi $t2, $t2, 0xFF     # $t2 = 0x56  
sll $t2, $t2, 16        # $t2 = 0x00560000

srl $t3, $t0, 16
andi $t3, $t3, 0xFF     # $t3 = 0x34
sll $t3, $t3, 8         # $t3 = 0x00003400

srl $t4, $t0, 24        # $t4 = 0x12

or $t0, $t1, $t2
or $t0, $t0, $t3  
or $t0, $t0, $t4        # $t0 = 0x78563412
```

14) Character Encoding và String Handling
**ASCII vs Extended ASCII:**
- ASCII: 7-bit (0-127), Standard characters
- Extended ASCII: 8-bit (0-255), Various code pages
- Unicode: UTF-8, UTF-16, UTF-32 (không hỗ trợ trực tiếp trong MIPS32)

**String operations example:**
```assembly
# String length (strlen equivalent)
strlen:
    move $v0, $zero     # length = 0
    move $t0, $a0       # ptr = string
loop:
    lb $t1, 0($t0)      # load byte
    beq $t1, $zero, done
    addiu $v0, $v0, 1   # length++
    addiu $t0, $t0, 1   # ptr++
    j loop
done:
    jr $ra
```

15) Số học modular và Overflow Handling
**Unsigned arithmetic:**
```assembly
# Unsigned addition với carry detection
addu $t2, $t0, $t1
sltu $t3, $t2, $t0      # carry = (sum < operand1)

# Unsigned comparison
sltu $t3, $t0, $t1      # $t3 = 1 if $t0 < $t1 (unsigned)
```

**Multiplication overflow detection:**
```assembly
# Kiểm tra overflow trong phép nhân signed
mult $t0, $t1
mflo $t2                # Low 32-bit
mfhi $t3                # High 32-bit

# Nếu $t2 >= 0: overflow nếu $t3 != 0
# Nếu $t2 < 0: overflow nếu $t3 != -1
```

16) Bitfield Operations
**Extract bitfield:**
```assembly
# Extract bits [high:low] từ $t0
# Ví dụ: extract bits [15:8] 
srl $t1, $t0, 8         # Shift right by low bit position
andi $t1, $t1, 0xFF     # Mask to keep only desired bits
```

**Insert bitfield:**
```assembly
# Insert value $t1 vào bits [15:8] của $t0
andi $t1, $t1, 0xFF     # Ensure value fits
sll $t1, $t1, 8         # Shift to position
lui $t2, 0xFFFF
ori $t2, $t2, 0x00FF    # Create mask 0xFFFF00FF
and $t0, $t0, $t2       # Clear target bits
or $t0, $t0, $t1        # Insert new value
```

17) Memory Access Patterns và Performance
**Sequential vs Random Access:**
```assembly
# Sequential access (cache-friendly)
la $t0, array
li $t1, 1000
loop1:
    lw $t2, 0($t0)      # Load từ địa chỉ hiện tại
    # Process $t2
    addiu $t0, $t0, 4   # Next element
    addiu $t1, $t1, -1
    bnez $t1, loop1

# Strided access (có thể cache-unfriendly)
la $t0, array
li $t1, 100
li $t3, 40              # Stride = 40 bytes
loop2:
    lw $t2, 0($t0)      # Load element
    # Process $t2  
    add $t0, $t0, $t3   # Jump by stride
    addiu $t1, $t1, -1
    bnez $t1, loop2
```

18) Load/Store Variants chi tiết
**Sign vs Zero Extension:**
```assembly
# Assume memory tại 0x1000 chứa byte 0xFF

lbu $t0, 0x1000($zero)  # $t0 = 0x000000FF (zero-extend)
lb $t0, 0x1000($zero)   # $t0 = 0xFFFFFFFF (sign-extend)

# Tương tự cho halfword
lhu $t0, 0x1000($zero)  # Zero-extend 16→32 bit
lh $t0, 0x1000($zero)   # Sign-extend 16→32 bit
```

19) Debugging Data Representation
**Common mistakes:**
```assembly
# SAI: Quên sign extension
li $t0, 0x8000          # $t0 = 0xFFFF8000 (sign-extended!)

# ĐÚNG: Dùng ori cho upper 16-bit có bit 15 set
lui $t0, 0x0000
ori $t0, $t0, 0x8000    # $t0 = 0x00008000

# SAI: Alignment violation
la $t0, byte_array
lw $t1, 1($t0)          # Misaligned word access!

# ĐÚNG: Load aligned hoặc dùng byte access
la $t0, byte_array
lbu $t1, 1($t0)         # Load single byte
lbu $t2, 2($t0)
lbu $t3, 3($t0)
lbu $t4, 4($t0)
# Manually combine if needed
```

20) Advanced Topics và Optimization
**Bit counting algorithms:**
```assembly
# Population count (số bit 1 trong word)
popcount:
    move $v0, $zero     # count = 0
    move $t0, $a0       # copy input
loop:
    beq $t0, $zero, done
    addiu $v0, $v0, 1   # count++
    addiu $t1, $t0, -1  # $t1 = $t0 - 1
    and $t0, $t0, $t1   # Clear lowest set bit
    j loop
done:
    jr $ra
```

**Fast division by constants:**
```assembly
# Divide by 3 using multiplication
# x/3 ≈ (x * 0xAAAAAAAB) >> 33 (cho unsigned 32-bit)
# Simplified version for small numbers:
div_by_3:
    # Use shift và subtract cho power-of-2 gần nhất
    srl $t0, $a0, 2     # x/4 (underestimate)
    srl $t1, $a0, 4     # x/16  
    add $t0, $t0, $t1   # x/4 + x/16 = 5x/16
    srl $t1, $a0, 6     # x/64
    add $t0, $t0, $t1   # 5x/16 + x/64 = 21x/64
    # Continue series expansion...
```

Kết luận nâng cao
Biểu diễn dữ liệu không chỉ là lý thuyết mà ảnh hưởng trực tiếp đến hiệu năng và tính đúng đắn của chương trình. Hiểu sâu về bit-level operations, alignment, endianness và các techniques tối ưu hóa giúp viết code MIPS hiệu quả và portable. Những kiến thức này đặc biệt quan trọng khi làm việc với embedded systems, system programming, và performance-critical applications.

