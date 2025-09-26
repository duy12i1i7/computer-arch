Tuần 11 — Ngoại Lệ, Ngắt, Syscall và Quyền

Mục tiêu
- Phân biệt ngoại lệ (exception) và ngắt (interrupt), đồng bộ/không đồng bộ.
- Hiểu luồng xử lý ngoại lệ cơ bản trên MIPS (khái quát), vai trò CP0.
- Sử dụng `syscall`, `break` trong môi trường mô phỏng (MARS/QtSPIM).

1) Khái niệm
- Ngoại lệ: sự kiện trong luồng lệnh (ví dụ tràn, truy cập không hợp lệ, chia 0). Đồng bộ với lệnh gây ra.
- Ngắt: tín hiệu bất chợt từ thiết bị ngoài (không đồng bộ). Trong mô phỏng cơ bản ít dùng.

2) Dòng điều khiển xử lý ngoại lệ (tổng quan)
- Phần cứng lưu PC gây sự kiện, chuyển tới vector handler (địa chỉ cố định/cấu hình được).
- Lưu trạng thái (Status/Cause EPC trong CP0), tắt bật ngắt, chuyển mode đặc quyền.
- Kết thúc bằng lệnh quay lại ngoại lệ (ERET) — khái niệm, MARS không mô phỏng đầy đủ đặc quyền.

3) Syscall trong MARS/QtSPIM
- `li $v0, code` và thiết lập tham số `$a0..$a3`, `syscall` để gọi dịch vụ giả lập: in số/chuỗi, đọc dữ liệu, cấp phát…
- Mã phổ biến: 1 (print_int), 4 (print_string), 5 (read_int), 8 (read_string), 9 (sbrk), 10 (exit), 11 (print_char), 34 (print_int_hex), ...

4) Lệnh `break` và debug
- `break` tạo ngoại lệ dùng cho gỡ lỗi; mô phỏng có thể dừng ở điểm này.

5) Ngoại lệ toán học/bộ nhớ
- Chia cho 0: đặt cờ và vector ngoại lệ; trong mô phỏng có thể báo lỗi runtime.
- Truy cập sai căn chỉnh/địa chỉ: có thể gây ngoại lệ; cần tuân thủ alignment.

6) Quyền và tách biệt chế độ (khái quát)
- Hệ MIPS thực có kernel/user mode, thanh ghi CP0 điều khiển, bảng trang bộ nhớ ảo (MMU/TLB).
- Trong mô phỏng giáo dục, các chi tiết này được đơn giản hóa hoặc không có.

Kết luận
- Ngoại lệ/ngắt đảm bảo hệ thống phản ứng với điều kiện bất thường và cung cấp dịch vụ hệ thống. Ở mức lập trình ứng dụng với MARS/QtSPIM, `syscall` là giao diện chính.

---

## Chi tiết Nâng cao về Exception Handling và System Call

### Exception and Interrupt Systems - Phân tích chi tiết

Exception và interrupt handling is fundamental to operating system design and computer architecture. These mechanisms enable systems to respond to exceptional conditions, provide system services, and maintain system integrity through privilege separation.

**Classification of Exceptional Control Flow:**
```
Synchronous Exceptions (Exceptions):
- Traps: Intentional (syscall, breakpoint)  
- Faults: Recoverable (page fault, alignment)
- Aborts: Unrecoverable (hardware failure)

Asynchronous Exceptions (Interrupts):
- Hardware Interrupts: Timer, I/O devices, network
- Software Interrupts: Inter-processor interrupts
```

1) Exception Types and Classification

