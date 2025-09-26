Tuần 05 — Thủ Tục, Quy Ước Gọi Hàm, Stack Frame

Mục tiêu
- Hiểu quy ước ABI: truyền tham số, trả về, thanh ghi caller/callee-saved.
- Viết prologue/epilogue chuẩn; quản lý stack frame an toàn.
- Xây dựng hàm đệ quy, hàm không lá/đơn giản (leaf/non-leaf).

1) Quy ước thanh ghi cho lời gọi hàm
- Tham số: `$a0-$a3`; trả về: `$v0-$v1`.
- Caller-saved: `$t0-$t9` (người gọi tự lưu nếu cần bảo toàn).
- Callee-saved: `$s0-$s7`, `$fp`/`$s8`, `$gp` (người được gọi phải khôi phục trước khi trả về).
- `$ra`: địa chỉ trở về do `jal` thiết lập; phải lưu trên stack nếu hàm sẽ gọi hàm khác (non-leaf).

2) Stack và chiều tăng/giảm
- `$sp` trỏ đỉnh stack; stack thường tăng xuống (trừ dần địa chỉ).
- Mỗi hàm cấp phát stack frame: lưu `$ra`, các `$s*` cần bảo toàn, biến cục bộ.

3) Khuôn mẫu prologue/epilogue
- Prologue:
  - `addiu $sp, $sp, -FRAME_SIZE`
  - lưu `$ra`, các `$s*` cần dùng
  - (tùy chọn) thiết lập `$fp` = `$sp` + offset
- Epilogue:
  - khôi phục `$ra`, `$s*`
  - `addiu $sp, $sp, FRAME_SIZE`
  - `jr $ra`

4) Leaf vs Non-leaf
- Leaf: không gọi hàm khác → có thể không cần lưu `$ra` nếu chắc chắn không bị ghi đè.
- Non-leaf: sẽ gọi hàm khác → phải lưu `$ra`; có thể cần lưu `$a*` nếu tái sử dụng.

5) Truyền tham số vượt `$a0-$a3`
- Các tham số dư truyền qua stack theo ABI; người gọi đẩy lên trước khi `jal`.
- Người được gọi đọc từ stack frame qua offset từ `$sp`/`$fp`.

6) Biến cục bộ và tạm
- Dùng `$s*` cho biến sống dài qua lời gọi; `$t*` cho tạm thời ngắn hạn.
- Biến cục bộ dạng mảng/struct lớn đặt trên stack.

7) Đệ quy
- Mỗi lần gọi tạo stack frame mới với tham số, giá trị tạm, và `$ra` riêng.
- Cần điểm dừng rõ ràng để không tràn stack.

8) Tối ưu và an toàn
- Giảm kích thước frame; chỉ lưu những gì thực sự dùng.
- Kiểm soát tràn số/địa chỉ khi tính offset; luôn căn chỉnh nếu cần.

9) Advanced Stack Management

**Dynamic Stack Allocation:**
```assembly
# Allocate n bytes on stack at runtime
dynamic_alloc:
    # $a0 contains size to allocate
    # Align to 8-byte boundary
    addiu $a0, $a0, 7       # Add 7 for rounding
    li $t0, -8
    and $a0, $a0, $t0       # Clear lower 3 bits (align to 8)
    
    subu $sp, $sp, $a0      # Allocate space
    move $v0, $sp           # Return pointer to allocated space
    jr $ra

# Deallocate by restoring stack pointer
dynamic_free:
    # $a0 contains original $sp value to restore
    move $sp, $a0
    jr $ra
```

