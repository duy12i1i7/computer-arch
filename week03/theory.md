Tuần 03 — Định Dạng Lệnh MIPS (R/I/J), ISA và Thanh Ghi

Mục tiêu
- Hiểu định dạng bit-level của các loại lệnh R/I/J.
- Nắm vai trò opcode, rs/rt/rd, shamt, funct, immediate, target.
- Phân biệt lệnh gốc và lệnh giả; quan hệ với assembler.

1) Tổng quan mã lệnh 32-bit
- Mỗi lệnh MIPS dài 32 bit, cấu trúc cố định theo loại.
- Thiết kế này tối ưu pipeline và giải mã phần cứng.

2) Định dạng R-type (Register)
- Trường: `opcode(6) | rs(5) | rt(5) | rd(5) | shamt(5) | funct(6)`.
- `opcode` của R-type thường bằng 0; `funct` xác định phép cụ thể (add, sub, and, or, slt...).
- `shamt` dùng cho dịch bit (sll, srl, sra); còn lại thường 0.

3) Định dạng I-type (Immediate)
- Trường: `opcode(6) | rs(5) | rt(5) | immediate(16)`.
- Dùng cho lệnh có hằng số 16-bit và load/store, branch: `addi`, `ori`, `lw`, `sw`, `beq`, `bne`, ...
- Immediate có thể được sign-extend (ví dụ `addi`, `lw/sw`) hoặc zero-extend (ví dụ `andi/ori/xori`).

4) Định dạng J-type (Jump)
- Trường: `opcode(6) | target(26)`.
- Địa chỉ nhảy tính từ `PC[31:28] : target << 2`. Phân mảnh 4-byte căn chỉnh do lệnh 32-bit.
- `j` (nhảy không điều kiện), `jal` (nhảy và lưu `$ra`).

5) Pseudo-instruction và ánh xạ
- `move rd, rs` → `addu rd, rs, $zero`.
- `li rt, imm32` → có thể là `addi` (nếu vừa 16-bit) hoặc `lui`+`ori`.
- `la rt, label` → thường `lui`+`ori` dựa trên địa chỉ nhãn.

6) Thanh ghi và quy ước sử dụng
- Mặc dù có thể dùng tên số `$0..$31`, nên dùng tên ABI để rõ vai trò.
- Lệnh nhảy/trở về: `jal` lưu địa chỉ trở về vào `$ra`; `jr $ra` để quay lại.

7) Nhãn, địa chỉ, và liên hệ với linker/loader (mô phỏng)
- Trong MARS/QtSPIM, nhãn ánh xạ trực tiếp sang địa chỉ bộ nhớ mô phỏng.
- Pseudo `la` dựa vào địa chỉ nhãn, assembler chèn `lui/ori` phù hợp.

8) Ảnh hưởng định dạng tới pipeline
- Lệnh R-type dùng nhiều nguồn thanh ghi → phụ thuộc dữ liệu; I-type với `lw` tạo hazard `lw-use`.
- J-type thay đổi luồng điều khiển → hazard điều khiển; các kỹ thuật dự đoán/điền chỗ trống (delay slot) là chủ đề pipeline.

9) Chi tiết Instruction Encoding Examples

**R-Type Example: `add $t0, $t1, $t2`**
```
Binary: 000000 01001 01010 01000 00000 100000
Hex: 0x012A4020

Breakdown:
- opcode = 000000 (6 bits) = 0x00
- rs = 01001 (5 bits) = 9 ($t1)  
- rt = 01010 (5 bits) = 10 ($t2)
- rd = 01000 (5 bits) = 8 ($t0)
- shamt = 00000 (5 bits) = 0
- funct = 100000 (6 bits) = 0x20 (ADD)
```

**I-Type Example: `lw $t0, 8($sp)`**
```
Binary: 100011 11101 01000 0000000000001000  
Hex: 0x8FA80008

Breakdown:
- opcode = 100011 (6 bits) = 0x23 (LW)
- rs = 11101 (5 bits) = 29 ($sp)
- rt = 01000 (5 bits) = 8 ($t0)  
- immediate = 0000000000001000 (16 bits) = 8
```

