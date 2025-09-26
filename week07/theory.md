Tuần 07 — Số Học và Logic: Cộng/Trừ/Nhân/Chia, Dịch Bit, Dấu

Mục tiêu
- Phân biệt lệnh có/không kiểm tra tràn: `add/sub` vs `addu/subu`.
- Hiểu nhân/chia 32-bit tạo kết quả 64-bit trong HI/LO.
- Nắm dịch số học vs logic: `sll/srl/sra` và ảnh hưởng bit dấu.
- Vận dụng bitwise `and/or/xor/nor`, thiết kế mặt nạ và thao tác bit.

1) Cộng/Trừ và tràn
- `add rd, rs, rt`: cộng có dấu, tràn → exception; `addu` cho không dấu (bỏ qua tràn).
- `sub/subu` tương tự cho trừ.
- Dùng `slt`/so sánh để tránh tràn trước khi cộng trong một số trường hợp.

2) Dịch bit
- `sll rd, rt, shamt`: dịch trái logic, thêm 0 ở phải; nhân 2^k.
- `srl`: dịch phải logic, thêm 0 ở trái; chia 2^k (không dấu).
- `sra`: dịch phải số học, sao chép bit dấu; chia 2^k làm tròn xuống đối với số âm.

3) Bitwise và mặt nạ
- `and`: lọc bit; `or`: đặt bit; `xor`: đảo bit chọn lọc; `nor`: phủ định của `or`.
- Mặt nạ: tạo bằng dịch/trừ/đảo; ví dụ: mask 8 bit thấp `0xFF`, đặt/clear bit.

4) Nhân/Chia và thanh ghi HI/LO
- `mult rs, rt`/`multu`: nhân 32×32 → 64-bit; `mfhi/mflo` để lấy cao/thấp.
- `div rs, rt`/`divu`: thương vào LO, dư vào HI.
- Pseudo `mul rd, rs, rt` có thể ánh xạ nhanh nếu kiến trúc hỗ trợ; bằng không là `mult/mflo`.

5) Dấu và mở rộng
- Kết hợp `sra` để khôi phục bit dấu khi dịch; chú ý khi tạo/ghép trường bit ký hiệu.
- Mở rộng có/không dấu khi tải từ bộ nhớ (tuần 2) ảnh hưởng tới số học tiếp theo.

6) Tối ưu số học
- Thay nhân/chia bội số 2 bằng dịch để giảm độ trễ.
- Dùng `addu` với `sll` để tính địa chỉ nhanh: `base + (i<<2)`.

7) Advanced Arithmetic Algorithms

**Fast Integer Division by Constants:**
```assembly
# Division by 3 using multiplication and shift
# Based on: x/3 ≈ (x * 0xAAAAAAAB) >> 33
div_by_3_fast:
    # $a0 = dividend, result in $v0
    # For 32-bit: use approximation x/3 ≈ (x + (x>>2) + (x>>4) + ...) >> 2
    
    move $t0, $a0           # x
    srl $t1, $t0, 2         # x >> 2
    add $t0, $t0, $t1       # x + (x >> 2) = x * 1.25
    
    srl $t1, $t0, 4         # (x * 1.25) >> 4
    add $t0, $t0, $t1       # x * 1.25 + (x * 1.25) >> 4
    
    srl $t1, $t0, 8         # Continue series
    add $t0, $t0, $t1
    
    srl $t1, $t0, 16
    add $t0, $t0, $t1
    
    srl $v0, $t0, 2         # Final shift
    
    # Correction for rounding
    move $t1, $v0
    sll $t2, $t1, 1         # quotient * 2
    add $t2, $t2, $t1       # quotient * 3
    sub $t3, $a0, $t2       # remainder = dividend - quotient * 3
    
    slti $t4, $t3, 3        # remainder < 3?
    bne $t4, $zero, div3_done
    addiu $v0, $v0, 1       # Adjust quotient
    
div3_done:
    jr $ra

# Optimized division by powers of 2 with proper rounding
div_by_power_of_2:
    # $a0 = dividend (signed), $a1 = power (0-31)
    # Proper signed division with rounding towards zero
    
    # Check if dividend is negative
    bltz $a0, negative_dividend
    
    # Positive dividend: simple right shift
    srav $v0, $a0, $a1
    jr $ra
    
negative_dividend:
    # For negative dividends: add (2^n - 1) before shifting
    li $t0, 1
    sllv $t0, $t0, $a1      # 2^n
    addiu $t0, $t0, -1      # 2^n - 1
    add $t1, $a0, $t0       # dividend + (2^n - 1)
    srav $v0, $t1, $a1      # Arithmetic shift right
    jr $ra
```

