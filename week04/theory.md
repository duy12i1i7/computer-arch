Tuần 04 — Điều Khiển Luồng: Rẽ Nhánh, Vòng Lặp, So Sánh

Mục tiêu
- Viết cấu trúc `if/else`, `while/for`, `do/while` bằng MIPS.
- Sử dụng nhánh so sánh với 0 (`bgtz`, `bltz`, `bgez`, `blez`) và so sánh bằng/khác (`beq`, `bne`).
- Dùng lệnh đặt cờ quan hệ (`slt`, `slti`, kết hợp với `bne/beq`).

1) Lệnh nhánh cơ bản
- `beq rs, rt, label`: nhảy nếu bằng; `bne`: nếu khác.
- `bgtz rs, label`: > 0; `bltz`: < 0; `bgez`: ≥ 0; `blez`: ≤ 0.
- Offset nhánh I-type 16-bit (sign-extend), địa chỉ mục tiêu = `PC + 4 + (offset << 2)`.

2) Quan hệ tổng quát qua `slt/slti`
- `slt rd, rs, rt`: rd = 1 nếu rs < rt (có dấu); `sltu` cho không dấu.
- Dùng `beq/bne` với rd để nhảy theo quan hệ chung (>, <, ≥, ≤) bằng biến đổi đại số.

3) Cấu trúc if/else và nhánh rơi qua (fall-through)
- Mẫu: kiểm tra điều kiện → nếu sai, nhảy qua nhánh if → else (tuỳ chọn) → join.
- Tận dụng fall-through để giảm một nhánh.

4) Vòng lặp
- `while`: đầu vòng kiểm tra điều kiện, nhảy ra nếu sai.
- `do/while`: thân chạy trước, cuối vòng kiểm tra điều kiện nhảy ngược lên.
- `for`: ánh xạ thành khởi tạo → kiểm tra → thân → cập nhật → lặp.

5) Nhánh và pipeline
- Nhánh gây hazard điều khiển: đường ống có thể bơm sai lệnh; các kiến trúc dùng dự đoán/flush/delay slot.
- MIPS cổ điển có delay slot 1 lệnh (tuỳ mô phỏng), nên chèn lệnh vô hại (`nop`) hoặc có ích.

6) Mẫu so sánh hỗn hợp
- So sánh với hằng: `slti`, rồi nhánh theo kết quả.
- So sánh không dấu: `sltu/sltiu` tránh ký nghĩa dấu (offset/địa chỉ, số đếm wrap-around).

7) Advanced Control Flow Patterns

**Switch Statement Implementation:**
```assembly
# C code: switch(x) { case 1: ...; case 2: ...; default: ... }
# Jump table approach:
switch_stmt:
    # Check bounds first
    slti $t0, $a0, 1        # x < 1?
    bne $t0, $zero, default
    slti $t0, $a0, 3        # x < 3?  
    beq $t0, $zero, default
    
    # In bounds: use jump table
    addiu $a0, $a0, -1      # Convert to 0-based index
    sll $t0, $a0, 2         # Multiply by 4 (word size)
    la $t1, jump_table
    add $t0, $t1, $t0       # Address of jump target
    lw $t0, 0($t0)          # Load jump address
    jr $t0                  # Jump to handler

jump_table:
    .word case1, case2

case1:
    # Handle case 1
    j end_switch
case2:
    # Handle case 2  
    j end_switch
default:
    # Handle default case
end_switch:
```