**J-Type Example: `j 0x00400020`** 
```
Binary: 000010 00000001000000000000001000
Hex: 0x08100008

Breakdown:
- opcode = 000010 (6 bits) = 0x02 (J)
- target = 00000001000000000000001000 (26 bits) = 0x100008
- Actual address = (PC[31:28] << 28) | (target << 2)
```

10) Complete MIPS Instruction Reference

**R-Type Instructions (opcode = 0x00):**
| funct | Mnemonic | Operation |
|-------|----------|-----------|
| 0x20  | add      | rd = rs + rt (với overflow) |
| 0x21  | addu     | rd = rs + rt (không overflow) |
| 0x22  | sub      | rd = rs - rt (với overflow) |  
| 0x23  | subu     | rd = rs - rt (không overflow) |
| 0x24  | and      | rd = rs & rt |
| 0x25  | or       | rd = rs \| rt |
| 0x26  | xor      | rd = rs ^ rt |
| 0x27  | nor      | rd = ~(rs \| rt) |
| 0x2A  | slt      | rd = (rs < rt) ? 1 : 0 |
| 0x2B  | sltu     | rd = (rs < rt) ? 1 : 0 (unsigned) |
| 0x00  | sll      | rd = rt << shamt |
| 0x02  | srl      | rd = rt >> shamt (logic) |
| 0x03  | sra      | rd = rt >> shamt (arithmetic) |
| 0x04  | sllv     | rd = rt << rs |
| 0x06  | srlv     | rd = rt >> rs (logic) |
| 0x07  | srav     | rd = rt >> rs (arithmetic) |
| 0x08  | jr       | PC = rs |
| 0x09  | jalr     | $ra = PC+4; PC = rs |
| 0x18  | mult     | HI:LO = rs * rt (signed) |
| 0x19  | multu    | HI:LO = rs * rt (unsigned) |
| 0x1A  | div      | LO = rs/rt; HI = rs%rt (signed) |
| 0x1B  | divu     | LO = rs/rt; HI = rs%rt (unsigned) |
| 0x10  | mfhi     | rd = HI |
| 0x12  | mflo     | rd = LO |
| 0x11  | mthi     | HI = rs |
| 0x13  | mtlo     | LO = rs |

**I-Type Instructions:**
| opcode | Mnemonic | Operation |
|--------|----------|-----------|
| 0x08   | addi     | rt = rs + imm (signed) |
| 0x09   | addiu    | rt = rs + imm (unsigned) |
| 0x0C   | andi     | rt = rs & (zero_ext)imm |
| 0x0D   | ori      | rt = rs \| (zero_ext)imm |
| 0x0E   | xori     | rt = rs ^ (zero_ext)imm |
| 0x0A   | slti     | rt = (rs < imm) ? 1 : 0 |
| 0x0B   | sltiu    | rt = (rs < imm) ? 1 : 0 (unsigned) |
| 0x0F   | lui      | rt = imm << 16 |
| 0x23   | lw       | rt = mem[rs + imm] |
| 0x21   | lh       | rt = (signed)mem[rs + imm] |
| 0x25   | lhu      | rt = (unsigned)mem[rs + imm] |
| 0x20   | lb       | rt = (signed)mem[rs + imm] |
| 0x24   | lbu      | rt = (unsigned)mem[rs + imm] |
| 0x2B   | sw       | mem[rs + imm] = rt |
| 0x29   | sh       | mem[rs + imm] = rt[15:0] |
| 0x28   | sb       | mem[rs + imm] = rt[7:0] |
| 0x04   | beq      | if(rs==rt) PC += imm<<2 |
| 0x05   | bne      | if(rs!=rt) PC += imm<<2 |
| 0x06   | blez     | if(rs<=0) PC += imm<<2 |
| 0x07   | bgtz     | if(rs>0) PC += imm<<2 |
| 0x01   | bltz/bgez| Xem regimm field |