**Comprehensive Exception Handling Framework:**
```assembly
.data
# Exception vector table (simplified)
exception_handlers:
    .word int_handler       # 0: Interrupt
    .word tlb_mod_handler   # 1: TLB modification 
    .word tlb_load_handler  # 2: TLB miss (load)
    .word tlb_store_handler # 3: TLB miss (store)
    .word addr_load_handler # 4: Address error (load)
    .word addr_store_handler # 5: Address error (store)
    .word bus_error_handler # 6: Bus error (instruction)
    .word bus_data_handler  # 7: Bus error (data)
    .word syscall_handler   # 8: System call
    .word bp_handler        # 9: Breakpoint
    .word ri_handler        # 10: Reserved instruction
    .word cpu_handler       # 11: Coprocessor unusable
    .word ov_handler        # 12: Arithmetic overflow
    .word trap_handler      # 13: Trap
    .word fpe_handler       # 15: Floating point exception

# Simulated CP0 registers (normally hardware-managed)
cp0_status: .word 0x00000000    # Status register
cp0_cause: .word 0x00000000     # Cause register  
cp0_epc: .word 0x00000000       # Exception PC
cp0_badvaddr: .word 0x00000000  # Bad virtual address
cp0_context: .word 0x00000000   # Context register
cp0_entryhi: .word 0x00000000   # TLB entry high
cp0_entrylo: .word 0x00000000   # TLB entry low

# Exception statistics
exception_counts: .space 64     # Count for each exception type
nested_level: .word 0           # Nesting depth
kernel_stack: .space 4096       # Kernel stack space
kernel_sp: .word 0              # Kernel stack pointer

# User program state save area
saved_registers: .space 128     # 32 registers * 4 bytes

.text
# Exception dispatcher (normally at 0x80000180)
exception_dispatcher:
    # Save user context immediately
    la $k0, saved_registers
    sw $at, 0($k0)
    sw $v0, 4($k0)
    sw $v1, 8($k0)
    sw $a0, 12($k0)
    sw $a1, 16($k0)
    sw $a2, 20($k0)
    sw $a3, 24($k0)
    sw $t0, 28($k0)
    sw $t1, 32($k0)
    sw $t2, 36($k0)
    sw $t3, 40($k0)
    sw $t4, 44($k0)
    sw $t5, 48($k0)
    sw $t6, 52($k0)
    sw $t7, 56($k0)
    sw $s0, 60($k0)
    sw $s1, 64($k0)
    sw $s2, 68($k0)
    sw $s3, 72($k0)
    sw $s4, 76($k0)
    sw $s5, 80($k0)
    sw $s6, 84($k0)
    sw $s7, 88($k0)
    sw $t8, 92($k0)
    sw $t9, 96($k0)
    sw $gp, 100($k0)
    sw $sp, 104($k0)        # Save user stack pointer
    sw $fp, 108($k0)
    sw $ra, 112($k0)
    
    # Switch to kernel stack
    lw $sp, kernel_sp
    
    # Increment nesting level
    lw $k1, nested_level
    addiu $k1, $k1, 1
    sw $k1, nested_level
    
    # Get exception cause
    lw $k0, cp0_cause
    srl $k0, $k0, 2         # Extract ExcCode (bits 6:2)
    andi $k0, $k0, 31       # Mask to 5 bits
    
    # Update exception statistics
    la $k1, exception_counts
    sll $t0, $k0, 2         # exccode * 4
    add $k1, $k1, $t0
    lw $t1, 0($k1)
    addiu $t1, $t1, 1
    sw $t1, 0($k1)
    
    # Jump to specific handler
    la $k1, exception_handlers
    add $k1, $k1, $t0       # &handlers[exccode]
    lw $k1, 0($k1)          # Load handler address
    jr $k1                  # Jump to handler
    
# System call handler
syscall_handler:
    # System call number in $v0
    # Arguments in $a0-$a3
    
    addiu $sp, $sp, -16
    sw $ra, 12($sp)
    sw $a0, 8($sp)
    sw $a1, 4($sp)
    sw $v0, 0($sp)
    
    # Validate system call number
    li $t0, MAX_SYSCALL
    bge $v0, $t0, invalid_syscall
    bltz $v0, invalid_syscall
    
    # Dispatch to system call
    la $t1, syscall_table
    sll $t2, $v0, 2         # syscall * 4
    add $t1, $t1, $t2
    lw $t3, 0($t1)          # Load handler address
    jalr $t3                # Call system call handler
    
    j syscall_return
    
invalid_syscall:
    li $v0, -1              # Error return
    
syscall_return:
    # Restore context and return
    lw $v0, 0($sp)          # Restore original $v0 if needed
    lw $a1, 4($sp)
    lw $a0, 8($sp)
    lw $ra, 12($sp)
    addiu $sp, $sp, 16
    
    # Update EPC to skip syscall instruction
    lw $t0, cp0_epc
    addiu $t0, $t0, 4       # Skip syscall
    sw $t0, cp0_epc
    
    j exception_return

# Arithmetic overflow handler
ov_handler:
    addiu $sp, $sp, -12
    sw $ra, 8($sp)
    sw $a0, 4($sp)
    sw $v0, 0($sp)
    
    # Get faulting instruction address
    lw $t0, cp0_epc
    
    # Log overflow exception
    la $a0, overflow_msg
    li $v0, 4
    syscall
    
    move $a0, $t0           # Print faulting PC
    li $v0, 34              # Print hex
    syscall
    
    # Option 1: Terminate program
    # li $v0, 10
    # syscall
    
    # Option 2: Continue with saturated arithmetic
    # This would require instruction analysis and result modification
    jal handle_overflow_recovery
    
    lw $v0, 0($sp)
    lw $a0, 4($sp)
    lw $ra, 8($sp)
    addiu $sp, $sp, 12
    
    j exception_return

handle_overflow_recovery:
    # Sophisticated overflow recovery
    # In real implementation, would:
    # 1. Decode the faulting instruction
    # 2. Determine operands and operation
    # 3. Compute saturated result
    # 4. Store result in destination register
    # 5. Update saved register context
    
    # For demo, just continue
    jr $ra

# TLB miss handler (load)
tlb_load_handler:
    addiu $sp, $sp, -12
    sw $ra, 8($sp)
    sw $t0, 4($sp)
    sw $t1, 0($sp)
    
    # Get bad virtual address
    lw $t0, cp0_badvaddr
    
    # Simple page table lookup (normally more complex)
    jal lookup_page_table
    move $a0, $t0           # Virtual address
    
    beq $v0, $zero, page_fault
    
    # Install TLB entry
    sw $v0, cp0_entrylo     # Physical page frame
    srl $t1, $t0, 12        # Virtual page number
    sll $t1, $t1, 12        # Clear offset bits
    sw $t1, cp0_entryhi     # Virtual page number
    
    # TLB write (simulated)
    jal tlb_write_random
    
    lw $t1, 0($sp)
    lw $t0, 4($sp)
    lw $ra, 8($sp)
    addiu $sp, $sp, 12
    
    j exception_return
    
page_fault:
    # Handle page fault - load from storage, allocate page, etc.
    jal handle_page_fault
    move $a0, $t0           # Virtual address
    
    lw $t1, 0($sp)
    lw $t0, 4($sp) 
    lw $ra, 8($sp)
    addiu $sp, $sp, 12
    
    j exception_return

# Address error handler
addr_load_handler:
    addiu $sp, $sp, -8
    sw $ra, 4($sp)
    sw $a0, 0($sp)
    
    # Get bad address
    lw $t0, cp0_badvaddr
    
    # Check if alignment error
    andi $t1, $t0, 3        # Check word alignment
    bne $t1, $zero, alignment_error
    
    # Check if address is in valid range
    li $t2, 0x80000000      # Kernel boundary
    bge $t0, $t2, kernel_address_error
    
    # Other address errors
    la $a0, addr_error_msg
    li $v0, 4
    syscall
    
    # Terminate program
    li $v0, 10
    syscall
    
alignment_error:
    la $a0, alignment_msg
    li $v0, 4
    syscall
    
    move $a0, $t0
    li $v0, 34
    syscall
    
    # Could attempt to fix alignment in some cases
    li $v0, 10
    syscall
    
kernel_address_error:
    la $a0, kernel_addr_msg
    li $v0, 4
    syscall
    
    li $v0, 10
    syscall

# Breakpoint handler
bp_handler:
    addiu $sp, $sp, -8
    sw $ra, 4($sp)
    sw $a0, 0($sp)
    
    la $a0, breakpoint_msg
    li $v0, 4
    syscall
    
    # Print current PC
    lw $a0, cp0_epc
    li $v0, 34
    syscall
    
    # In debugger, would enter interactive mode
    # For demo, just continue
    
    lw $a0, 0($sp)
    lw $ra, 4($sp)
    addiu $sp, $sp, 8
    
    j exception_return

# Reserved instruction handler
ri_handler:
    addiu $sp, $sp, -12
    sw $ra, 8($sp)
    sw $a0, 4($sp)
    sw $t0, 0($sp)
    
    la $a0, reserved_inst_msg
    li $v0, 4
    syscall
    
    # Get and print faulting instruction
    lw $t0, cp0_epc
    # In real system, would read instruction from memory
    move $a0, $t0
    li $v0, 34
    syscall
    
    # Terminate program (could also emulate instruction)
    li $v0, 10
    syscall

# Exception return common path
exception_return:
    # Decrement nesting level
    lw $k0, nested_level
    addiu $k0, $k0, -1
    sw $k0, nested_level
    
    # Restore user context
    la $k0, saved_registers
    lw $at, 0($k0)
    lw $v0, 4($k0)
    lw $v1, 8($k0)
    lw $a0, 12($k0)
    lw $a1, 16($k0)
    lw $a2, 20($k0)
    lw $a3, 24($k0)
    lw $t0, 28($k0)
    lw $t1, 32($k0)
    lw $t2, 36($k0)
    lw $t3, 40($k0)
    lw $t4, 44($k0)
    lw $t5, 48($k0)
    lw $t6, 52($k0)
    lw $t7, 56($k0)
    lw $s0, 60($k0)
    lw $s1, 64($k0)
    lw $s2, 68($k0)
    lw $s3, 72($k0)
    lw $s4, 76($k0)
    lw $s5, 80($k0)
    lw $s6, 84($k0)
    lw $s7, 88($k0)
    lw $t8, 92($k0)
    lw $t9, 96($k0)
    lw $gp, 100($k0)
    lw $sp, 104($k0)       # Restore user stack
    lw $fp, 108($k0)
    lw $ra, 112($k0)
    
    # Return from exception (ERET simulation)
    lw $k0, cp0_epc
    jr $k0                  # Return to user program
```