**Variable-Length Argument Lists:**
```assembly
# Function with variable arguments: func(int count, ...)
varargs_func:
    # Prologue
    addiu $sp, $sp, -32
    sw $ra, 28($sp)
    sw $fp, 24($sp)
    sw $s0, 20($sp)
    move $fp, $sp
    
    # $a0 = count, remaining args in $a1, $a2, $a3, then on stack
    move $s0, $a0           # Save count
    
    # Save register args to stack for uniform access
    sw $a1, 32($fp)         # First vararg
    sw $a2, 36($fp)         # Second vararg  
    sw $a3, 40($fp)         # Third vararg
    # Stack args already at 44($fp), 48($fp), ...
    
    # Process arguments
    li $t0, 0               # i = 0
    addiu $t1, $fp, 32      # ptr to first arg
varargs_loop:
    beq $t0, $s0, varargs_done
    lw $a0, 0($t1)          # Load current argument
    # Process argument in $a0
    addiu $t0, $t0, 1       # i++
    addiu $t1, $t1, 4       # Next argument
    j varargs_loop
varargs_done:
    
    # Epilogue
    move $sp, $fp
    lw $s0, 20($sp)
    lw $fp, 24($sp)
    lw $ra, 28($sp)
    addiu $sp, $sp, 32
    jr $ra
```

10) Complex Calling Conventions

**Passing Large Structures:**
```assembly
# C: struct large_struct func(struct large_struct arg);
# Structures larger than registers passed by reference

func_with_large_struct:
    # $a0 points to input struct
    # $a1 points to space for return struct
    
    # Copy input struct to local variable
    addiu $sp, $sp, -64     # Assume struct is 56 bytes + alignment
    move $t0, $sp           # Local struct address
    li $t1, 56              # Struct size
    
copy_loop:
    beq $t1, $zero, copy_done
    lw $t2, 0($a0)          # Load from source
    sw $t2, 0($t0)          # Store to destination
    addiu $a0, $a0, 4
    addiu $t0, $t0, 4
    addiu $t1, $t1, -4
    j copy_loop
copy_done:
    
    # Process struct...
    
    # Copy result to return location ($a1)
    move $t0, $sp           # Source (local struct)
    move $t1, $a1           # Destination (return space)
    li $t2, 56              # Size
    
return_copy:
    beq $t2, $zero, return_done
    lw $t3, 0($t0)
    sw $t3, 0($t1)
    addiu $t0, $t0, 4
    addiu $t1, $t1, 4
    addiu $t2, $t2, -4
    j return_copy
return_done:
    
    addiu $sp, $sp, 64      # Deallocate local struct
    jr $ra
```

**Function Pointers và Callbacks:**
```assembly
# Higher-order function: map(array, size, func_ptr)
map_function:
    # $a0 = array, $a1 = size, $a2 = function pointer
    addiu $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)         # Save array
    sw $s1, 12($sp)         # Save size
    sw $s2, 8($sp)          # Save function pointer
    sw $s3, 4($sp)          # Save counter
    
    move $s0, $a0           # array
    move $s1, $a1           # size
    move $s2, $a2           # function pointer
    li $s3, 0               # i = 0
    
map_loop:
    beq $s3, $s1, map_done
    
    # Calculate array[i] address
    sll $t0, $s3, 2         # i * 4
    add $t0, $s0, $t0       # &array[i]
    lw $a0, 0($t0)          # Load array[i]
    
    # Call function pointer
    jalr $s2                # Call function through pointer
    
    # Store result back (assuming function modifies the value)
    sll $t0, $s3, 2         # i * 4
    add $t0, $s0, $t0       # &array[i]
    sw $v0, 0($t0)          # array[i] = result
    
    addiu $s3, $s3, 1       # i++
    j map_loop
map_done:
    
    # Restore registers
    lw $s3, 4($sp)
    lw $s2, 8($sp)
    lw $s1, 12($sp)
    lw $s0, 16($sp)
    lw $ra, 20($sp)
    addiu $sp, $sp, 24
    jr $ra
```

11) Optimization Techniques