**Extended Precision Arithmetic:**
```assembly
# 64-bit addition using 32-bit operations
add64:
    # $a0,$a1 = first 64-bit number (low, high)
    # $a2,$a3 = second 64-bit number (low, high)  
    # Result: $v0,$v1 = sum (low, high)
    
    addu $v0, $a0, $a2      # Add low 32 bits
    sltu $t0, $v0, $a0      # Carry = (sum < operand1)
    
    addu $v1, $a1, $a3      # Add high 32 bits
    addu $v1, $v1, $t0      # Add carry from low part
    
    jr $ra

# 64-bit multiplication
mult64:
    # $a0,$a1 = first 64-bit number (low, high)
    # $a2,$a3 = second 64-bit number (low, high)
    # Result: $v0,$v1 = product (low, high) - truncated to 64 bits
    
    # Using formula: (a1*2^32 + a0) * (a3*2^32 + a2)
    # = a1*a3*2^64 + (a1*a2 + a0*a3)*2^32 + a0*a2
    # We ignore a1*a3*2^64 term (overflow beyond 64 bits)
    
    multu $a0, $a2          # a0 * a2
    mflo $v0                # Low part of result
    mfhi $t0                # High part of a0*a2
    
    multu $a0, $a3          # a0 * a3
    mflo $t1                # Low part of a0*a3
    
    multu $a1, $a2          # a1 * a2  
    mflo $t2                # Low part of a1*a2
    
    add $t1, $t1, $t2       # (a0*a3 + a1*a2)
    add $v1, $t0, $t1       # High part = hi(a0*a2) + (a0*a3 + a1*a2)
    
    jr $ra

# Square root using Newton-Raphson method
integer_sqrt:
    # $a0 = input, $v0 = floor(sqrt(input))
    beq $a0, $zero, sqrt_zero
    
    # Initial guess: roughly input/2, but at least 1
    srl $v0, $a0, 1         # x = input / 2
    ori $v0, $v0, 1         # Ensure x >= 1
    
sqrt_loop:
    move $t0, $v0           # old_x = x
    div $a0, $v0            # input / x
    mflo $t1                # quotient
    add $t2, $v0, $t1       # x + input/x
    srl $v0, $t2, 1         # new_x = (x + input/x) / 2
    
    # Check convergence: |new_x - old_x| <= 1
    sub $t3, $v0, $t0       # new_x - old_x
    abs $t3, $t3            # |new_x - old_x|
    slti $t4, $t3, 2        # |diff| < 2?
    beq $t4, $zero, sqrt_loop
    
    # Verify result and adjust if necessary  
    mul $t0, $v0, $v0       # x^2
    slt $t1, $a0, $t0       # input < x^2?
    bne $t1, $zero, sqrt_adjust_down
    
    addiu $t2, $v0, 1       # (x+1)
    mul $t3, $t2, $t2       # (x+1)^2
    slt $t4, $a0, $t3       # input < (x+1)^2?
    bne $t4, $zero, sqrt_done
    addiu $v0, $v0, 1       # Adjust up
    j sqrt_done
    
sqrt_adjust_down:
    addiu $v0, $v0, -1
    j sqrt_done
    
sqrt_zero:
    li $v0, 0
    
sqrt_done:
    jr $ra
```

8) Floating Point Emulation