2) Advanced System Call Implementation

**Comprehensive System Call Interface:**
```assembly
.data
# System call table
syscall_table:
    .word sys_exit          # 0: exit
    .word sys_print_int     # 1: print integer
    .word sys_print_float   # 2: print float
    .word sys_print_double  # 3: print double  
    .word sys_print_string  # 4: print string
    .word sys_read_int      # 5: read integer
    .word sys_read_float    # 6: read float
    .word sys_read_double   # 7: read double
    .word sys_read_string   # 8: read string
    .word sys_sbrk          # 9: allocate heap memory
    .word sys_exit2         # 10: exit with status
    .word sys_print_char    # 11: print character
    .word sys_read_char     # 12: read character
    .word sys_open          # 13: open file
    .word sys_read_file     # 14: read from file
    .word sys_write_file    # 15: write to file
    .word sys_close         # 16: close file
    .word sys_time          # 30: get time
    .word sys_sleep         # 32: sleep
    .word sys_print_hex     # 34: print integer as hex
    .word sys_print_bin     # 35: print integer as binary
    .word sys_print_uint    # 36: print unsigned integer

MAX_SYSCALL = 40

# File descriptor table (simplified)
MAX_FILES = 16
file_table: .space 64       # 16 files * 4 bytes per entry
file_names: .space 1024     # File name storage
next_fd: .word 3            # Next available FD (0,1,2 reserved)

# Memory management
heap_pointer: .word 0x10040000  # Start of heap
heap_size: .word 0              # Current heap size
max_heap: .word 0x7FFFFFFF      # Maximum heap address

.text
# Enhanced print integer with formatting
sys_print_int:
    # $a0 = integer to print
    # $a1 = format options (0=decimal, 1=hex, 2=binary, 3=octal)
    
    addiu $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)          # Number
    sw $s1, 4($sp)          # Format
    sw $s2, 0($sp)          # Working register
    
    move $s0, $a0           # Save number
    move $s1, $a1           # Save format
    
    beq $s1, $zero, print_decimal
    li $t0, 1
    beq $s1, $t0, print_hex_format
    li $t0, 2  
    beq $s1, $t0, print_binary_format
    li $t0, 3
    beq $s1, $t0, print_octal_format
    
print_decimal:
    move $a0, $s0
    li $v0, 1               # Standard print integer
    syscall
    j print_int_done
    
print_hex_format:
    la $a0, hex_prefix
    li $v0, 4
    syscall
    move $a0, $s0
    li $v0, 34              # Print hex
    syscall
    j print_int_done
    
print_binary_format:
    la $a0, bin_prefix
    li $v0, 4
    syscall
    
    # Print 32 bits
    li $s2, 32              # Bit counter
    move $t0, $s0           # Number
    
print_bit_loop:
    beq $s2, $zero, print_int_done
    
    sll $t0, $t0, 1         # Shift left
    bltz $t0, print_one
    
print_zero:
    li $a0, '0'
    li $v0, 11
    syscall
    j next_bit
    
print_one:
    li $a0, '1'
    li $v0, 11
    syscall
    
next_bit:
    # Add space every 4 bits for readability
    andi $t1, $s2, 3
    li $t2, 1
    bne $t1, $t2, no_space
    li $a0, ' '
    li $v0, 11
    syscall
    
no_space:
    addiu $s2, $s2, -1
    j print_bit_loop
    
print_octal_format:
    la $a0, oct_prefix
    li $v0, 4
    syscall
    
    # Convert to octal (groups of 3 bits)
    li $s2, 11              # 33 bits / 3 = 11 octal digits
    move $t0, $s0
    
print_octal_loop:
    beq $s2, $zero, print_int_done
    
    # Extract 3 bits
    srl $t1, $t0, 29        # Get top 3 bits
    andi $t1, $t1, 7        # Mask to 3 bits
    
    addiu $a0, $t1, '0'     # Convert to ASCII
    li $v0, 11
    syscall
    
    sll $t0, $t0, 3         # Shift left 3 bits
    addiu $s2, $s2, -1
    j print_octal_loop
    
print_int_done:
    lw $s2, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addiu $sp, $sp, 16
    jr $ra

# Advanced string operations
sys_read_string:
    # $a0 = buffer address
    # $a1 = maximum length
    # Enhanced with bounds checking and line editing
    
    addiu $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)         # Buffer
    sw $s1, 8($sp)          # Max length
    sw $s2, 4($sp)          # Current position
    sw $s3, 0($sp)          # Character
    
    move $s0, $a0           # Buffer
    move $s1, $a1           # Max length
    li $s2, 0               # Position
    
read_char_loop:
    # Check buffer bounds
    bge $s2, $s1, buffer_full
    
    # Read character
    li $v0, 12              # Read char
    syscall
    move $s3, $v0           # Save character
    
    # Check for newline (end of input)
    li $t0, 10              # '\n'
    beq $s3, $t0, string_complete
    
    # Check for carriage return
    li $t0, 13              # '\r'
    beq $s3, $t0, string_complete
    
    # Check for backspace
    li $t0, 8               # Backspace
    beq $s3, $t0, handle_backspace
    li $t0, 127             # DEL
    beq $s3, $t0, handle_backspace
    
    # Check for printable character
    li $t0, 32              # Space
    blt $s3, $t0, read_char_loop    # Skip control chars
    li $t0, 126             # '~'
    bgt $s3, $t0, read_char_loop    # Skip extended chars
    
    # Store character in buffer
    add $t1, $s0, $s2       # Buffer + position
    sb $s3, 0($t1)          # Store character
    
    # Echo character
    move $a0, $s3
    li $v0, 11
    syscall
    
    addiu $s2, $s2, 1       # Increment position
    j read_char_loop
    
handle_backspace:
    # Only backspace if not at beginning
    beq $s2, $zero, read_char_loop
    
    addiu $s2, $s2, -1      # Decrement position
    
    # Echo backspace sequence
    li $a0, 8               # Backspace
    li $v0, 11
    syscall
    li $a0, ' '             # Space
    li $v0, 11
    syscall
    li $a0, 8               # Backspace again
    li $v0, 11
    syscall
    
    j read_char_loop
    
buffer_full:
    # Buffer full - force completion
    addiu $s2, $s2, -1      # Make room for null terminator
    
string_complete:
    # Add null terminator
    add $t1, $s0, $s2
    sb $zero, 0($t1)
    
    # Echo newline
    li $a0, 10
    li $v0, 11
    syscall
    
    lw $s3, 0($sp)
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    addiu $sp, $sp, 20
    jr $ra

# Enhanced memory allocation with debugging
sys_sbrk:
    # $a0 = number of bytes to allocate
    # Returns: $v0 = pointer to allocated memory (or -1 on error)
    
    addiu $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s0, 4($sp)          # Requested size
    sw $s1, 0($sp)          # Current heap pointer
    
    move $s0, $a0           # Save requested size
    
    # Check for negative allocation
    bltz $s0, sbrk_error
    
    # Get current heap pointer
    lw $s1, heap_pointer
    
    # Check if allocation would exceed maximum
    add $t0, $s1, $s0       # New heap pointer
    lw $t1, max_heap
    bgt $t0, $t1, sbrk_error
    
    # Update heap pointer
    sw $t0, heap_pointer
    
    # Update heap size
    lw $t2, heap_size
    add $t2, $t2, $s0
    sw $t2, heap_size
    
    # Clear allocated memory (optional, for debugging)
    beq $s0, $zero, sbrk_success    # Skip if zero bytes
    
    move $t3, $s1           # Start address
    move $t4, $s0           # Size
    
clear_loop:
    beq $t4, $zero, sbrk_success
    sb $zero, 0($t3)
    addiu $t3, $t3, 1
    addiu $t4, $t4, -1
    j clear_loop
    
sbrk_success:
    move $v0, $s1           # Return original heap pointer
    j sbrk_done
    
sbrk_error:
    li $v0, -1              # Error return
    
sbrk_done:
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addiu $sp, $sp, 12
    jr $ra

# File operations (simplified implementation)
sys_open:
    # $a0 = filename (string)
    # $a1 = flags (0=read, 1=write, 2=append)
    # Returns: $v0 = file descriptor (or -1 on error)
    
    addiu $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)          # Filename
    sw $s1, 4($sp)          # Flags
    sw $s2, 0($sp)          # File descriptor
    
    move $s0, $a0           # Save filename
    move $s1, $a1           # Save flags
    
    # Find free file descriptor
    lw $s2, next_fd
    li $t0, MAX_FILES
    bge $s2, $t0, open_error
    
    # Store filename (simplified - just store pointer)
    la $t1, file_table
    sll $t2, $s2, 2         # fd * 4
    add $t1, $t1, $t2
    sw $s0, 0($t1)          # Store filename pointer
    
    # Update next available FD
    addiu $t3, $s2, 1
    sw $t3, next_fd
    
    move $v0, $s2           # Return file descriptor
    j open_done
    
open_error:
    li $v0, -1              # Error return
    
open_done:
    lw $s2, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addiu $sp, $sp, 16
    jr $ra

sys_read_file:
    # $a0 = file descriptor
    # $a1 = buffer
    # $a2 = count
    # Returns: $v0 = bytes read (or -1 on error)
    
    # Simplified implementation - just return error
    li $v0, -1
    jr $ra

sys_write_file:
    # $a0 = file descriptor  
    # $a1 = buffer
    # $a2 = count
    # Returns: $v0 = bytes written (or -1 on error)
    
    # Check for stdout (fd = 1)
    li $t0, 1
    beq $a0, $t0, write_stdout
    
    # Check for stderr (fd = 2)
    li $t0, 2
    beq $a0, $t0, write_stderr
    
    # Other files not implemented
    li $v0, -1
    jr $ra
    
write_stdout:
write_stderr:
    # Write to console
    move $t0, $a1           # Buffer
    move $t1, $a2           # Count
    li $t2, 0               # Bytes written
    
write_loop:
    beq $t1, $zero, write_done
    lbu $a0, 0($t0)         # Load character
    li $v0, 11              # Print char
    syscall
    
    addiu $t0, $t0, 1       # Next character
    addiu $t1, $t1, -1      # Decrement count
    addiu $t2, $t2, 1       # Increment written
    j write_loop
    
write_done:
    move $v0, $t2           # Return bytes written
    jr $ra

sys_close:
    # $a0 = file descriptor
    # Returns: $v0 = 0 on success, -1 on error
    
    # Validate file descriptor
    li $t0, 3
    blt $a0, $t0, close_error   # Can't close stdin/stdout/stderr
    li $t0, MAX_FILES
    bge $a0, $t0, close_error
    
    # Clear file table entry
    la $t1, file_table
    sll $t2, $a0, 2
    add $t1, $t1, $t2
    sw $zero, 0($t1)
    
    li $v0, 0               # Success
    jr $ra
    
close_error:
    li $v0, -1              # Error
    jr $ra

sys_time:
    # Return current time (simulated)
    # In real system, would read hardware timer
    li $v0, 1234567890      # Fixed time for simulation
    jr $ra

sys_sleep:
    # $a0 = milliseconds to sleep
    # Simulate by doing busy work
    move $t0, $a0
    
sleep_loop:
    beq $t0, $zero, sleep_done
    li $t1, 1000            # Inner loop count
    
inner_sleep:
    beq $t1, $zero, sleep_next
    addiu $t1, $t1, -1
    j inner_sleep
    
sleep_next:
    addiu $t0, $t0, -1
    j sleep_loop
    
sleep_done:
    jr $ra

sys_exit:
    # $a0 = exit status
    li $v0, 10              # MARS exit syscall
    syscall
    # Should not return

sys_exit2:
    # Enhanced exit with status
    # $a0 = exit status
    addiu $sp, $sp, -8
    sw $a0, 4($sp)
    sw $ra, 0($sp)
    
    # Print exit message
    la $a0, exit_msg
    li $v0, 4
    syscall
    
    lw $a0, 4($sp)          # Restore exit status
    li $v0, 1
    syscall
    
    li $a0, 10              # Newline
    li $v0, 11
    syscall
    
    li $v0, 10              # Exit
    syscall

# Utility functions for system calls
lookup_page_table:
    # $a0 = virtual address
    # Returns: $v0 = physical page frame (or 0 if not found)
    
    # Simplified page table lookup
    # In real system, would traverse hierarchical page tables
    srl $t0, $a0, 12        # Virtual page number
    
    # For simulation, map pages 1:1 with offset
    li $t1, 0x00400000      # Physical base
    srl $t1, $t1, 12        # Physical page base
    add $v0, $t0, $t1       # Physical page = virtual page + base
    
    jr $ra

handle_page_fault:
    # $a0 = faulting virtual address
    # Simplified page fault handler
    
    # In real system would:
    # 1. Check if address is valid (in VMA)
    # 2. Allocate physical page
    # 3. Load page from storage if needed
    # 4. Update page table
    # 5. Install TLB entry
    
    # For simulation, just return success
    jr $ra

tlb_write_random:
    # Install TLB entry at random index
    # In real hardware, would write to TLB
    jr $ra

# Exception handling support functions
init_exception_system:
    # Initialize exception handling system
    
    # Set up kernel stack
    la $t0, kernel_stack
    addiu $t0, $t0, 4096    # Top of stack
    sw $t0, kernel_sp
    
    # Initialize CP0 registers
    sw $zero, cp0_status
    sw $zero, cp0_cause
    sw $zero, cp0_epc
    
    # Clear exception statistics
    la $t0, exception_counts
    li $t1, 16              # Number of exception types
    
clear_stats:
    beq $t1, $zero, init_done
    sw $zero, 0($t0)
    addiu $t0, $t0, 4
    addiu $t1, $t1, -1
    j clear_stats
    
init_done:
    jr $ra

print_exception_stats:
    # Print exception statistics
    addiu $sp, $sp, -8
    sw $ra, 4($sp)
    sw $s0, 0($sp)
    
    la $a0, stats_header
    li $v0, 4
    syscall
    
    li $s0, 0               # Exception type
    
stats_loop:
    li $t0, 16
    bge $s0, $t0, stats_done
    
    # Print exception name
    la $t1, exception_names
    sll $t2, $s0, 2         # type * 4
    add $t1, $t1, $t2
    lw $a0, 0($t1)
    li $v0, 4
    syscall
    
    # Print count
    la $t1, exception_counts
    add $t1, $t1, $t2
    lw $a0, 0($t1)
    li $v0, 1
    syscall
    
    li $a0, 10              # Newline
    li $v0, 11
    syscall
    
    addiu $s0, $s0, 1
    j stats_loop
    
stats_done:
    lw $s0, 0($sp)
    lw $ra, 4($sp)
    addiu $sp, $sp, 8
    jr $ra

.data
# Exception messages
overflow_msg: .asciiz "Arithmetic overflow at PC: "
alignment_msg: .asciiz "Alignment error at address: "
addr_error_msg: .asciiz "Address error\n"
kernel_addr_msg: .asciiz "Kernel address space violation\n"
breakpoint_msg: .asciiz "Breakpoint hit at PC: "
reserved_inst_msg: .asciiz "Reserved instruction at PC: "
exit_msg: .asciiz "Program exiting with status: "

# Format prefixes
hex_prefix: .asciiz "0x"
bin_prefix: .asciiz "0b"
oct_prefix: .asciiz "0o"

# Statistics
stats_header: .asciiz "Exception Statistics:\n"
exception_names:
    .word int_name, tlb_mod_name, tlb_load_name, tlb_store_name
    .word addr_load_name, addr_store_name, bus_error_name, bus_data_name
    .word syscall_name, bp_name, ri_name, cpu_name
    .word ov_name, trap_name, reserved_name, fpe_name

int_name: .asciiz "Interrupts: "
tlb_mod_name: .asciiz "TLB Modifications: "
tlb_load_name: .asciiz "TLB Load Misses: "
tlb_store_name: .asciiz "TLB Store Misses: "
addr_load_name: .asciiz "Address Errors (Load): "
addr_store_name: .asciiz "Address Errors (Store): "
bus_error_name: .asciiz "Bus Errors (Instruction): "
bus_data_name: .asciiz "Bus Errors (Data): "
syscall_name: .asciiz "System Calls: "
bp_name: .asciiz "Breakpoints: "
ri_name: .asciiz "Reserved Instructions: "
cpu_name: .asciiz "Coprocessor Unusable: "
ov_name: .asciiz "Arithmetic Overflows: "
trap_name: .asciiz "Traps: "
reserved_name: .asciiz "Reserved: "
fpe_name: .asciiz "Floating Point Exceptions: "
```