**Tail Call Optimization trong Detail:**
```assembly
# Original recursive function
factorial_normal:
    addiu $sp, $sp, -8
    sw $ra, 4($sp)
    sw $a0, 0($sp)
    
    slti $t0, $a0, 2        # n < 2?
    beq $t0, $zero, recursive_case
    
    # Base case: return 1
    li $v0, 1
    j factorial_return
    
recursive_case:
    addiu $a0, $a0, -1      # n - 1
    jal factorial_normal    # Recursive call
    
    # Multiply result by original n
    lw $t0, 0($sp)          # Original n
    mul $v0, $v0, $t0       # result * n
    
factorial_return:
    lw $ra, 4($sp)
    addiu $sp, $sp, 8
    jr $ra

# Tail-recursive version (accumulator)
factorial_tail:
    # $a0 = n, $a1 = accumulator
    slti $t0, $a0, 2
    bne $t0, $zero, factorial_tail_base
    
    # Tail recursive case
    mul $a1, $a1, $a0       # acc = acc * n
    addiu $a0, $a0, -1      # n = n - 1
    j factorial_tail        # Tail call (no jal!)
    
factorial_tail_base:
    move $v0, $a1           # Return accumulator
    jr $ra
```

**Register Window Emulation:**
```assembly
# Simulate register windows for deep call chains
# Use a software-managed register save area

.data
reg_save_area: .space 1024  # 32 registers * 8 levels * 4 bytes

.text
# Save current register window
save_registers:
    la $t0, reg_save_area
    lw $t1, current_level
    sll $t1, $t1, 7         # level * 128 bytes (32 regs * 4)
    add $t0, $t0, $t1       # Save area for this level
    
    # Save all $s registers
    sw $s0, 0($t0)
    sw $s1, 4($t0)
    sw $s2, 8($t0)
    sw $s3, 12($t0)
    sw $s4, 16($t0)
    sw $s5, 20($t0)
    sw $s6, 24($t0)
    sw $s7, 28($t0)
    
    # Increment level
    lw $t1, current_level
    addiu $t1, $t1, 1
    sw $t1, current_level
    jr $ra

# Restore register window
restore_registers:
    # Decrement level first
    lw $t1, current_level
    addiu $t1, $t1, -1
    sw $t1, current_level
    
    la $t0, reg_save_area
    sll $t1, $t1, 7         # level * 128 bytes
    add $t0, $t0, $t1
    
    # Restore all $s registers
    lw $s0, 0($t0)
    lw $s1, 4($t0)
    lw $s2, 8($t0)
    lw $s3, 12($t0)
    lw $s4, 16($t0)
    lw $s5, 20($t0)
    lw $s6, 24($t0)
    lw $s7, 28($t0)
    jr $ra
```

12) Exception Handling in Functions

**Structured Exception Handling:**
```assembly
# Function with exception handling
protected_function:
    addiu $sp, $sp, -16
    sw $ra, 12($sp)
    sw $fp, 8($sp)
    sw $s0, 4($sp)          # Save exception handler
    move $fp, $sp
    
    # Set up exception handler
    la $s0, exception_handler
    sw $s0, exception_ptr   # Global exception pointer
    
    # Risky operation that might fail
    jal risky_operation
    
    # Check for exception
    lw $t0, exception_flag
    bne $t0, $zero, handle_exception
    
    # Normal return path
    li $v0, 0               # Success
    j function_cleanup
    
handle_exception:
    # Exception occurred
    li $v0, -1              # Error code
    sw $zero, exception_flag # Clear flag
    
function_cleanup:
    # Restore previous exception handler
    lw $s0, 4($sp)
    sw $s0, exception_ptr
    
    # Standard epilogue
    move $sp, $fp
    lw $s0, 4($sp)
    lw $fp, 8($sp)
    lw $ra, 12($sp)
    addiu $sp, $sp, 16
    jr $ra

exception_handler:
    # Set exception flag
    li $t0, 1
    sw $t0, exception_flag
    # Jump back to caller's exception check
    jr $ra
```

13) Stack Debugging và Profiling

