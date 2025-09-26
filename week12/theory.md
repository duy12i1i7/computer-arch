Tuần 12 — Hiệu Năng: CPI, Amdahl, Benchmark và Vi Phần Cứng

Mục tiêu
- Đo lường hiệu năng qua phương trình: `Time = IC × CPI × Tc`.
- Phân tích cải tiến cục bộ với Luật Amdahl; tập trung vào bottleneck.
- Nhìn tổng quan biến thể vi kiến trúc: đa chu kỳ, pipeline, superscalar, out-of-order (khái quát).
- Liên hệ tối ưu mã ở mức assembly với hành vi bộ nhớ/nhánh.

1) Phương trình hiệu năng
- `IC` (Instruction Count): số lệnh thực thi; phụ thuộc vào ISA và trình biên dịch/lập trình viên.
- `CPI`: chu kỳ mỗi lệnh; phụ thuộc pipeline, hazard, cache, dự đoán nhánh.
- `Tc` (chu kỳ đồng hồ): phụ thuộc công nghệ và độ sâu pipeline.
- Tối ưu hoá nên nhắm đồng thời: giảm IC (mã gọn), giảm CPI (ít stall), hoặc tăng tần số (giảm Tc).

2) Luật Amdahl
- Speedup tổng = 1 / [(1-p) + p/s], với p là phần được tăng tốc, s là speedup phần đó.
- Cải tiến bộ phận có p nhỏ → lợi ích giới hạn; tập trung bottleneck có p lớn.

3) Ảnh hưởng pipeline và nhánh
- Lịch lệnh tốt, giảm lw-use, lấp delay slot giúp CPI → 1.
- Nhánh khó đoán làm tăng flush; sắp xếp điều kiện để thuận lợi dự đoán (tĩnh) hoặc gom nhánh.

4) Bộ nhớ và locality
- Tối ưu thứ tự truy cập, chặn dữ liệu (blocking), ghép/so le (padding) để giảm miss.
- Cấu trúc dữ liệu gọn, tuyến tính; tránh truy cập phân tán.

5) Vi kiến trúc cao cấp (khái quát)
- Superscalar: phát nhiều lệnh/chu kỳ; cần tránh phụ thuộc ràng buộc.
- Out-of-order: đổi chỗ thực thi giữ đúng phụ thuộc dữ liệu; phức tạp hơn nhiều so với MIPS cổ điển.
- Vector/SIMD: xử lý dữ liệu song song; không thuộc MIPS32 cơ bản nhưng là xu hướng kiến trúc.

6) Benchmark và đo đạc
- Dùng workload đại diện; tránh microbenchmark gây hiểu nhầm.
- Đo trung bình điều hoà/địa lý thay vì trung bình cộng khi ghép nhiều bài test (tuỳ metric).
- Tái hiện điều kiện thực tế: bộ nhớ, nhánh, I/O.

7) Ánh xạ tối ưu hoá vào MIPS
- Giảm IC: dùng lệnh hiệu quả (ghép địa chỉ, dịch thay nhân khi phù hợp), loại bỏ tính toán trùng.
- Giảm CPI: hoán đổi lệnh độc lập, gom nhóm load trước khi dùng, giảm nhánh.
- Dữ liệu: sắp xếp mảng liên tiếp, truy cập tuần tự, dùng `.align` hợp lý.

Kết luận
- Hiệu năng là bức tranh nhiều lớp: ISA, pipeline, cache, mã. Tư duy định lượng (CPI, Amdahl) cùng kỹ thuật lập lịch/địa chỉ hoá giúp mã MIPS đạt tốc độ tốt hơn.

---

## Chi tiết Nâng cao về Performance Analysis

### Computer Performance Analysis - Phân tích toàn diện

Performance analysis is the cornerstone of computer architecture design and optimization. Understanding the quantitative foundations of performance enables architects to make informed design decisions and programmers to write efficient code that maximizes hardware utilization.

**The Iron Law of Performance:**
```
Execution Time = Instructions × Cycles per Instruction × Clock Period
      CPU Time = IC × CPI × Tc

Where:
- IC (Instruction Count): Dynamic instruction count executed
- CPI (Cycles Per Instruction): Average cycles per instruction  
- Tc (Clock Period): Inverse of clock frequency
```

1) Comprehensive Performance Equation Analysis