**Nested Loop Optimization:**
```assembly
# for(i=0; i<100; i++) for(j=0; j<200; j++) array[i][j] = 0;
# Optimized version với loop unrolling
nested_loops:
    li $t0, 0               # i = 0
    la $t3, array           # Base address
outer_loop:
    li $t1, 0               # j = 0  
    sll $t4, $t0, 9         # i * 512 (200*4 bytes per row + padding)
    add $t5, $t3, $t4       # Address of array[i][0]
    
inner_loop:
    # Unroll by 4 to reduce branch overhead
    sw $zero, 0($t5)        # array[i][j] = 0
    sw $zero, 4($t5)        # array[i][j+1] = 0  
    sw $zero, 8($t5)        # array[i][j+2] = 0
    sw $zero, 12($t5)       # array[i][j+3] = 0
    
    addiu $t5, $t5, 16      # Move to next 4 elements
    addiu $t1, $t1, 4       # j += 4
    slti $t2, $t1, 200      # j < 200?
    bne $t2, $zero, inner_loop
    
    addiu $t0, $t0, 1       # i++
    slti $t2, $t0, 100      # i < 100?
    bne $t2, $zero, outer_loop
```

8) Branch Prediction và Optimization

**Static Branch Prediction:**
```assembly
# Compiler/programmer hints for better prediction
# Predict NOT TAKEN (fall-through more likely):
    beq $t0, $zero, rare_case    # Rare condition
    # Common path code here
    j continue
rare_case:
    # Rarely executed code
continue:

# Predict TAKEN (branch more likely):
    bne $t0, $zero, common_case  # Common condition
    # Rare path (fall-through)
    j continue  
common_case:
    # Frequently executed code
continue:
```

**Profile-Guided Optimization:**
```assembly
# Original code:
    beq $t0, $t1, label1
    # Path A (10% frequency)
    j end
label1:
    # Path B (90% frequency)
end:

# Optimized based on profile:
    bne $t0, $t1, label1    # Invert condition
    # Path B (90% - now fall-through)
    j end
label1:  
    # Path A (10% - now taken branch)
end:
```

9) Complex Conditional Expressions

**Short-Circuit Evaluation:**
```assembly
# C: if (a && b && c) { ... }
# Short-circuit AND:
    beq $t0, $zero, end_if  # if (!a) skip
    beq $t1, $zero, end_if  # if (!b) skip  
    beq $t2, $zero, end_if  # if (!c) skip
    # All conditions true - execute then block
    # ... then block code ...
end_if:

# C: if (a || b || c) { ... }
# Short-circuit OR:
    bne $t0, $zero, then_block  # if (a) execute
    bne $t1, $zero, then_block  # if (b) execute
    bne $t2, $zero, then_block  # if (c) execute
    j end_if                    # All false - skip
then_block:
    # ... then block code ...
end_if:
```

**Complex Comparisons:**
```assembly
# C: if (a < b && c > d) { ... }
    slt $t3, $t0, $t1       # $t3 = (a < b)
    beq $t3, $zero, end_if  # if (!(a < b)) skip
    slt $t3, $t3, $t2       # $t3 = (d < c), reuse $t3
    beq $t3, $zero, end_if  # if (!(c > d)) skip
    # Both conditions true
    # ... then block code ...
end_if:
```

10) Function Call Patterns

**Tail Call Optimization:**
```assembly
# C: return function_b(x);
# Normal call:
normal_call:
    jal function_b
    # Return with result already in $v0
    jr $ra

# Tail call optimized:
tail_call:
    # Set up arguments in $a0-$a3
    j function_b            # Jump directly (not jal)
    # function_b will return to our caller
```

**Computed Goto (Function Pointers):**
```assembly
# C: (*func_ptr)(args);
computed_call:
    lw $t0, func_ptr        # Load function address
    jalr $t0                # Call through register
    # Result in $v0

# Jump table for function dispatch:
dispatch_table:
    .word func1, func2, func3, func4

dispatch:
    sll $t0, $a0, 2         # Index * 4
    la $t1, dispatch_table
    add $t0, $t1, $t0
    lw $t0, 0($t0)          # Load function address
    jr $t0                  # Jump to function
```

11) Loop Transformations