**IEEE 754 Single Precision Operations:**
```assembly
# IEEE 754 format: Sign(1) | Exponent(8) | Mantissa(23)
# Bias = 127 for single precision

# Extract IEEE 754 components
ieee754_extract:
    # $a0 = IEEE 754 float value
    # Returns: $v0 = mantissa, $v1 = exponent, $a0 = sign
    
    move $t0, $a0           # Save original
    
    # Extract sign bit
    srl $a0, $t0, 31        # Sign = bit 31
    
    # Extract exponent  
    sll $t1, $t0, 1         # Shift out sign bit
    srl $v1, $t1, 24        # Extract exponent (bits 30-23)
    
    # Extract mantissa
    lui $t2, 0x007F         # Mask for mantissa
    ori $t2, $t2, 0xFFFF    # 0x007FFFFF
    and $v0, $t0, $t2       # Extract mantissa (bits 22-0)
    
    jr $ra

# Software floating point addition (simplified)
float_add_soft:
    # $a0 = first float, $a1 = second float
    addiu $sp, $sp, -32
    sw $ra, 28($sp)
    sw $s0, 24($sp)         # first operand components
    sw $s1, 20($sp)
    sw $s2, 16($sp)
    sw $s3, 12($sp)         # second operand components  
    sw $s4, 8($sp)
    sw $s5, 4($sp)
    sw $s6, 0($sp)          # working registers
    
    # Extract first operand
    jal ieee754_extract
    move $s0, $v0           # mantissa1
    move $s1, $v1           # exponent1
    move $s2, $a0           # sign1
    
    # Extract second operand
    move $a0, $a1
    jal ieee754_extract
    move $s3, $v0           # mantissa2
    move $s4, $v1           # exponent2
    move $s5, $a0           # sign2
    
    # Handle special cases (zero, infinity, NaN)
    beq $s1, $zero, first_zero
    beq $s4, $zero, second_zero
    
    # Add implicit leading 1 for normalized numbers
    lui $t0, 0x0080         # 0x00800000
    or $s0, $s0, $t0        # mantissa1 |= 0x00800000
    or $s3, $s3, $t0        # mantissa2 |= 0x00800000
    
    # Align mantissas by shifting smaller exponent
    sub $t1, $s1, $s4       # exp_diff = exp1 - exp2
    bgez $t1, first_larger
    
second_larger:
    # Second operand has larger exponent
    neg $t1, $t1            # |exp_diff|
    move $s6, $s4           # result_exp = exp2
    srlv $s0, $s0, $t1      # Shift mantissa1 right
    j mantissa_aligned
    
first_larger:
    # First operand has larger exponent  
    move $s6, $s1           # result_exp = exp1
    srlv $s3, $s3, $t1      # Shift mantissa2 right
    
mantissa_aligned:
    # Add or subtract mantissas based on signs
    xor $t0, $s2, $s5       # sign1 XOR sign2
    beq $t0, $zero, same_signs
    
different_signs:
    # Subtraction: larger - smaller
    slt $t1, $s0, $s3       # mantissa1 < mantissa2?
    beq $t1, $zero, sub_normal
    
    # mantissa2 > mantissa1: swap and negate result sign
    sub $s0, $s3, $s0       # result_mantissa = mantissa2 - mantissa1
    move $s2, $s5           # result_sign = sign2
    j normalize
    
sub_normal:
    sub $s0, $s0, $s3       # result_mantissa = mantissa1 - mantissa2
    # result_sign = sign1 (already in $s2)
    j normalize
    
same_signs:
    # Addition
    add $s0, $s0, $s3       # result_mantissa = mantissa1 + mantissa2
    # Check for overflow
    lui $t0, 0x0100         # 0x01000000
    and $t1, $s0, $t0
    beq $t1, $zero, normalize
    
    # Mantissa overflow: shift right and increment exponent
    srl $s0, $s0, 1
    addiu $s6, $s6, 1
    j normalize
    
normalize:
    # Remove implicit leading 1
    lui $t0, 0x007F
    ori $t0, $t0, 0xFFFF    # 0x007FFFFF
    and $s0, $s0, $t0
    
    # Pack result
    sll $t0, $s2, 31        # Sign bit
    sll $t1, $s6, 23        # Exponent bits
    or $v0, $t0, $t1        # Sign | Exponent
    or $v0, $v0, $s0        # | Mantissa
    
    j float_add_done
    
first_zero:
    move $v0, $a1           # Return second operand
    j float_add_done
    
second_zero:
    move $v0, $a0           # Return first operand
    
float_add_done:
    lw $s6, 0($sp)
    lw $s5, 4($sp)
    lw $s4, 8($sp)
    lw $s3, 12($sp)
    lw $s2, 16($sp)
    lw $s1, 20($sp)
    lw $s0, 24($sp)
    lw $ra, 28($sp)
    addiu $sp, $sp, 32
    jr $ra
```