**Performance Measurement Framework:**
```assembly
.data
# Performance counters
instruction_count: .word 0
cycle_count: .word 0
cache_hits: .word 0
cache_misses: .word 0
branch_correct: .word 0
branch_incorrect: .word 0
pipeline_stalls: .word 0

# Benchmark parameters
benchmark_start_time: .word 0
benchmark_end_time: .word 0
benchmark_iterations: .word 1000

# Performance results
measured_cpi: .word 0
measured_ipc: .word 0       # Instructions per cycle
cache_hit_rate: .word 0
branch_accuracy: .word 0

.text
# Performance monitoring initialization
init_performance_monitoring:
    # Clear all counters
    sw $zero, instruction_count
    sw $zero, cycle_count
    sw $zero, cache_hits
    sw $zero, cache_misses
    sw $zero, branch_correct
    sw $zero, branch_incorrect
    sw $zero, pipeline_stalls
    
    # Record start time
    li $v0, 30              # Get system time
    syscall
    sw $a0, benchmark_start_time
    
    jr $ra

# Instruction profiling (called for each instruction)
profile_instruction:
    # $a0 = instruction type (0=alu, 1=load, 2=store, 3=branch, 4=jump)
    # $a1 = cache result (0=miss, 1=hit)
    # $a2 = branch result (0=incorrect, 1=correct, -1=not_branch)
    # $a3 = stall cycles
    
    addiu $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)
    sw $s1, 4($sp)
    sw $s2, 0($sp)
    
    # Increment instruction count
    lw $t0, instruction_count
    addiu $t0, $t0, 1
    sw $t0, instruction_count
    
    # Update cache statistics
    beq $a1, $zero, cache_miss_profile
    
cache_hit_profile:
    lw $t1, cache_hits
    addiu $t1, $t1, 1
    sw $t1, cache_hits
    j branch_profile
    
cache_miss_profile:
    lw $t1, cache_misses
    addiu $t1, $t1, 1
    sw $t1, cache_misses
    
branch_profile:
    # Update branch statistics
    li $t2, -1
    beq $a2, $t2, stall_profile     # Not a branch
    
    beq $a2, $zero, branch_miss_profile
    
branch_hit_profile:
    lw $t3, branch_correct
    addiu $t3, $t3, 1
    sw $t3, branch_correct
    j stall_profile
    
branch_miss_profile:
    lw $t3, branch_incorrect
    addiu $t3, $t3, 1
    sw $t3, branch_incorrect
    
stall_profile:
    # Update stall cycles
    lw $t4, pipeline_stalls
    add $t4, $t4, $a3
    sw $t4, pipeline_stalls
    
    # Update cycle count (base cycle + stalls)
    lw $t5, cycle_count
    addiu $t5, $t5, 1       # Base cycle
    add $t5, $t5, $a3       # Add stall cycles
    sw $t5, cycle_count
    
    lw $s2, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addiu $sp, $sp, 16
    jr $ra

# Calculate performance metrics
calculate_performance_metrics:
    addiu $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s0, 4($sp)
    sw $s1, 0($sp)
    
    # Record end time
    li $v0, 30              # Get system time
    syscall
    sw $a0, benchmark_end_time
    
    # Calculate CPI
    lw $t0, cycle_count
    lw $t1, instruction_count
    beq $t1, $zero, metrics_error
    
    # CPI = cycles / instructions (multiply by 1000 for precision)
    li $t2, 1000
    mul $t0, $t0, $t2       # cycles * 1000
    div $t0, $t1            # (cycles * 1000) / instructions
    mflo $s0                # CPI * 1000
    sw $s0, measured_cpi
    
    # IPC = instructions / cycles
    mul $t1, $t1, $t2       # instructions * 1000
    lw $t3, cycle_count
    div $t1, $t3            # (instructions * 1000) / cycles
    mflo $s1                # IPC * 1000
    sw $s1, measured_ipc
    
    # Cache hit rate = hits / (hits + misses)
    lw $t4, cache_hits
    lw $t5, cache_misses
    add $t6, $t4, $t5       # Total accesses
    beq $t6, $zero, skip_cache_rate
    
    mul $t4, $t4, $t2       # hits * 1000
    div $t4, $t6            # (hits * 1000) / total
    mflo $t7                # Hit rate * 1000
    sw $t7, cache_hit_rate
    
skip_cache_rate:
    # Branch prediction accuracy
    lw $t8, branch_correct
    lw $t9, branch_incorrect
    add $s0, $t8, $t9       # Total branches
    beq $s0, $zero, skip_branch_rate
    
    mul $t8, $t8, $t2       # correct * 1000
    div $t8, $s0            # (correct * 1000) / total
    mflo $s1                # Accuracy * 1000
    sw $s1, branch_accuracy
    
skip_branch_rate:
    li $v0, 1               # Success
    j metrics_done
    
metrics_error:
    li $v0, 0               # Error
    
metrics_done:
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addiu $sp, $sp, 12
    jr $ra

# Print performance report
print_performance_report:
    addiu $sp, $sp, -8
    sw $ra, 4($sp)
    sw $s0, 0($sp)
    
    la $a0, perf_header
    li $v0, 4
    syscall
    
    # Print instruction count
    la $a0, ic_label
    li $v0, 4
    syscall
    lw $a0, instruction_count
    li $v0, 1
    syscall
    
    # Print cycle count
    la $a0, cycle_label
    li $v0, 4
    syscall
    lw $a0, cycle_count
    li $v0, 1
    syscall
    
    # Print CPI (divide by 1000 for display)
    la $a0, cpi_label
    li $v0, 4
    syscall
    lw $s0, measured_cpi
    div $s0, $s0, 1000      # Integer part
    move $a0, $s0
    li $v0, 1
    syscall
    
    li $a0, '.'
    li $v0, 11
    syscall
    
    lw $s0, measured_cpi
    li $t0, 1000
    div $s0, $t0
    mfhi $a0                # Remainder = fractional part
    li $v0, 1
    syscall
    
    # Print IPC
    la $a0, ipc_label
    li $v0, 4
    syscall
    lw $s0, measured_ipc
    div $s0, $s0, 1000
    move $a0, $s0
    li $v0, 1
    syscall
    
    li $a0, '.'
    li $v0, 11
    syscall
    
    lw $s0, measured_ipc
    li $t0, 1000
    div $s0, $t0
    mfhi $a0
    li $v0, 1
    syscall
    
    # Print cache hit rate
    la $a0, cache_rate_label
    li $v0, 4
    syscall
    lw $s0, cache_hit_rate
    div $s0, $s0, 10        # Convert to percentage
    move $a0, $s0
    li $v0, 1
    syscall
    la $a0, percent_sign
    li $v0, 4
    syscall
    
    # Print branch accuracy
    la $a0, branch_acc_label
    li $v0, 4
    syscall
    lw $s0, branch_accuracy
    div $s0, $s0, 10
    move $a0, $s0
    li $v0, 1
    syscall
    la $a0, percent_sign
    li $v0, 4
    syscall
    
    lw $s0, 0($sp)
    lw $ra, 4($sp)
    addiu $sp, $sp, 8
    jr $ra

# Benchmark matrix multiplication with performance monitoring
benchmark_matrix_multiply:
    addiu $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)         # i
    sw $s1, 8($sp)          # j  
    sw $s2, 4($sp)          # k
    sw $s3, 0($sp)          # matrix size
    
    jal init_performance_monitoring
    
    li $s3, 8               # 8x8 matrices
    li $s0, 0               # i = 0
    
bench_i_loop:
    bge $s0, $s3, bench_done
    li $s1, 0               # j = 0
    
bench_j_loop:
    bge $s1, $s3, bench_next_i
    
    # Profile load instruction (C[i][j])
    li $a0, 1               # Load instruction
    li $a1, 1               # Cache hit (assume)
    li $a2, -1              # Not a branch
    li $a3, 0               # No stalls
    jal profile_instruction
    
    li $s2, 0               # k = 0
    
bench_k_loop:
    bge $s2, $s3, bench_store_c
    
    # Profile load instruction (A[i][k])
    li $a0, 1               # Load instruction
    li $a1, 1               # Cache hit
    li $a2, -1              # Not a branch
    li $a3, 0               # No stalls
    jal profile_instruction
    
    # Profile load instruction (B[k][j])
    li $a0, 1               # Load instruction
    li $a1, 0               # Cache miss (stride access)
    li $a2, -1              # Not a branch
    li $a3, 10              # Memory stall cycles
    jal profile_instruction
    
    # Profile multiply instruction
    li $a0, 0               # ALU instruction
    li $a1, 1               # N/A for ALU
    li $a2, -1              # Not a branch
    li $a3, 0               # No stalls
    jal profile_instruction
    
    # Profile add instruction
    li $a0, 0               # ALU instruction
    li $a1, 1               # N/A
    li $a2, -1              # Not a branch
    li $a3, 0               # No stalls
    jal profile_instruction
    
    addiu $s2, $s2, 1
    
    # Profile branch instruction (k loop)
    li $a0, 3               # Branch instruction
    li $a1, 1               # N/A
    li $a1, 1               # Correctly predicted
    li $a3, 0               # No stalls
    jal profile_instruction
    
    j bench_k_loop
    
bench_store_c:
    # Profile store instruction
    li $a0, 2               # Store instruction
    li $a1, 1               # Cache hit
    li $a2, -1              # Not a branch
    li $a3, 0               # No stalls
    jal profile_instruction
    
    addiu $s1, $s1, 1
    
    # Profile branch instruction (j loop)
    li $a0, 3               # Branch instruction
    li $a1, 1               # N/A
    li $a2, 1               # Correctly predicted
    li $a3, 0               # No stalls
    jal profile_instruction
    
    j bench_j_loop
    
bench_next_i:
    addiu $s0, $s0, 1
    
    # Profile branch instruction (i loop)
    li $a0, 3               # Branch instruction
    li $a1, 1               # N/A
    li $a2, 1               # Correctly predicted
    li $a3, 0               # No stalls
    jal profile_instruction
    
    j bench_i_loop
    
bench_done:
    jal calculate_performance_metrics
    jal print_performance_report
    
    lw $s3, 0($sp)
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    addiu $sp, $sp, 20
    jr $ra
```