3) Privilege Architecture and Protection

**User/Kernel Mode Simulation:**
```assembly
.data
# Privilege levels
USER_MODE = 0
KERNEL_MODE = 1

# Current privilege level
current_mode: .word USER_MODE

# Protected resources
protected_memory_base: .word 0x80000000
protected_memory_size: .word 0x10000000

# System call gate
syscall_gate_addr: .word syscall_dispatcher

.text
# Privilege check for memory access
check_memory_privilege:
    # $a0 = address to check
    # $a1 = access type (0=read, 1=write, 2=execute)
    # Returns: $v0 = 1 if allowed, 0 if denied
    
    # Check if in kernel mode
    lw $t0, current_mode
    li $t1, KERNEL_MODE
    beq $t0, $t1, access_allowed    # Kernel can access everything
    
    # User mode - check if accessing protected memory
    lw $t2, protected_memory_base
    blt $a0, $t2, access_allowed    # Below protected region
    
    lw $t3, protected_memory_size
    add $t3, $t2, $t3               # End of protected region
    bge $a0, $t3, access_allowed    # Above protected region
    
    # Access to protected memory from user mode
    li $v0, 0                       # Deny access
    jr $ra
    
access_allowed:
    li $v0, 1                       # Allow access
    jr $ra

# Mode switching (simplified)
enter_kernel_mode:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Check if already in kernel mode
    lw $t0, current_mode
    li $t1, KERNEL_MODE
    beq $t0, $t1, already_kernel
    
    # Switch to kernel mode
    sw $t1, current_mode
    
    # In real system, would also:
    # - Switch to kernel stack
    # - Save user context
    # - Enable/disable interrupts
    # - Update MMU settings
    
already_kernel:
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

exit_kernel_mode:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Check if in kernel mode
    lw $t0, current_mode
    li $t1, KERNEL_MODE
    bne $t0, $t1, not_kernel
    
    # Switch to user mode
    li $t2, USER_MODE
    sw $t2, current_mode
    
    # In real system, would also:
    # - Switch to user stack
    # - Restore user context
    # - Update privilege bits
    # - Flush privileged state
    
not_kernel:
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

# Protected instruction emulation
execute_privileged_instruction:
    # $a0 = instruction opcode
    # $a1 = instruction operands
    
    addiu $sp, $sp, -12
    sw $ra, 8($sp)
    sw $a0, 4($sp)
    sw $a1, 0($sp)
    
    # Check privilege level
    lw $t0, current_mode
    li $t1, KERNEL_MODE
    bne $t0, $t1, privilege_violation
    
    # Execute privileged operation based on opcode
    lw $t2, 4($sp)          # Restore opcode
    
    # Example privileged operations
    li $t3, 1               # TLB write
    beq $t2, $t3, priv_tlb_write
    li $t3, 2               # Interrupt enable/disable
    beq $t2, $t3, priv_int_control
    li $t3, 3               # Cache control
    beq $t2, $t3, priv_cache_control
    
    # Unknown privileged instruction
    j privilege_violation
    
priv_tlb_write:
    # Simulate TLB write operation
    la $a0, tlb_write_msg
    li $v0, 4
    syscall
    j priv_done
    
priv_int_control:
    # Simulate interrupt control
    la $a0, int_control_msg
    li $v0, 4
    syscall
    j priv_done
    
priv_cache_control:
    # Simulate cache control
    la $a0, cache_control_msg
    li $v0, 4
    syscall
    j priv_done
    
privilege_violation:
    # Generate privilege violation exception
    la $a0, priv_violation_msg
    li $v0, 4
    syscall
    
    # Would normally generate exception
    li $v0, 10              # Exit for demo
    syscall
    
priv_done:
    lw $a1, 0($sp)
    lw $a0, 4($sp) 
    lw $ra, 8($sp)
    addiu $sp, $sp, 12
    jr $ra

# Secure system call dispatcher
syscall_dispatcher:
    # Entry point for system calls from user mode
    addiu $sp, $sp, -8
    sw $ra, 4($sp)
    sw $v0, 0($sp)
    
    # Validate that call came from user mode
    lw $t0, current_mode
    li $t1, USER_MODE
    bne $t0, $t1, invalid_syscall_mode
    
    # Enter kernel mode
    jal enter_kernel_mode
    
    # Validate system call number
    lw $t2, 0($sp)          # Restore syscall number
    bltz $t2, invalid_syscall_num
    li $t3, MAX_SYSCALL
    bge $t2, $t3, invalid_syscall_num
    
    # Dispatch to system call handler
    la $t4, syscall_table
    sll $t5, $t2, 2         # syscall * 4
    add $t4, $t4, $t5
    lw $t6, 0($t4)          # Load handler address
    jalr $t6                # Call handler
    
    # Exit kernel mode
    jal exit_kernel_mode
    
    lw $v0, 0($sp)
    lw $ra, 4($sp)
    addiu $sp, $sp, 8
    jr $ra
    
invalid_syscall_mode:
    la $a0, invalid_mode_msg
    li $v0, 4
    syscall
    li $v0, 10
    syscall
    
invalid_syscall_num:
    la $a0, invalid_num_msg
    li $v0, 4
    syscall
    li $v0, 10
    syscall

.data
tlb_write_msg: .asciiz "TLB write operation executed\n"
int_control_msg: .asciiz "Interrupt control operation executed\n"
cache_control_msg: .asciiz "Cache control operation executed\n"
priv_violation_msg: .asciiz "Privilege violation - attempted privileged operation in user mode\n"
invalid_mode_msg: .asciiz "Invalid system call - not in user mode\n"
invalid_num_msg: .asciiz "Invalid system call number\n"
```