**Stack Overflow Detection:**
```assembly
# Check for stack overflow before allocation
safe_stack_alloc:
    # $a0 = bytes to allocate
    la $t0, stack_limit     # Predefined stack bottom
    subu $t1, $sp, $a0      # New stack pointer
    slt $t2, $t1, $t0       # New SP < limit?
    beq $t2, $zero, alloc_ok
    
    # Stack overflow!
    la $a0, stack_overflow_msg
    li $v0, 4               # Print string syscall
    syscall
    li $v0, 10              # Exit syscall
    syscall
    
alloc_ok:
    subu $sp, $sp, $a0      # Safe to allocate
    move $v0, $sp           # Return allocated pointer
    jr $ra

.data
stack_overflow_msg: .asciiz "Stack overflow detected!\n"
stack_limit: .word 0x7FFFEFFF    # Example stack limit
```

**Call Stack Walking:**
```assembly
# Print call stack for debugging (simplified)
print_stack_trace:
    addiu $sp, $sp, -8
    sw $ra, 4($sp)
    sw $fp, 0($sp)
    
    move $t0, $fp           # Current frame pointer
    li $t1, 0               # Frame counter
    
trace_loop:
    beq $t0, $zero, trace_done  # No more frames
    slti $t2, $t1, 10       # Limit depth to 10
    beq $t2, $zero, trace_done
    
    # Print frame info
    move $a0, $t1           # Frame number
    li $v0, 1               # Print integer
    syscall
    
    la $a0, frame_msg
    li $v0, 4               # Print string
    syscall
    
    lw $a0, 4($t0)          # Return address from this frame
    li $v0, 34              # Print hex
    syscall
    
    la $a0, newline
    li $v0, 4
    syscall
    
    # Move to previous frame
    lw $t0, 0($t0)          # Previous frame pointer
    addiu $t1, $t1, 1       # Next frame
    j trace_loop
    
trace_done:
    lw $fp, 0($sp)
    lw $ra, 4($sp)
    addiu $sp, $sp, 8
    jr $ra

.data
frame_msg: .asciiz ": Return address = 0x"
newline: .asciiz "\n"
```

14) Advanced Parameter Passing

**Pass by Reference Emulation:**
```assembly
# C: void swap(int *a, int *b)
swap_by_reference:
    lw $t0, 0($a0)          # Load *a
    lw $t1, 0($a1)          # Load *b
    sw $t1, 0($a0)          # *a = *b
    sw $t0, 0($a1)          # *b = temp
    jr $ra

# Caller:
    la $t0, var1
    la $t1, var2
    move $a0, $t0           # Pass address of var1
    move $a1, $t1           # Pass address of var2
    jal swap_by_reference
```

**Structure Return via Hidden Parameter:**
```assembly
# C: struct point add_points(struct point a, struct point b);
# Compiler-generated call sequence:

caller:
    # Allocate space for return value
    addiu $sp, $sp, -8      # Space for struct point (8 bytes)
    
    # Pass hidden return pointer as first argument
    move $a0, $sp           # Pointer to return space
    
    # Pass actual arguments (by value or reference)
    la $a1, point_a         # First struct argument
    la $a2, point_b         # Second struct argument
    
    jal add_points
    
    # Return value now in stack space pointed to by $sp
    lw $t0, 0($sp)          # point.x
    lw $t1, 4($sp)          # point.y
    
    addiu $sp, $sp, 8       # Clean up return space

add_points:
    # $a0 = return pointer, $a1 = &point_a, $a2 = &point_b
    lw $t0, 0($a1)          # point_a.x
    lw $t1, 4($a1)          # point_a.y
    lw $t2, 0($a2)          # point_b.x
    lw $t3, 4($a2)          # point_b.y
    
    add $t0, $t0, $t2       # result.x = a.x + b.x
    add $t1, $t1, $t3       # result.y = a.y + b.y
    
    sw $t0, 0($a0)          # Store result.x
    sw $t1, 4($a0)          # Store result.y
    
    jr $ra
```

15) Performance Optimization