2) Amdahl's Law Analysis and Application

**Amdahl's Law Implementation:**
```assembly
.data
# Amdahl's Law parameters
parallel_fraction: .word 800       # 80.0% (scaled by 10)
sequential_fraction: .word 200     # 20.0% (scaled by 10)
processor_count: .word 4           # Number of processors
speedup_result: .word 0            # Calculated speedup

# Optimization scenarios
scenarios: .space 40               # 10 scenarios * 4 bytes each
scenario_names: .space 400         # 10 * 40 char names
scenario_count: .word 0

.text
# Calculate Amdahl's Law speedup
calculate_amdahl_speedup:
    # $a0 = parallel fraction (scaled by 10, so 80% = 800)
    # $a1 = number of processors
    # Returns: $v0 = speedup (scaled by 10)
    
    addiu $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s0, 4($sp)          # Parallel fraction
    sw $s1, 0($sp)          # Number of processors
    
    move $s0, $a0           # Save parallel fraction
    move $s1, $a1           # Save processor count
    
    # Sequential fraction = 1000 - parallel_fraction
    li $t0, 1000
    sub $t1, $t0, $s0       # Sequential fraction
    
    # Speedup = 1 / (sequential_fraction + parallel_fraction/processors)
    # All calculations scaled by 1000 for precision
    
    # Calculate parallel_fraction / processors
    mul $t2, $s0, 1000      # Scale parallel fraction
    div $t2, $s1            # Divide by processors
    mflo $t3                # Result
    
    # Calculate denominator: sequential_fraction + parallel_fraction/processors
    mul $t4, $t1, 1000      # Scale sequential fraction
    add $t5, $t4, $t3       # Add parallel term
    
    # Calculate speedup: 1 / denominator
    li $t6, 1000000         # 1.0 scaled by 1000000
    div $t6, $t5            # 1000000 / denominator
    mflo $v0                # Result scaled by 100
    
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addiu $sp, $sp, 12
    jr $ra

# Analyze multiple optimization scenarios
analyze_optimization_scenarios:
    addiu $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)          # Scenario index
    sw $s1, 4($sp)          # Base execution time
    sw $s2, 0($sp)          # Working register
    
    la $a0, amdahl_header
    li $v0, 4
    syscall
    
    li $s1, 1000            # Base execution time (1000 time units)
    li $s0, 0               # Scenario index
    
scenario_loop:
    li $t0, 5               # Number of scenarios  
    bge $s0, $t0, scenario_analysis_done
    
    # Define scenarios
    beq $s0, $zero, scenario_cpu_optimization
    li $t1, 1
    beq $s0, $t1, scenario_memory_optimization
    li $t1, 2
    beq $s0, $t1, scenario_branch_optimization
    li $t1, 3
    beq $s0, $t1, scenario_parallel_optimization
    li $t1, 4
    beq $s0, $t1, scenario_combined_optimization
    j next_scenario
    
scenario_cpu_optimization:
    # CPU optimization: 60% of code, 2x speedup
    la $a0, cpu_opt_msg
    li $v0, 4
    syscall
    
    li $a0, 600             # 60% parallelizable
    li $a1, 2               # 2x speedup
    jal calculate_amdahl_speedup
    move $s2, $v0
    j print_scenario_result
    
scenario_memory_optimization:
    # Memory optimization: 30% of code, 5x speedup
    la $a0, mem_opt_msg
    li $v0, 4
    syscall
    
    li $a0, 300             # 30% parallelizable
    li $a1, 5               # 5x speedup
    jal calculate_amdahl_speedup
    move $s2, $v0
    j print_scenario_result
    
scenario_branch_optimization:
    # Branch optimization: 10% of code, 10x speedup
    la $a0, branch_opt_msg
    li $v0, 4
    syscall
    
    li $a0, 100             # 10% parallelizable
    li $a1, 10              # 10x speedup
    jal calculate_amdahl_speedup
    move $s2, $v0
    j print_scenario_result
    
scenario_parallel_optimization:
    # Parallel optimization: 80% of code, 4 processors
    la $a0, parallel_opt_msg
    li $v0, 4
    syscall
    
    li $a0, 800             # 80% parallelizable
    li $a1, 4               # 4 processors
    jal calculate_amdahl_speedup
    move $s2, $v0
    j print_scenario_result
    
scenario_combined_optimization:
    # Combined optimization: complex scenario
    la $a0, combined_opt_msg
    li $v0, 4
    syscall
    
    # First optimize CPU (60% at 2x)
    li $a0, 600
    li $a1, 2
    jal calculate_amdahl_speedup
    move $t0, $v0           # First speedup
    
    # Then optimize memory (30% of remaining at 3x)
    li $a0, 300
    li $a1, 3
    jal calculate_amdahl_speedup
    move $t1, $v0           # Second speedup
    
    # Combined effect (simplified)
    add $s2, $t0, $t1       # Additive approximation
    div $s2, $s2, 2         # Average
    
print_scenario_result:
    # Print speedup result
    la $a0, speedup_label
    li $v0, 4
    syscall
    
    div $s2, $s2, 100       # Convert to decimal
    move $a0, $s2
    li $v0, 1
    syscall
    
    li $a0, '.'
    li $v0, 11
    syscall
    
    move $t2, $s2
    li $t3, 100
    mul $t2, $t2, $t3       # Restore original
    li $t3, 100
    div $t2, $t3
    mfhi $a0                # Fractional part
    li $v0, 1
    syscall
    
    la $a0, times_faster
    li $v0, 4
    syscall
    
next_scenario:
    addiu $s0, $s0, 1
    j scenario_loop
    
scenario_analysis_done:
    lw $s2, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addiu $sp, $sp, 16
    jr $ra

# Performance-critical code optimization examples
optimize_inner_loop:
    # Example: Optimizing a performance-critical inner loop
    # Original version vs optimized version comparison
    
    addiu $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)
    sw $s1, 4($sp)
    sw $s2, 0($sp)
    
    la $a0, optimization_header
    li $v0, 4
    syscall
    
    # Test original version
    jal init_performance_monitoring
    jal original_inner_loop
    jal calculate_performance_metrics
    
    # Save original results
    lw $s0, measured_cpi
    lw $s1, instruction_count
    
    la $a0, original_results
    li $v0, 4
    syscall
    move $a0, $s1
    li $v0, 1
    syscall
    la $a0, instructions_label
    li $v0, 4
    syscall
    
    div $s0, $s0, 1000
    move $a0, $s0
    li $v0, 1
    syscall
    la $a0, cpi_suffix
    li $v0, 4
    syscall
    
    # Test optimized version
    jal init_performance_monitoring
    jal optimized_inner_loop
    jal calculate_performance_metrics
    
    # Calculate improvement
    lw $s2, instruction_count
    
    la $a0, optimized_results
    li $v0, 4
    syscall
    move $a0, $s2
    li $v0, 1
    syscall
    la $a0, instructions_label
    li $v0, 4
    syscall
    
    lw $t0, measured_cpi
    div $t0, $t0, 1000
    move $a0, $t0
    li $v0, 1
    syscall
    la $a0, cpi_suffix
    li $v0, 4
    syscall
    
    # Calculate speedup
    div $s0, $s1, $s2       # Instruction count ratio
    la $a0, improvement_label
    li $v0, 4
    syscall
    move $a0, $s0
    li $v0, 1
    syscall
    la $a0, times_faster
    li $v0, 4
    syscall
    
    lw $s2, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addiu $sp, $sp, 16
    jr $ra

original_inner_loop:
    # Original inefficient inner loop
    li $t0, 0               # i
    li $t1, 1000            # Loop count
    
original_loop:
    bge $t0, $t1, original_done
    
    # Inefficient: repeated memory access
    la $t2, test_array
    sll $t3, $t0, 2         # i * 4
    add $t2, $t2, $t3       # &array[i]
    lw $t4, 0($t2)          # Load array[i]
    
    # Inefficient: complex calculation in loop
    mul $t5, $t4, $t4       # array[i] * array[i]
    div $t5, $t5, 7         # Expensive division
    mflo $t5
    
    # Store back
    sw $t5, 0($t2)
    
    # Profile each iteration
    li $a0, 1               # Load
    li $a1, 0               # Cache miss (poor locality)
    li $a2, -1              # Not branch
    li $a3, 5               # Memory stall
    jal profile_instruction
    
    li $a0, 0               # ALU (multiply)
    li $a1, 1               # N/A
    li $a2, -1              # Not branch
    li $a3, 2               # Multi-cycle multiply
    jal profile_instruction
    
    li $a0, 0               # ALU (divide)
    li $a1, 1               # N/A
    li $a2, -1              # Not branch
    li $a3, 20              # Expensive divide
    jal profile_instruction
    
    li $a0, 2               # Store
    li $a1, 0               # Cache miss
    li $a2, -1              # Not branch
    li $a3, 3               # Write stall
    jal profile_instruction
    
    addiu $t0, $t0, 1
    j original_loop
    
original_done:
    jr $ra

optimized_inner_loop:
    # Optimized version with multiple improvements
    li $t0, 0               # i
    li $t1, 1000            # Loop count
    la $t2, test_array      # Hoist address calculation
    li $t6, 7               # Hoist constant
    
    # Precompute division by 7 using multiply and shift
    # 1/7 ≈ 0.142857... ≈ 2454267027 / 2^34
    lui $t7, 0x9249         # Upper 16 bits of magic number
    ori $t7, $t7, 0x2493    # Lower 16 bits
    
optimized_loop:
    bge $t0, $t1, optimized_done
    
    # Efficient: single address calculation
    lw $t4, 0($t2)          # Load array[i] (good spatial locality)
    
    # Efficient: strength reduction - avoid division
    mul $t5, $t4, $t4       # array[i] * array[i]
    
    # Replace division with multiply and shift
    multu $t5, $t7          # Multiply by magic number
    mfhi $t8               # Get upper 32 bits
    srl $t8, $t8, 2         # Shift right by 2 (total shift = 34)
    
    # Store back
    sw $t8, 0($t2)
    addiu $t2, $t2, 4       # Increment pointer (strength reduction)
    
    # Profile optimized iteration
    li $a0, 1               # Load
    li $a1, 1               # Cache hit (good locality)
    li $a2, -1              # Not branch
    li $a3, 0               # No stall
    jal profile_instruction
    
    li $a0, 0               # ALU (multiply)
    li $a1, 1               # N/A
    li $a2, -1              # Not branch
    li $a3, 1               # Single-cycle multiply
    jal profile_instruction
    
    li $a0, 0               # ALU (magic multiply)
    li $a1, 1               # N/A
    li $a2, -1              # Not branch
    li $a3, 1               # Single-cycle multiply
    jal profile_instruction
    
    li $a0, 2               # Store
    li $a1, 1               # Cache hit
    li $a2, -1              # Not branch
    li $a3, 0               # No stall
    jal profile_instruction
    
    addiu $t0, $t0, 1
    j optimized_loop
    
optimized_done:
    jr $ra
```