Kết luận
Exception and interrupt handling forms the foundation of modern operating systems and enables:

**Core Concepts:**
- **Exception Classification**: Synchronous vs asynchronous, recoverable vs non-recoverable
- **Control Flow Transfer**: Hardware mechanisms for transferring control to handlers
- **Context Preservation**: Saving and restoring program state across exceptions
- **Privilege Enforcement**: Protecting system resources and maintaining security

**System Call Interface:**
- **Service Abstraction**: Clean interface between user programs and kernel services
- **Parameter Validation**: Ensuring security through input validation and bounds checking
- **Resource Management**: Managing system resources like memory, files, and devices
- **Error Handling**: Robust error reporting and recovery mechanisms

**Advanced Features:**
- **Nested Exceptions**: Handling exceptions that occur during exception processing
- **Interrupt Prioritization**: Managing multiple simultaneous interrupt sources
- **Memory Protection**: Enforcing address space isolation between processes
- **Performance Optimization**: Minimizing exception handling overhead

**Real-world Applications:**
- **Operating System Design**: Implementing process management, memory management, I/O
- **Embedded Systems**: Handling real-time events and hardware interrupts
- **Security Systems**: Implementing access control and isolation mechanisms
- **Debugging Tools**: Using breakpoints and single-stepping for program analysis

Understanding exception handling is essential for system programmers, kernel developers, and anyone working on low-level software that interacts directly with hardware and operating system services.