**Function Inlining Example:**
```assembly
# Original function call:
    li $a0, 5
    jal square              # Call overhead
    # Result in $v0

square:
    mul $v0, $a0, $a0       # Actual work
    jr $ra                  # Return overhead

# Inlined version:
    li $t0, 5
    mul $v0, $t0, $t0       # Direct computation, no call overhead
```

**Leaf Function Optimization:**
```assembly
# Simple leaf function (no stack frame needed)
simple_add:
    add $v0, $a0, $a1       # Just add arguments
    jr $ra                  # Return immediately

# Complex leaf function (minimal stack usage)
complex_leaf:
    # Only save registers that we'll modify
    addiu $sp, $sp, -4
    sw $t0, 0($sp)          # Save only what we use
    
    # Function body using $t0
    sll $t0, $a0, 1         # $t0 = $a0 * 2
    add $v0, $t0, $a1       # result = ($a0 * 2) + $a1
    
    lw $t0, 0($sp)          # Restore
    addiu $sp, $sp, 4
    jr $ra
```

16) Memory Management within Functions

**Local Array Allocation:**
```assembly
function_with_local_array:
    # Allocate 100-element integer array (400 bytes)
    addiu $sp, $sp, -416    # 400 + 16 for saved registers
    sw $ra, 412($sp)
    sw $fp, 408($sp)
    sw $s0, 404($sp)
    sw $s1, 400($sp)
    move $fp, $sp
    
    # Local array starts at $fp
    move $s0, $fp           # Base of local array
    li $s1, 100             # Array size
    
    # Initialize array
    li $t0, 0               # i = 0
init_loop:
    beq $t0, $s1, init_done
    sll $t1, $t0, 2         # i * 4
    add $t2, $s0, $t1       # &array[i]
    sw $t0, 0($t2)          # array[i] = i
    addiu $t0, $t0, 1
    j init_loop
init_done:
    
    # Use array...
    
    # Cleanup
    move $sp, $fp
    lw $s1, 400($sp)
    lw $s0, 404($sp)
    lw $fp, 408($sp)
    lw $ra, 412($sp)
    addiu $sp, $sp, 416
    jr $ra
```

17) Interfacing with High-Level Languages

**C Calling Convention Compliance:**
```assembly
# Function callable from C: int mips_function(int a, int b, int c, int d, int e);
.globl mips_function
mips_function:
    # Standard prologue
    addiu $sp, $sp, -8
    sw $ra, 4($sp)
    sw $fp, 0($sp)
    move $fp, $sp
    
    # Parameters: $a0=a, $a1=b, $a2=c, $a3=d
    # Fifth parameter 'e' is at 8($fp) on stack
    
    # Access fifth parameter
    lw $t0, 8($fp)          # Load parameter 'e'
    
    # Compute: a + b + c + d + e
    add $v0, $a0, $a1       # a + b
    add $v0, $v0, $a2       # + c
    add $v0, $v0, $a3       # + d
    add $v0, $v0, $t0       # + e
    
    # Standard epilogue
    move $sp, $fp
    lw $fp, 0($sp)
    lw $ra, 4($sp)
    addiu $sp, $sp, 8
    jr $ra
```

Kết luận nâng cao
Function calls trong MIPS architecture đòi hỏi sự hiểu biết sâu sắc về:

1. **Memory Management**: Stack layout, alignment, overflow protection
2. **Register Discipline**: Caller vs callee-saved conventions
3. **Performance Optimization**: Inlining, tail calls, register windows
4. **Error Handling**: Exception propagation, stack unwinding
5. **Interoperability**: C calling conventions, ABI compliance
6. **Debugging Support**: Stack traces, parameter inspection

Mastery của những concepts này essential cho:
- **System Programming**: OS kernels, device drivers
- **Compiler Development**: Code generation, optimization
- **Embedded Systems**: Resource-constrained environments
- **Performance Tuning**: Call overhead reduction
- **Reverse Engineering**: Understanding compiled code

Việc áp dụng đúng calling conventions không chỉ đảm bảo correctness mà còn enable powerful optimizations và maintain compatibility across different tools và languages.