3) Advanced Microarchitecture Concepts

**Superscalar and Out-of-Order Simulation:**
```assembly
.data
# Superscalar processor simulation
ISSUE_WIDTH = 4             # Can issue 4 instructions per cycle
NUM_FUNCTIONAL_UNITS = 8    # ALU, Load/Store, Branch units

# Instruction window
instruction_window: .space 128   # 32 instructions * 4 bytes
window_head: .word 0
window_tail: .word 0
window_size: .word 0

# Functional units
func_units: .space 32       # 8 units * 4 bytes (busy until cycle)
unit_types: .space 32       # Unit types (0=ALU, 1=LS, 2=Branch, 3=Mult)

# Register renaming simulation
physical_registers: .space 256  # 64 physical registers
register_map: .space 128        # 32 logical -> physical mapping
free_list: .space 256           # Free physical register list
free_list_head: .word 0
free_list_tail: .word 0

# Reorder buffer
reorder_buffer: .space 256      # 64 entries * 4 bytes
rob_head: .word 0
rob_tail: .word 0
rob_size: .word 0

.text
# Initialize superscalar processor simulator
init_superscalar_processor:
    # Initialize functional units
    la $t0, func_units
    li $t1, NUM_FUNCTIONAL_UNITS
    
init_func_units:
    beq $t1, $zero, init_rename
    sw $zero, 0($t0)        # Unit available at cycle 0
    addiu $t0, $t0, 4
    addiu $t1, $t1, -1
    j init_func_units
    
init_rename:
    # Initialize register renaming
    li $t0, 0               # Logical register
    li $t1, 32              # Number of logical registers
    
init_rename_loop:
    beq $t1, $zero, init_free_list
    
    # Map logical register to physical register
    la $t2, register_map
    sll $t3, $t0, 2         # reg * 4
    add $t2, $t2, $t3
    sw $t0, 0($t2)          # Initial 1:1 mapping
    
    addiu $t0, $t0, 1
    addiu $t1, $t1, -1
    j init_rename_loop
    
init_free_list:
    # Initialize free list with physical registers 32-63
    li $t0, 32              # Start with physical reg 32
    li $t1, 32              # 32 free registers
    la $t2, free_list
    
init_free_loop:
    beq $t1, $zero, init_reorder_buffer
    sw $t0, 0($t2)
    addiu $t0, $t0, 1
    addiu $t2, $t2, 4
    addiu $t1, $t1, -1
    j init_free_loop
    
init_reorder_buffer:
    sw $zero, rob_head
    sw $zero, rob_tail
    sw $zero, rob_size
    
    jr $ra

# Simulate superscalar instruction issue
simulate_superscalar_issue:
    # $a0 = current cycle
    # Returns: $v0 = instructions issued this cycle
    
    addiu $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)          # Current cycle
    sw $s1, 4($sp)          # Instructions issued
    sw $s2, 0($sp)          # Working register
    
    move $s0, $a0           # Save current cycle
    li $s1, 0               # Instructions issued = 0
    
    # Try to issue up to ISSUE_WIDTH instructions
    li $t0, ISSUE_WIDTH
    
issue_loop:
    beq $t0, $zero, issue_done
    beq $s1, $t0, issue_done    # Already issued max
    
    # Check if instruction window has instructions
    lw $t1, window_size
    beq $t1, $zero, issue_done
    
    # Get next instruction from window
    jal get_next_ready_instruction
    move $a0, $s0           # Current cycle
    
    beq $v0, $zero, issue_done  # No ready instructions
    
    # Try to issue instruction
    move $a0, $v0           # Instruction
    move $a1, $s0           # Current cycle
    jal try_issue_instruction
    
    beq $v0, $zero, try_next    # Couldn't issue
    
    # Successfully issued
    addiu $s1, $s1, 1       # Increment issued count
    
try_next:
    addiu $t0, $t0, -1
    j issue_loop
    
issue_done:
    move $v0, $s1           # Return number issued
    
    lw $s2, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addiu $sp, $sp, 16
    jr $ra

get_next_ready_instruction:
    # $a0 = current cycle
    # Returns: $v0 = ready instruction (0 if none)
    
    # Simplified: just return first instruction in window
    lw $t0, window_size
    beq $t0, $zero, no_ready_inst
    
    # Get instruction from head of window
    lw $t1, window_head
    la $t2, instruction_window
    sll $t3, $t1, 2         # head * 4
    add $t2, $t2, $t3
    lw $v0, 0($t2)          # Load instruction
    
    jr $ra
    
no_ready_inst:
    li $v0, 0
    jr $ra

try_issue_instruction:
    # $a0 = instruction, $a1 = current cycle
    # Returns: $v0 = 1 if issued, 0 if stalled
    
    addiu $sp, $sp, -12
    sw $ra, 8($sp)
    sw $a0, 4($sp)          # Instruction
    sw $a1, 0($sp)          # Current cycle
    
    # Determine required functional unit
    move $t0, $a0           # Instruction
    srl $t1, $t0, 26        # Extract opcode
    
    # Map opcode to functional unit type
    beq $t1, $zero, need_alu        # R-type
    li $t2, 35                      # lw
    beq $t1, $t2, need_load_store
    li $t2, 43                      # sw
    beq $t1, $t2, need_load_store
    li $t2, 4                       # beq
    beq $t1, $t2, need_branch
    
need_alu:
    li $t3, 0               # ALU unit type
    j find_available_unit
    
need_load_store:
    li $t3, 1               # Load/Store unit type
    j find_available_unit
    
need_branch:
    li $t3, 2               # Branch unit type
    
find_available_unit:
    # Find available functional unit of required type
    li $t4, 0               # Unit index
    la $t5, func_units
    la $t6, unit_types
    
find_unit_loop:
    li $t7, NUM_FUNCTIONAL_UNITS
    bge $t4, $t7, no_unit_available
    
    # Check unit type
    sll $t8, $t4, 2         # unit * 4
    add $t9, $t6, $t8
    lw $s0, 0($t9)          # Load unit type
    bne $s0, $t3, next_unit # Wrong type
    
    # Check if unit is available
    add $s1, $t5, $t8
    lw $s2, 0($s1)          # Load busy until cycle
    lw $s3, 0($sp)          # Current cycle
    bgt $s2, $s3, next_unit # Unit still busy
    
    # Found available unit - reserve it
    addiu $s4, $s3, 2       # Assume 2-cycle latency
    sw $s4, 0($s1)          # Mark busy until cycle
    
    # Add to reorder buffer
    jal add_to_reorder_buffer
    lw $a0, 4($sp)          # Instruction
    lw $a1, 0($sp)          # Issue cycle
    
    # Remove from instruction window
    jal remove_from_window
    
    li $v0, 1               # Successfully issued
    j try_issue_done
    
next_unit:
    addiu $t4, $t4, 1
    j find_unit_loop
    
no_unit_available:
    li $v0, 0               # Could not issue
    
try_issue_done:
    lw $a1, 0($sp)
    lw $a0, 4($sp)
    lw $ra, 8($sp)
    addiu $sp, $sp, 12
    jr $ra

add_to_reorder_buffer:
    # $a0 = instruction, $a1 = issue cycle
    
    # Check if ROB is full
    lw $t0, rob_size
    li $t1, 64              # ROB capacity
    beq $t0, $t1, rob_full
    
    # Add to tail
    lw $t2, rob_tail
    la $t3, reorder_buffer
    sll $t4, $t2, 2         # tail * 4
    add $t3, $t3, $t4
    sw $a0, 0($t3)          # Store instruction
    
    # Update tail pointer
    addiu $t2, $t2, 1
    li $t5, 64
    beq $t2, $t5, wrap_rob_tail
    j update_rob_tail
    
wrap_rob_tail:
    li $t2, 0
    
update_rob_tail:
    sw $t2, rob_tail
    
    # Increment size
    addiu $t0, $t0, 1
    sw $t0, rob_size
    
rob_full:
    jr $ra

remove_from_window:
    # Remove instruction from head of window
    lw $t0, window_size
    beq $t0, $zero, window_empty
    
    # Update head pointer
    lw $t1, window_head
    addiu $t1, $t1, 1
    li $t2, 32              # Window capacity
    beq $t1, $t2, wrap_window_head
    j update_window_head
    
wrap_window_head:
    li $t1, 0
    
update_window_head:
    sw $t1, window_head
    
    # Decrement size
    addiu $t0, $t0, -1
    sw $t0, window_size
    
window_empty:
    jr $ra

# Simulate out-of-order completion and retirement
simulate_ooo_completion:
    # $a0 = current cycle
    
    addiu $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s0, 4($sp)          # Current cycle
    sw $s1, 0($sp)          # Instructions completed
    
    move $s0, $a0
    li $s1, 0
    
    # Check functional units for completion
    li $t0, 0               # Unit index
    la $t1, func_units
    
completion_loop:
    li $t2, NUM_FUNCTIONAL_UNITS
    bge $t0, $t2, retirement_phase
    
    # Check if unit completes this cycle
    sll $t3, $t0, 2         # unit * 4
    add $t4, $t1, $t3
    lw $t5, 0($t4)          # Busy until cycle
    
    bne $t5, $s0, next_completion   # Not completing this cycle
    
    # Unit completes - mark as available
    sw $zero, 0($t4)
    addiu $s1, $s1, 1       # Count completion
    
next_completion:
    addiu $t0, $t0, 1
    j completion_loop
    
retirement_phase:
    # Try to retire instructions from ROB head
    jal try_retire_instructions
    move $a0, $s0           # Current cycle
    
    move $v0, $s1           # Return completions
    
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addiu $sp, $sp, 12
    jr $ra

try_retire_instructions:
    # $a0 = current cycle
    # Try to retire completed instructions in-order
    
    lw $t0, rob_size
    beq $t0, $zero, no_retire
    
    # Check head of ROB
    lw $t1, rob_head
    la $t2, reorder_buffer
    sll $t3, $t1, 2
    add $t2, $t2, $t3
    lw $t4, 0($t2)          # Load instruction
    
    # Check if instruction is complete (simplified)
    # In real implementation, would check completion status
    
    # Retire instruction
    addiu $t1, $t1, 1       # Advance head
    li $t5, 64
    beq $t1, $t5, wrap_rob_head
    j update_rob_head_retire
    
wrap_rob_head:
    li $t1, 0
    
update_rob_head_retire:
    sw $t1, rob_head
    
    # Decrement size
    addiu $t0, $t0, -1
    sw $t0, rob_size
    
no_retire:
    jr $ra

.data
# Test data
test_array: .space 4000

# Performance report labels
perf_header: .asciiz "\n=== Performance Report ===\n"
ic_label: .asciiz "Instructions: "
cycle_label: .asciiz "\nCycles: "
cpi_label: .asciiz "\nCPI: "
ipc_label: .asciiz "\nIPC: "
cache_rate_label: .asciiz "\nCache Hit Rate: "
branch_acc_label: .asciiz "\nBranch Accuracy: "
percent_sign: .asciiz "%"

# Amdahl's Law labels
amdahl_header: .asciiz "\n=== Amdahl's Law Analysis ===\n"
cpu_opt_msg: .asciiz "CPU Optimization (60% code, 2x speedup): "
mem_opt_msg: .asciiz "Memory Optimization (30% code, 5x speedup): "
branch_opt_msg: .asciiz "Branch Optimization (10% code, 10x speedup): "
parallel_opt_msg: .asciiz "Parallel Optimization (80% code, 4 processors): "
combined_opt_msg: .asciiz "Combined Optimization: "
speedup_label: .asciiz "Speedup: "
times_faster: .asciiz "x faster\n"

# Optimization comparison labels
optimization_header: .asciiz "\n=== Loop Optimization Comparison ===\n"
original_results: .asciiz "Original: "
optimized_results: .asciiz "Optimized: "
instructions_label: .asciiz " instructions, CPI: "
cpi_suffix: .asciiz "\n"
improvement_label: .asciiz "Improvement: "
```