9) Cryptographic Operations

**AES S-Box Implementation:**
```assembly
# AES S-Box lookup table (256 bytes)
.data
.align 2
aes_sbox:
    .byte 0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5
    .byte 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76
    .byte 0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0
    .byte 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0
    .byte 0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc
    .byte 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15
    .byte 0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a
    .byte 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75
    # ... (continue for all 256 bytes)

.text
# AES SubBytes transformation
aes_subbytes:
    # $a0 = pointer to 16-byte state array
    la $t0, aes_sbox        # S-box base address
    li $t1, 16              # 16 bytes to process
    move $t2, $a0           # Current byte pointer
    
subbytes_loop:
    beq $t1, $zero, subbytes_done
    lbu $t3, 0($t2)         # Load current byte
    add $t4, $t0, $t3       # &sbox[byte]
    lbu $t5, 0($t4)         # sbox[byte]
    sb $t5, 0($t2)          # Store substituted byte
    
    addiu $t2, $t2, 1       # Next byte
    addiu $t1, $t1, -1      # Decrement counter
    j subbytes_loop
    
subbytes_done:
    jr $ra

# 32-bit rotations for cryptographic operations
rotate_left:
    # $a0 = value, $a1 = rotation count
    # MIPS doesn't have rotate, emulate with shifts
    andi $a1, $a1, 31       # Rotation count mod 32
    sllv $t0, $a0, $a1      # Left shift
    li $t1, 32
    sub $t1, $t1, $a1       # 32 - rotation_count
    srlv $t2, $a0, $t1      # Right shift
    or $v0, $t0, $t2        # Combine
    jr $ra

rotate_right:
    # $a0 = value, $a1 = rotation count
    andi $a1, $a1, 31       # Rotation count mod 32
    srlv $t0, $a0, $a1      # Right shift
    li $t1, 32
    sub $t1, $t1, $a1       # 32 - rotation_count
    sllv $t2, $a0, $t1      # Left shift
    or $v0, $t0, $t2        # Combine
    jr $ra
```

10) Bit-level Optimization Techniques