**J-Type Instructions:**
| opcode | Mnemonic | Operation |
|--------|----------|-----------|
| 0x02   | j        | PC = (PC[31:28]<<28)\|(target<<2) |
| 0x03   | jal      | $ra=PC+4; PC=(PC[31:28]<<28)\|(target<<2) |

11) Pseudo-Instructions chi tiết

**Load Immediate 32-bit:**
```assembly
# li $t0, 0x12345678
# Expands to:
lui $t0, 0x1234         # Load upper 16 bits
ori $t0, $t0, 0x5678    # OR in lower 16 bits

# li $t0, 0x00001234  
# Expands to:
ori $t0, $zero, 0x1234  # Simple immediate fits in 16 bits

# li $t0, 0xFFFF8000
# Expands to:  
addiu $t0, $zero, -32768 # Sign extension works correctly
```

**Load Address:**
```assembly
# la $t0, label
# If label is in data segment (0x10010000):
lui $t0, 0x1001         # Upper 16 bits of address
ori $t0, $t0, 0x0000    # Lower 16 bits (if 0)

# Or using addiu if lower 16 bits have sign bit set:
lui $t0, 0x1001
addiu $t0, $t0, offset  # Sign-extends properly
```

**Move Instruction:**
```assembly
# move $t0, $t1
# Expands to:
addu $t0, $t1, $zero    # Add with zero (or can use OR)
```

**Branch Greater Than:**
```assembly
# bgt $t0, $t1, label
# Expands to:
slt $at, $t1, $t0       # $at = 1 if $t1 < $t0
bne $at, $zero, label   # Branch if not equal to zero
```

12) Address Calculation Details

**PC-Relative Addressing (Branches):**
```
Effective Address = PC + 4 + (sign_extend(offset) << 2)

Example: beq $t0, $t1, loop
If PC = 0x00400020, offset = -4 (0xFFFC in 16-bit)
EA = 0x00400020 + 4 + (0xFFFFFFFC << 2)
   = 0x00400024 + 0xFFFFFFF0  
   = 0x00400014
```

**Jump Target Calculation:**
```
Jump Address = (PC+4)[31:28] || target || 00

Example: j 0x00100000
If PC = 0x00400020
Jump Address = 0x0 || 0x100000 || 00 = 0x00400000

Note: Can only jump within 256MB region!
```

13) Instruction Pipeline Impact

**R-Type Pipeline Stages:**
- **IF**: Fetch instruction from I-Cache
- **ID**: Decode opcode/funct, read rs/rt registers  
- **EX**: Perform ALU operation
- **MEM**: No memory access (pass through)
- **WB**: Write result to rd register

**Load Pipeline Stages:**
- **IF**: Fetch lw instruction
- **ID**: Decode, read base register (rs)
- **EX**: Calculate effective address (rs + offset)
- **MEM**: Access D-Cache, read data
- **WB**: Write loaded data to rt register

**Branch Pipeline Stages:**
- **IF**: Fetch branch instruction
- **ID**: Decode, read rs/rt registers, compare
- **EX**: Calculate branch target address  
- **MEM**: No memory access
- **WB**: Update PC if branch taken

14) Encoding Ambiguities và Special Cases

**Register $zero đặc biệt:**
```assembly
add $zero, $t0, $t1     # Legal but $zero remains 0
sw $zero, 0($sp)        # Store constant 0 to memory
```

**Shift Amount Encoding:**
```assembly
sll $t0, $t1, 0         # No-op (shift by 0)
sll $t0, $t1, 31        # Maximum shift amount
# shamt field chỉ 5 bits → maximum shift = 31
```

**Immediate Value Interpretation:**
```assembly
addi $t0, $zero, 0x8000  # $t0 = 0xFFFF8000 (sign-extended!)
addiu $t0, $zero, 0x8000 # $t0 = 0xFFFF8000 (same result!)
ori $t0, $zero, 0x8000   # $t0 = 0x00008000 (zero-extended)
```

15) Assembler Implementation Details

**Symbol Table Management:**
```
Label → Address mapping:
main:     0x00400000
loop:     0x00400010  
data1:    0x10010000
buffer:   0x10010020
```