Kết luận nâng cao
Performance analysis và optimization represent the intersection of theoretical computer science và practical engineering. Mastery requires understanding:

**Quantitative Foundation:**
- **Performance Equation**: IC × CPI × Tc provides framework for systematic optimization
- **Amdahl's Law**: Limits of partial optimization guide resource allocation decisions  
- **Roofline Model**: Memory bandwidth và computational intensity constraints
- **Benchmarking Methodology**: Representative workloads, statistical significance, measurement precision

**Microarchitectural Impact:**
- **Pipeline Efficiency**: Hazard reduction, instruction scheduling, branch prediction accuracy
- **Memory Hierarchy**: Cache optimization, prefetching, memory access patterns
- **Superscalar Execution**: Instruction-level parallelism, functional unit utilization
- **Out-of-Order Processing**: Dynamic scheduling, register renaming, speculation recovery

**Software Optimization:**
- **Algorithmic Complexity**: Choose algorithms with better asymptotic performance
- **Code Generation**: Compiler optimizations, hand-tuned assembly for critical paths
- **Data Structure Layout**: Cache-friendly organization, memory access locality
- **Loop Optimization**: Unrolling, blocking, vectorization, strength reduction

**System-Level Considerations:**
- **Bottleneck Analysis**: Identify và address limiting factors in system performance
- **Power Efficiency**: Performance per watt optimization for mobile và datacenter applications
- **Scalability**: Multi-core parallelization, distributed computing architectures
- **Real-World Constraints**: Thermal limits, power budgets, manufacturing costs

**Advanced Techniques:**
- **Profile-Guided Optimization**: Use runtime behavior to inform optimization decisions
- **Machine Learning**: Predict program behavior, optimize compilation strategies
- **Heterogeneous Computing**: GPU acceleration, specialized accelerators (TPU, FPGA)
- **Near-Data Computing**: Minimize data movement through processing-in-memory

Understanding performance fundamentals enables computer architects to design efficient processors, compiler writers to generate optimal code, và application developers to create high-performance software that fully utilizes modern computing systems.