**Population Count (Hamming Weight):**
```assembly
# Brian Kernighan's algorithm
popcount_kernighan:
    # $a0 = input value
    li $v0, 0               # count = 0
    
popcount_loop:
    beq $a0, $zero, popcount_done
    addiu $v0, $v0, 1       # count++
    addiu $t0, $a0, -1      # n - 1
    and $a0, $a0, $t0       # n = n & (n-1), clears lowest set bit
    j popcount_loop
    
popcount_done:
    jr $ra

# Parallel bit counting (faster for dense bit patterns)
popcount_parallel:
    # $a0 = input value
    move $t0, $a0
    
    # Step 1: count pairs
    srl $t1, $t0, 1         # n >> 1
    lui $t2, 0x5555         # 0x55555555
    ori $t2, $t2, 0x5555
    and $t1, $t1, $t2       # (n >> 1) & 0x55555555
    sub $t0, $t0, $t1       # n - ((n >> 1) & 0x55555555)
    
    # Step 2: count groups of 4
    srl $t1, $t0, 2         # temp >> 2
    lui $t2, 0x3333         # 0x33333333
    ori $t2, $t2, 0x3333
    and $t0, $t0, $t2       # temp & 0x33333333
    and $t1, $t1, $t2       # (temp >> 2) & 0x33333333
    add $t0, $t0, $t1       # (temp & 0x33333333) + ((temp >> 2) & 0x33333333)
    
    # Step 3: count groups of 8
    srl $t1, $t0, 4         # temp >> 4
    add $t0, $t0, $t1       # temp + (temp >> 4)
    lui $t2, 0x0F0F         # 0x0F0F0F0F
    ori $t2, $t2, 0x0F0F
    and $t0, $t0, $t2       # (temp + (temp >> 4)) & 0x0F0F0F0F
    
    # Step 4: sum all bytes
    lui $t1, 0x0101         # 0x01010101
    ori $t1, $t1, 0x0101
    mul $t0, $t0, $t1       # temp * 0x01010101
    srl $v0, $t0, 24        # (temp * 0x01010101) >> 24
    
    jr $ra

# Find first set bit (trailing zeros count)
find_first_set:
    # $a0 = input value, returns position of first set bit (0-31) or -1
    beq $a0, $zero, ffs_not_found
    
    # Use two's complement trick: n & (-n) isolates lowest set bit
    neg $t0, $a0            # -n
    and $t0, $a0, $t0       # n & (-n)
    
    # Convert isolated bit to position using DeBruijn sequence
    lui $t1, 0x077C         # 0x077CB531 (32-bit DeBruijn sequence)
    ori $t1, $t1, 0xB531
    mul $t0, $t0, $t1       # isolated_bit * debruijn
    srl $t0, $t0, 27        # >> 27 (32-5)
    
    # Lookup in DeBruijn table
    la $t2, debruijn_table
    add $t2, $t2, $t0
    lbu $v0, 0($t2)
    jr $ra
    
ffs_not_found:
    li $v0, -1
    jr $ra

.data
debruijn_table:
    .byte 0, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 25, 17, 4, 8
    .byte 31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9
```

11) SIMD Emulation

**Packed Byte Operations:**
```assembly
# Add 4 packed bytes simultaneously
packed_byte_add:
    # $a0, $a1 = two words containing 4 bytes each
    # Add corresponding bytes with saturation
    
    # Extract individual bytes from first operand
    andi $t0, $a0, 0xFF     # byte0
    srl $t1, $a0, 8
    andi $t1, $t1, 0xFF     # byte1
    srl $t2, $a0, 16
    andi $t2, $t2, 0xFF     # byte2
    srl $t3, $a0, 24        # byte3
    
    # Extract individual bytes from second operand
    andi $t4, $a1, 0xFF     # byte0
    srl $t5, $a1, 8
    andi $t5, $t5, 0xFF     # byte1
    srl $t6, $a1, 16
    andi $t6, $t6, 0xFF     # byte2
    srl $t7, $a1, 24        # byte3
    
    # Add with saturation
    add $s0, $t0, $t4       # sum0
    slti $s4, $s0, 256      # sum0 < 256?
    beq $s4, $zero, sat0
    j no_sat0
sat0:
    li $s0, 255             # Saturate to 255
no_sat0:
    
    add $s1, $t1, $t5       # sum1
    slti $s4, $s1, 256
    beq $s4, $zero, sat1
    j no_sat1
sat1:
    li $s1, 255
no_sat1:
    
    add $s2, $t2, $t6       # sum2
    slti $s4, $s2, 256
    beq $s4, $zero, sat2
    j no_sat2
sat2:
    li $s2, 255
no_sat2:
    
    add $s3, $t3, $t7       # sum3
    slti $s4, $s3, 256
    beq $s4, $zero, sat3
    j no_sat3
sat3:
    li $s3, 255
no_sat3:
    
    # Pack results back into word
    sll $s1, $s1, 8         # byte1 << 8
    sll $s2, $s2, 16        # byte2 << 16
    sll $s3, $s3, 24        # byte3 << 24
    
    or $v0, $s0, $s1        # byte0 | byte1
    or $v0, $v0, $s2        # | byte2
    or $v0, $v0, $s3        # | byte3
    
    jr $ra

# Horizontal sum of packed bytes
packed_byte_hsum:
    # $a0 = word containing 4 bytes
    # Returns sum of all 4 bytes
    
    andi $t0, $a0, 0xFF     # byte0
    srl $t1, $a0, 8
    andi $t1, $t1, 0xFF     # byte1
    srl $t2, $a0, 16
    andi $t2, $t2, 0xFF     # byte2
    srl $t3, $a0, 24        # byte3
    
    add $v0, $t0, $t1       # byte0 + byte1
    add $v0, $v0, $t2       # + byte2
    add $v0, $v0, $t3       # + byte3
    
    jr $ra
```