**Loop Unrolling:**
```assembly
# Original loop:
original_loop:
    beq $t0, $zero, end
    # Loop body
    addiu $t0, $t0, -1
    j original_loop
end:

# Unrolled by 4:
unrolled_loop:
    slti $t1, $t0, 4        # Less than 4 iterations left?
    bne $t1, $zero, cleanup
    
    # Process 4 iterations at once
    # Loop body (iteration 1)
    # Loop body (iteration 2)  
    # Loop body (iteration 3)
    # Loop body (iteration 4)
    
    addiu $t0, $t0, -4      # Decrement by 4
    j unrolled_loop

cleanup:
    beq $t0, $zero, end     # Handle remaining iterations
    # Original loop body
    addiu $t0, $t0, -1
    j cleanup
end:
```

**Loop Fusion:**
```assembly
# Original: two separate loops
# for(i=0; i<n; i++) a[i] = b[i] + c[i];
# for(i=0; i<n; i++) d[i] = a[i] * 2;

# Fused version:
fused_loop:
    beq $t0, $zero, end
    
    sll $t1, $t0, 2         # i * 4
    add $t2, $t5, $t1       # &b[i]
    add $t3, $t6, $t1       # &c[i]  
    add $t4, $t7, $t1       # &a[i]
    add $t8, $t9, $t1       # &d[i]
    
    lw $t2, 0($t2)          # b[i]
    lw $t3, 0($t3)          # c[i]
    add $t2, $t2, $t3       # b[i] + c[i]
    sw $t2, 0($t4)          # a[i] = b[i] + c[i]
    
    sll $t2, $t2, 1         # a[i] * 2
    sw $t2, 0($t8)          # d[i] = a[i] * 2
    
    addiu $t0, $t0, -1
    j fused_loop
end:
```

12) Error Handling và Exception Patterns

**Bounds Checking:**
```assembly
array_access:
    # Check lower bound
    bltz $a1, bounds_error  # index < 0?
    
    # Check upper bound  
    lw $t0, array_size
    slt $t1, $a1, $t0       # index < size?
    beq $t1, $zero, bounds_error
    
    # Safe to access
    la $t0, array
    sll $t1, $a1, 2         # index * 4
    add $t0, $t0, $t1
    lw $v0, 0($t0)          # Load array[index]
    jr $ra

bounds_error:
    # Handle error (return error code, exception, etc.)
    li $v0, -1              # Error code
    jr $ra
```

**Null Pointer Checking:**
```assembly
safe_dereference:
    beq $a0, $zero, null_error  # Check for null
    lw $v0, 0($a0)              # Safe to dereference
    jr $ra

null_error:
    li $v0, -1                  # Error indicator
    jr $ra
```

13) Advanced Branch Techniques

**Branch Delay Slot Utilization:**
```assembly
# Without delay slot usage:
    beq $t0, $t1, target
    nop                     # Wasted slot

# With useful instruction in delay slot:
    beq $t0, $t1, target
    addiu $t2, $t2, 1       # This executes regardless

# Branch likely (if available):
    beql $t0, $t1, target   # Branch likely
    addiu $t2, $t2, 1       # Only executes if branch taken
```

**Conditional Move Emulation:**
```assembly
# C: result = (condition) ? a : b;
# Without conditional move:
    beq $t0, $zero, else_part
    move $v0, $t1           # result = a
    j end_if
else_part:
    move $v0, $t2           # result = b  
end_if:

# Emulated conditional move (branchless):
    sltu $t3, $zero, $t0    # $t3 = (condition != 0)
    subu $t4, $t1, $t2      # $t4 = a - b
    mul $t4, $t4, $t3       # $t4 = (a - b) * condition
    add $v0, $t2, $t4       # result = b + (a - b) * condition
```

14) Performance Analysis

**Branch Penalty Calculation:**
```
# Assume 5-stage pipeline, 2-cycle branch penalty
Original code: 1000 instructions, 200 branches, 50% taken
CPI = 1 + (200 branches * 0.5 taken * 2 penalty) / 1000
    = 1 + 200/1000 = 1.2

Optimized: reduce branches to 150, same taken rate  
CPI = 1 + (150 * 0.5 * 2) / 1000 = 1.15
Speedup = 1.2/1.15 = 1.043 (4.3% improvement)
```