**Two-Pass Assembly:**
- **Pass 1**: Build symbol table, determine addresses
- **Pass 2**: Generate machine code, resolve references

**Relocation Entries:**
```
For instruction: lw $t0, data1
- Store placeholder in machine code
- Create relocation entry: (address, symbol, type)
- Linker resolves during final link phase
```

16) Instruction Set Extensions

**MIPS32 Release 2 additions:**
- `seb/seh`: Sign-extend byte/halfword
- `ins/ext`: Insert/extract bit fields
- `rotr/rotrv`: Rotate right
- Conditional moves: `movn/movz`

**Example with newer instructions:**
```assembly
# Extract bits [15:8] using ext (if available)
ext $t1, $t0, 8, 8      # Extract 8 bits starting at bit 8

# Insert bits using ins (if available)  
ins $t0, $t1, 8, 8      # Insert $t1[7:0] into $t0[15:8]
```

17) Debugging Instruction Encoding

**Common Assembly Errors:**
```assembly
# ERROR: Wrong register in wrong field
add $t0, 100, $t1       # Can't have immediate in rs field!

# ERROR: Immediate too large
addi $t0, $t1, 0x10000  # 16-bit immediate overflow!

# ERROR: Mismatched instruction format
beq $t0, $t1, 100       # Branch target should be label

# CORRECT versions:
addi $t0, $t1, 100      # Immediate in correct position
lui $t2, 0x0001
ori $t0, $t2, 0x0000    # Load large constant properly
beq $t0, $t1, label     # Use label for branch target
```

18) Advanced Encoding Topics

**Instruction Aliases:**
```assembly
# Multiple ways to encode same operation:
move $t0, $t1           → addu $t0, $t1, $zero
move $t0, $t1           → or $t0, $t1, $zero

nop                     → sll $zero, $zero, 0
nop                     → add $zero, $zero, $zero

clear $t0               → add $t0, $zero, $zero
clear $t0               → or $t0, $zero, $zero
```

**Assembler Optimizations:**
```assembly
# Assembler may optimize:
li $t0, 0               → move $t0, $zero
addi $t0, $zero, 5      → ori $t0, $zero, 5 (if positive)
```

19) Cross-Platform Considerations

**Endianness trong Instruction Encoding:**
- Instruction encoding is fixed regardless of data endianness
- Instructions are always stored in big-endian format in specifications
- But implementation may store differently in memory

**ABI Compatibility:**
- O32 ABI: Original 32-bit calling convention
- N32/N64 ABI: For 64-bit MIPS
- Different register usage conventions

20) Performance Optimization via Instruction Selection

**Strength Reduction:**
```assembly
# Multiply by constant powers of 2:
# Instead of: mult $t0, $t1; mflo $t0  (where $t1 = 8)
sll $t0, $t0, 3         # Shift left by 3 (multiply by 8)

# Divide by power of 2:
# Instead of: div $t0, $t1; mflo $t0   (where $t1 = 4)  
sra $t0, $t0, 2         # Arithmetic shift right by 2
```

**Address Calculation Optimization:**
```assembly
# Array indexing: addr = base + index * 4
# Slow way:
sll $t1, $t1, 2         # index *= 4
add $t0, $t0, $t1       # base + index*4

# Better: combine using scale+base addressing mode if available
# MIPS doesn't have scaled addressing, so above is optimal
```

Kết luận nâng cao
Hiểu sâu về instruction encoding không chỉ giúp debug assembly code hiệu quả mà còn là nền tảng để hiểu pipeline behavior, cache performance, và compiler optimization. Knowledge này đặc biệt quan trọng khi:
- Viết performance-critical code
- Debug compiler-generated assembly
- Implement emulators hoặc simulators
- Làm việc với embedded systems có memory constraints
- Optimize instruction cache utilization

MIPS instruction format được thiết kế cẩn thận để balance giữa simplicity (dễ decode) và functionality (đủ expressive power), tạo nền tảng cho high-performance pipeline implementations.