12) Performance Profiling

**Cycle Counter Implementation:**
```assembly
.data
cycle_count_high: .word 0
cycle_count_low: .word 0

.text
# Read performance counter (emulated)
read_cycle_counter:
    # In real MIPS, would use CP0 Count register
    # For simulation, use system call or manual counter
    
    lw $t0, cycle_count_low
    lw $t1, cycle_count_high
    
    addiu $t0, $t0, 1       # Increment low part
    sltu $t2, $t0, 1        # Check for overflow (wrap from 0xFFFFFFFF to 0)
    add $t1, $t1, $t2       # Add carry to high part
    
    sw $t0, cycle_count_low
    sw $t1, cycle_count_high
    
    move $v0, $t0           # Return low part
    move $v1, $t1           # Return high part
    jr $ra

# Benchmark arithmetic operations
benchmark_arithmetic:
    # Benchmark various arithmetic operations
    li $t0, 10000           # Iteration count
    
    # Benchmark addition
    jal read_cycle_counter
    move $s0, $v0           # Start time (low)
    move $s1, $v1           # Start time (high)
    
    li $t1, 0               # Loop counter
    li $t2, 123             # Operand 1
    li $t3, 456             # Operand 2
    
add_benchmark_loop:
    beq $t1, $t0, add_benchmark_done
    add $t4, $t2, $t3       # The operation being benchmarked
    addiu $t1, $t1, 1
    j add_benchmark_loop
    
add_benchmark_done:
    jal read_cycle_counter
    move $s2, $v0           # End time (low)
    move $s3, $v1           # End time (high)
    
    # Calculate elapsed cycles
    sub $v0, $s2, $s0       # Low part difference
    sub $v1, $s3, $s1       # High part difference
    # Handle borrow if needed
    slt $t5, $s2, $s0       # Did low part borrow?
    sub $v1, $v1, $t5       # Adjust high part
    
    # $v0,$v1 now contains total cycles for 10000 additions
    div $v0, $t0            # Cycles per operation
    mflo $v0                # Average cycles per addition
    
    jr $ra
```

Kết luận nâng cao
Arithmetic và logic operations trong MIPS assembly требuje understanding của:

1. **Hardware Limitations**: Overflow detection, signed vs unsigned semantics
2. **Algorithm Design**: Efficient implementations của complex operations  
3. **Bit Manipulation**: Cryptographic operations, SIMD emulation
4. **Performance Optimization**: Strength reduction, loop unrolling
5. **Numerical Precision**: Extended precision arithmetic, floating point emulation
6. **Profiling và Measurement**: Performance characterization

Key insights:
- **Assembly-level arithmetic** exposes hardware realities hidden by high-level languages
- **Bit manipulation techniques** are fundamental to systems programming và cryptography
- **Performance optimization** requires understanding of instruction costs và pipeline behavior
- **Extended precision arithmetic** enables applications beyond native word size
- **Profiling tools** essential for validating optimization effectiveness

Những techniques này critical trong:
- **Cryptographic Implementations**: AES, RSA, elliptic curve cryptography
- **Digital Signal Processing**: Audio/video processing, filtering
- **Scientific Computing**: High-precision numerical methods
- **Game Development**: 3D graphics, physics simulation  
- **Embedded Systems**: Resource-constrained arithmetic operations
- **Compiler Optimization**: Understanding target instruction costs

Mastery của low-level arithmetic operations là foundation для high-performance computing và system-level programming.