**Loop Overhead Analysis:**
```assembly
# Simple loop overhead:
loop:
    # 10 instructions of actual work
    addiu $t0, $t0, -1      # 1 instruction overhead
    bne $t0, $zero, loop    # 1 instruction overhead
    
# Overhead = 2/12 = 16.7% of total instructions

# Unrolled by 4:
unrolled:
    # 40 instructions of actual work  
    addiu $t0, $t0, -4      # 1 instruction overhead
    bne $t0, $zero, unrolled # 1 instruction overhead
    
# Overhead = 2/42 = 4.8% of total instructions
# Reduction in overhead = 16.7% - 4.8% = 11.9%
```

15) Debugging Control Flow

**Common Branch Bugs:**
```assembly
# BUG: Off-by-one error
loop:
    # Process array[i]
    addiu $t0, $t0, 1       # i++
    slt $t1, $t0, $t2       # i < size?
    bne $t1, $zero, loop    # Wrong: should be bne
    # This misses the last element!

# FIXED:
loop:
    # Process array[i]  
    addiu $t0, $t0, 1       # i++
    slt $t1, $t0, $t2       # i < size?
    bne $t1, $zero, loop    # Correct
```

**Branch Target Verification:**
```assembly
# Use labels instead of addresses for maintainability
# BAD:
    beq $t0, $t1, 0x00400020    # Hard-coded address

# GOOD:  
    beq $t0, $t1, target_label  # Symbolic label
target_label:
    # Code here
```

16) Control Flow Graph Analysis

**Basic Block Identification:**
```assembly
# Basic Block 1: (no branches in/out except at ends)
main:
    li $t0, 0
    li $t1, 10
    
# Basic Block 2:
loop:
    slt $t2, $t0, $t1
    beq $t2, $zero, end     # Branch out
    
# Basic Block 3:  
    addiu $t0, $t0, 1
    j loop                  # Branch out
    
# Basic Block 4:
end:
    jr $ra
```

**Dead Code Elimination:**
```assembly
# Original:
    beq $t0, $t1, target
    li $t2, 100             # Dead code if branch always taken
    addiu $t3, $t3, 1       # Dead code
target:
    # Continue here

# After optimization:
    beq $t0, $t1, target    # If provably always taken
    # Dead instructions removed
target: 
    # Continue here
```

17) High-Level Language Mappings

**For Loop Variants:**
```assembly
# C: for(int i=start; i<end; i+=step)
# Count-up loop:
    move $t0, $a0           # i = start
    move $t1, $a1           # end
    move $t2, $a2           # step
for_loop:
    slt $t3, $t0, $t1       # i < end?
    beq $t3, $zero, end_for
    # Loop body
    add $t0, $t0, $t2       # i += step
    j for_loop
end_for:

# Count-down optimization (if step is constant):
# for(int i=n; i>0; i--)
    move $t0, $a0           # i = n
countdown:
    beq $t0, $zero, end     # More efficient than slt
    # Loop body
    addiu $t0, $t0, -1      # i--
    j countdown
end:
```

**While vs Do-While:**
```assembly
# while(condition) { body }
while_loop:
    # Test condition first
    beq $t0, $zero, end_while
    # Loop body
    j while_loop
end_while:

# do { body } while(condition)  
do_while:
    # Loop body first
    bne $t0, $zero, do_while    # Test at end
```

Kết luận nâng cao
Điều khiển luồng trong MIPS không chỉ là việc ánh xạ trực tiếp từ high-level constructs. Hiểu sâu về branch behavior, prediction, và optimization techniques giúp:

1. **Viết code hiệu quả hơn**: Giảm branch misprediction penalty
2. **Debug tốt hơn**: Hiểu được assembly generated từ compiler
3. **Optimize performance**: Loop unrolling, fusion, branch elimination
4. **Understand pipeline impact**: Branch hazards và cách minimize
5. **Design better algorithms**: Với awareness về branch costs

Những techniques này đặc biệt quan trọng trong embedded systems, real-time applications, và performance-critical code where every cycle counts.

