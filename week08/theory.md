Tuần 08 — Pipeline Cơ Bản: IF/ID/EX/MEM/WB

Mục tiêu
- Hiểu mô hình đường ống 5 giai đoạn MIPS cổ điển.
- Phân tích đường đi dữ liệu và tín hiệu điều khiển qua pipeline registers.
- Đánh giá CPI lý tưởng và chi phí bubble (stall).

1) 5 giai đoạn
- IF (Instruction Fetch): lấy lệnh từ bộ nhớ chỉ lệnh; PC ← PC+4.
- ID (Instruction Decode/Register Fetch): giải mã, đọc thanh ghi nguồn, tạo hằng.
- EX (Execute/Address): ALU tính toán, so sánh nhánh, tính địa chỉ.
- MEM (Memory Access): truy cập bộ nhớ dữ liệu (lw/sw).
- WB (Write Back): ghi kết quả về thanh ghi đích.

2) Thanh ghi pipeline
- IF/ID, ID/EX, EX/MEM, MEM/WB giữ thông tin lệnh qua các giai đoạn.
- Mỗi chu kỳ, lệnh tiến 1 giai đoạn (lý tưởng) → chồng chéo thực thi.

3) CPI lý tưởng và thông lượng
- Nếu không hazard, CPI ≈ 1 (mỗi chu kỳ hoàn tất 1 lệnh sau khi đầy đường ống).
- Thông lượng tăng ~k lần với k giai đoạn, độ trễ mỗi lệnh không đổi (hoặc cao hơn do latch/điều khiển).

4) Hazard cơ bản (giới thiệu)
- Cấu trúc (structural): tranh chấp tài nguyên (ví dụ bộ nhớ đơn cổng).
- Dữ liệu (data): phụ thuộc RAW, WAR, WAW; MIPS chủ yếu RAW.
- Điều khiển (control): nhánh, nhảy thay đổi PC.

5) Stall và bubble
- Khi hazard không thể giải, chèn bubble (nop) giữ ổn định dữ liệu.
- Ảnh hưởng CPI: mỗi bubble cộng thêm chu kỳ.

6) Forwarding (nhắc trước tuần 9)
- Chuyển tiếp kết quả từ EX/MEM/MEM/WB sang ID/EX để tránh chờ WB.
- Đặc biệt với `lw-use`, đôi khi vẫn cần 1 stall chu kỳ.

7) ISA và pipeline
- Thiết kế MIPS cố định 32-bit và load/store làm đơn giản hóa decode và control.
- Branch delay slot (lịch sử): cho phép tận dụng 1 lệnh sau nhánh; nhiều mô phỏng duy trì tương thích.

8) Detailed Pipeline Analysis

**Pipeline Register Contents:**
```
Cycle | IF/ID        | ID/EX           | EX/MEM         | MEM/WB
------|------------- |-----------------|----------------|----------------
1     | add $t0,...  | -               | -              | -
2     | lw $t1,...   | add $t0,...     | -              | -  
3     | sub $t2,...  | lw $t1,...      | add $t0,...    | -
4     | beq $t3,...  | sub $t2,...     | lw $t1,...     | add $t0,...
5     | and $t4,...  | beq $t3,...     | sub $t2,...    | lw $t1,...
```

**Pipeline Datapath Components:**
```assembly
# Conceptual pipeline stages with data flow

# IF Stage Components:
# - PC register
# - Instruction memory
# - PC+4 adder
# - IF/ID pipeline register

# ID Stage Components:  
# - Instruction decoder
# - Register file (read ports)
# - Sign extender
# - Control unit
# - ID/EX pipeline register

# EX Stage Components:
# - ALU
# - Branch target calculator
# - Forwarding unit
# - EX/MEM pipeline register

# MEM Stage Components:
# - Data memory
# - Branch decision logic
# - MEM/WB pipeline register

# WB Stage Components:
# - Register file (write port)
# - Write-back multiplexer
```

**Pipeline Performance Metrics:**
```assembly
# Calculate pipeline speedup
pipeline_speedup_analysis:
    # Single-cycle implementation:
    # Each instruction takes: IF + ID + EX + MEM + WB = 5 time units
    # For n instructions: 5n time units
    
    # Pipelined implementation (ideal):
    # First instruction: 5 time units to complete
    # Remaining n-1 instructions: 1 time unit each
    # Total: 5 + (n-1) = n + 4 time units
    
    # Speedup = (5n) / (n + 4)
    # As n → ∞, speedup approaches 5x
    
    # Example calculation for 1000 instructions:
    li $t0, 1000            # n = 1000
    li $t1, 5
    mul $t2, $t0, $t1       # Single-cycle time = 5000
    
    add $t3, $t0, 4         # Pipelined time = 1004
    
    # Speedup = 5000 / 1004 ≈ 4.98x
    div $t2, $t3
    mflo $v0                # Speedup (integer part)
    
    jr $ra
```

9) Advanced Pipeline Concepts

**Superscalar Pipeline Simulation:**
```assembly
# Simulate 2-way superscalar execution
# Can issue 2 instructions per cycle if no dependencies

.data
instruction_queue: .space 400   # Queue of 100 instructions
issue_width: .word 2            # Instructions per cycle
pipeline_depth: .word 5

.text
superscalar_simulator:
    # Simplified superscalar pipeline simulator
    # $a0 = instruction array base
    # $a1 = number of instructions
    
    addiu $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)         # Instruction pointer
    sw $s1, 12($sp)         # Cycle counter
    sw $s2, 8($sp)          # Instructions issued
    sw $s3, 4($sp)          # Instructions completed
    sw $s4, 0($sp)          # Pipeline stages array
    
    move $s0, $zero         # IP = 0
    move $s1, $zero         # Cycle = 0
    move $s2, $zero         # Issued = 0
    move $s3, $zero         # Completed = 0
    
    # Allocate pipeline tracking array
    lw $t0, pipeline_depth
    sll $t0, $t0, 2         # depth * 4 bytes per stage
    lw $t1, issue_width
    mul $t0, $t0, $t1       # * issue_width
    subu $sp, $sp, $t0      # Allocate on stack
    move $s4, $sp           # Pipeline array base
    
superscalar_cycle:
    # Check if simulation complete
    bge $s3, $a1, simulation_done
    
    # Issue phase: try to issue up to 2 instructions
    lw $t0, issue_width
    li $t1, 0               # Instructions issued this cycle
    
issue_loop:
    beq $t1, $t0, issue_done    # Reached issue width limit
    bge $s0, $a1, issue_done    # No more instructions
    
    # Check for dependencies with in-flight instructions
    sll $t2, $s0, 2         # instruction_index * 4
    add $t3, $a0, $t2       # &instructions[IP]
    lw $t4, 0($t3)          # Load instruction
    
    # Simplified dependency check (would be more complex in reality)
    jal check_dependencies
    beq $v0, $zero, issue_stall
    
    # Issue instruction into pipeline
    # Add to pipeline stage 0
    sll $t5, $t1, 2         # issue_slot * 4  
    lw $t6, pipeline_depth
    mul $t5, $t5, $t6       # issue_slot * depth * 4
    add $t5, $s4, $t5       # &pipeline[issue_slot][0]
    sw $t4, 0($t5)          # Store instruction in pipeline
    
    addiu $s0, $s0, 1       # IP++
    addiu $s2, $s2, 1       # Issued++
    addiu $t1, $t1, 1       # This cycle issued++
    j issue_loop
    
issue_stall:
    # Cannot issue due to dependency - pipeline stall
    j issue_done
    
issue_done:
    # Execute phase: advance all pipeline stages
    lw $t0, issue_width
    li $t1, 0               # Issue slot counter
    
execute_slots:
    beq $t1, $t0, execute_done
    
    # Advance pipeline stages for this issue slot
    lw $t2, pipeline_depth
    addiu $t3, $t2, -1      # depth - 1
    
advance_stages:
    bltz $t3, slot_done     # All stages processed
    
    # pipeline[slot][stage] = pipeline[slot][stage-1]
    sll $t4, $t1, 2         # slot * 4
    mul $t4, $t4, $t2       # slot * depth * 4
    add $t4, $s4, $t4       # &pipeline[slot][0]
    
    sll $t5, $t3, 2         # stage * 4
    add $t6, $t4, $t5       # &pipeline[slot][stage]
    
    beq $t3, $zero, clear_stage0
    addiu $t7, $t5, -4      # (stage-1) * 4
    add $t8, $t4, $t7       # &pipeline[slot][stage-1]
    lw $t9, 0($t8)          # Load from previous stage
    sw $t9, 0($t6)          # Store to current stage
    j stage_advanced
    
clear_stage0:
    sw $zero, 0($t6)        # Clear stage 0
    
stage_advanced:
    addiu $t3, $t3, -1      # stage--
    j advance_stages
    
slot_done:
    # Check if instruction completed (reached final stage)
    lw $t2, pipeline_depth
    addiu $t2, $t2, -1      # final_stage = depth - 1
    sll $t4, $t1, 2
    mul $t4, $t4, $t2
    add $t4, $s4, $t4
    sll $t5, $t2, 2
    add $t4, $t4, $t5       # &pipeline[slot][final_stage]
    lw $t6, 0($t4)          # Load instruction from final stage
    
    beq $t6, $zero, next_slot
    addiu $s3, $s3, 1       # Completed++
    sw $zero, 0($t4)        # Clear final stage
    
next_slot:
    addiu $t1, $t1, 1       # Next issue slot
    j execute_slots
    
execute_done:
    addiu $s1, $s1, 1       # Cycle++
    j superscalar_cycle
    
simulation_done:
    move $v0, $s1           # Return total cycles
    move $v1, $s2           # Return instructions issued
    
    # Restore stack and registers
    lw $t0, pipeline_depth
    sll $t0, $t0, 2
    lw $t1, issue_width
    mul $t0, $t0, $t1
    addu $sp, $sp, $t0      # Deallocate pipeline array
    
    lw $s4, 0($sp)
    lw $s3, 4($sp)
    lw $s2, 8($sp)
    lw $s1, 12($sp)
    lw $s0, 16($sp)
    lw $ra, 20($sp)
    addiu $sp, $sp, 24
    jr $ra

check_dependencies:
    # Simplified dependency checker
    # In real implementation, would check:
    # - RAW dependencies (read after write)
    # - WAR dependencies (write after read) 
    # - WAW dependencies (write after write)
    # - Structural hazards (resource conflicts)
    
    # For simulation, just return 1 (can issue)
    li $v0, 1
    jr $ra
```

10) Branch Prediction Implementation

**Two-bit Saturating Counter Predictor:**
```assembly
.data
# Branch prediction table (1024 entries * 2 bits each)
# Packed 4 predictors per word (8 bits used, 24 bits unused per word)
BHT_SIZE = 1024
branch_history_table: .space 1024   # 1024 bytes = 1024 * 2-bit predictors

# Branch target buffer (simplified)
BTB_SIZE = 256
branch_target_buffer: .space 1024   # 256 entries * 4 bytes each

.text
# Initialize branch predictor
init_branch_predictor:
    la $t0, branch_history_table
    li $t1, BHT_SIZE
    li $t2, 0x55            # Initialize to "weakly not taken" (01 pattern)
    
init_bht_loop:
    beq $t1, $zero, init_btb
    sb $t2, 0($t0)
    addiu $t0, $t0, 1
    addiu $t1, $t1, -1
    j init_bht_loop
    
init_btb:
    la $t0, branch_target_buffer
    li $t1, BTB_SIZE
    
init_btb_loop:
    beq $t1, $zero, init_done
    sw $zero, 0($t0)        # Initialize all targets to 0
    addiu $t0, $t0, 4
    addiu $t1, $t1, -1
    j init_btb_loop
    
init_done:
    jr $ra

# Make branch prediction
predict_branch:
    # $a0 = branch PC
    # Returns: $v0 = prediction (1 = taken, 0 = not taken)
    #          $v1 = predicted target (if taken)
    
    # Hash PC to get BHT index
    srl $t0, $a0, 2         # Remove lower 2 bits (word alignment)
    andi $t0, $t0, 1023     # Modulo 1024 (BHT_SIZE - 1)
    
    # Get 2-bit counter from BHT
    la $t1, branch_history_table
    add $t1, $t1, $t0
    lbu $t2, 0($t1)         # Load 2-bit counter
    
    # Extract prediction (bit 1 of counter)
    srl $v0, $t2, 1
    andi $v0, $v0, 1        # prediction = counter >> 1
    
    # If predicted taken, look up target in BTB
    beq $v0, $zero, predict_not_taken
    
    # Hash PC for BTB lookup
    srl $t3, $a0, 2
    andi $t3, $t3, 255      # Modulo 256 (BTB_SIZE - 1)
    
    la $t4, branch_target_buffer
    sll $t5, $t3, 2         # index * 4
    add $t4, $t4, $t5
    lw $v1, 0($t4)          # Load predicted target
    j predict_done
    
predict_not_taken:
    add $v1, $a0, 4         # Predicted target = PC + 4
    
predict_done:
    jr $ra

# Update branch predictor with actual outcome
update_branch_predictor:
    # $a0 = branch PC
    # $a1 = actual outcome (1 = taken, 0 = not taken)
    # $a2 = actual target (if taken)
    
    # Hash PC to get BHT index
    srl $t0, $a0, 2
    andi $t0, $t0, 1023
    
    # Get current 2-bit counter
    la $t1, branch_history_table
    add $t1, $t1, $t0
    lbu $t2, 0($t1)         # Current counter value
    
    # Update counter based on outcome
    beq $a1, $zero, branch_not_taken
    
branch_taken:
    # Increment counter (saturate at 3)
    addiu $t3, $t2, 1
    slti $t4, $t3, 4        # counter + 1 < 4?
    bne $t4, $zero, update_counter
    li $t3, 3               # Saturate at 3
    j update_counter
    
branch_not_taken:
    # Decrement counter (saturate at 0)
    addiu $t3, $t2, -1
    bgez $t3, update_counter
    li $t3, 0               # Saturate at 0
    
update_counter:
    sb $t3, 0($t1)          # Store updated counter
    
    # Update BTB if branch was taken
    beq $a1, $zero, update_done
    
    # Hash PC for BTB update
    srl $t5, $a0, 2
    andi $t5, $t5, 255
    
    la $t6, branch_target_buffer
    sll $t7, $t5, 2
    add $t6, $t6, $t7
    sw $a2, 0($t6)          # Store actual target
    
update_done:
    jr $ra
```

11) Cache Simulation Framework

**Direct-Mapped Cache Simulator:**
```assembly
.data
# Cache parameters
CACHE_SIZE = 1024           # 1KB cache
BLOCK_SIZE = 32             # 32-byte blocks
NUM_BLOCKS = 32             # CACHE_SIZE / BLOCK_SIZE

# Cache data structures
cache_data: .space 1024     # Actual cache data
cache_tags: .space 132      # 32 tags + valid bits (4 bytes each)
cache_stats_hits: .word 0
cache_stats_misses: .word 0

.text
# Initialize cache
init_cache:
    # Clear all cache data
    la $t0, cache_data
    li $t1, CACHE_SIZE
    
init_data_loop:
    beq $t1, $zero, init_tags
    sw $zero, 0($t0)
    addiu $t0, $t0, 4
    addiu $t1, $t1, -4
    j init_data_loop
    
init_tags:
    # Initialize all tags as invalid
    la $t0, cache_tags
    li $t1, NUM_BLOCKS
    
init_tags_loop:
    beq $t1, $zero, init_stats
    sw $zero, 0($t0)        # tag = 0, valid = 0
    addiu $t0, $t0, 4
    addiu $t1, $t1, -1
    j init_tags_loop
    
init_stats:
    sw $zero, cache_stats_hits
    sw $zero, cache_stats_misses
    jr $ra

# Cache lookup and access
cache_access:
    # $a0 = memory address
    # $a1 = access type (0 = read, 1 = write)
    # Returns: $v0 = hit/miss (1 = hit, 0 = miss)
    #          $v1 = data (for reads)
    
    addiu $sp, $sp, -8
    sw $ra, 4($sp)
    sw $a0, 0($sp)
    
    # Extract address components
    # Address format: | Tag | Index | Block Offset |
    #                 | 22  |   5   |      5       |
    
    andi $t0, $a0, 31       # Block offset (bits 4-0)
    srl $t1, $a0, 5         # Remove block offset
    andi $t1, $t1, 31       # Index (bits 9-5)
    srl $t2, $a0, 10        # Tag (bits 31-10)
    
    # Calculate cache line address
    la $t3, cache_tags
    sll $t4, $t1, 2         # index * 4
    add $t3, $t3, $t4       # &cache_tags[index]
    lw $t5, 0($t3)          # Load tag entry
    
    # Check if valid and tag matches
    andi $t6, $t5, 1        # Extract valid bit (LSB)
    beq $t6, $zero, cache_miss
    
    srl $t7, $t5, 1         # Extract tag (bits 31-1)
    bne $t7, $t2, cache_miss
    
cache_hit:
    # Cache hit - access data
    lw $t0, cache_stats_hits
    addiu $t0, $t0, 1
    sw $t0, cache_stats_hits
    
    # Calculate data address
    la $t0, cache_data
    sll $t1, $t1, 5         # index * BLOCK_SIZE
    add $t0, $t0, $t1       # &cache_data[index][0]
    lw $a0, 0($sp)          # Restore original address
    andi $t2, $a0, 31       # Block offset
    add $t0, $t0, $t2       # &cache_data[index][offset]
    
    beq $a1, $zero, cache_read_hit
    
cache_write_hit:
    # Write data (simplified - just store address for demo)
    sw $a0, 0($t0)
    li $v1, 0               # No data returned for writes
    j cache_hit_done
    
cache_read_hit:
    lw $v1, 0($t0)          # Load data
    
cache_hit_done:
    li $v0, 1               # Hit
    j cache_access_done
    
cache_miss:
    # Cache miss - update statistics
    lw $t0, cache_stats_misses
    addiu $t0, $t0, 1
    sw $t0, cache_stats_misses
    
    # Install new cache line
    # Update tag (simplified - no LRU needed for direct-mapped)
    sll $t0, $t2, 1         # tag << 1
    ori $t0, $t0, 1         # Set valid bit
    sw $t0, 0($t3)          # Store new tag entry
    
    # Load data from memory (simulated)
    jal simulate_memory_access
    
    # Store data in cache
    la $t0, cache_data
    sll $t1, $t1, 5         # index * BLOCK_SIZE  
    add $t0, $t0, $t1
    sw $v0, 0($t0)          # Store loaded data
    
    beq $a1, $zero, cache_read_miss
    
cache_write_miss:
    lw $a0, 0($sp)
    sw $a0, 0($t0)          # Write new data
    li $v1, 0
    j cache_miss_done
    
cache_read_miss:
    move $v1, $v0           # Return loaded data
    
cache_miss_done:
    li $v0, 0               # Miss
    
cache_access_done:
    lw $ra, 4($sp)
    addiu $sp, $sp, 8
    jr $ra

simulate_memory_access:
    # Simulate memory access delay and return data
    # In real system, would access main memory
    lw $a0, 0($sp)          # Get address from stack
    
    # Simulate 100-cycle memory access delay
    li $t0, 100
memory_delay_loop:
    beq $t0, $zero, memory_access_done
    addiu $t0, $t0, -1
    j memory_delay_loop
    
memory_access_done:
    # Return simulated data (just use address as data)
    move $v0, $a0
    jr $ra

# Print cache statistics
print_cache_stats:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Print hits
    la $a0, hits_msg
    li $v0, 4
    syscall
    
    lw $a0, cache_stats_hits
    li $v0, 1
    syscall
    
    # Print misses
    la $a0, misses_msg
    li $v0, 4
    syscall
    
    lw $a0, cache_stats_misses
    li $v0, 1
    syscall
    
    # Calculate and print hit rate
    lw $t0, cache_stats_hits
    lw $t1, cache_stats_misses
    add $t2, $t0, $t1       # Total accesses
    beq $t2, $zero, no_accesses
    
    # Hit rate = hits * 100 / total
    li $t3, 100
    mul $t4, $t0, $t3       # hits * 100
    div $t4, $t2            # (hits * 100) / total
    mflo $t5               # Hit rate percentage
    
    la $a0, hit_rate_msg
    li $v0, 4
    syscall
    
    move $a0, $t5
    li $v0, 1
    syscall
    
    la $a0, percent_msg
    li $v0, 4
    syscall
    
no_accesses:
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

.data
hits_msg: .asciiz "Cache Hits: "
misses_msg: .asciiz "\nCache Misses: "
hit_rate_msg: .asciiz "\nHit Rate: "
percent_msg: .asciiz "%\n"
```

12) Out-of-Order Execution Concepts

**Register Renaming Simulation:**
```assembly
.data
# Physical register file (larger than architectural)
NUM_ARCH_REGS = 32
NUM_PHYS_REGS = 64
physical_registers: .space 256      # 64 * 4 bytes

# Register mapping table (architectural -> physical)
register_map: .space 128            # 32 * 4 bytes

# Free list of physical registers
free_list: .space 256               # 64 entries
free_list_head: .word 32            # Start with physical reg 32
free_list_tail: .word 63            # End with physical reg 63

.text
# Initialize register renaming
init_register_renaming:
    # Initialize physical registers
    la $t0, physical_registers
    li $t1, NUM_PHYS_REGS
    li $t2, 0
    
init_phys_regs:
    beq $t1, $zero, init_map_table
    sw $t2, 0($t0)          # Initialize to register number
    addiu $t0, $t0, 4
    addiu $t1, $t1, -1
    addiu $t2, $t2, 1
    j init_phys_regs
    
init_map_table:
    # Initialize architectural -> physical mapping (1:1 initially)
    la $t0, register_map
    li $t1, NUM_ARCH_REGS
    li $t2, 0
    
init_map_loop:
    beq $t1, $zero, init_free_list
    sw $t2, 0($t0)          # arch_reg[i] maps to phys_reg[i]
    addiu $t0, $t0, 4
    addiu $t1, $t1, -1
    addiu $t2, $t2, 1
    j init_map_loop
    
init_free_list:
    # Initialize free list with physical registers 32-63
    la $t0, free_list
    li $t1, NUM_ARCH_REGS   # Start from register 32
    li $t2, NUM_PHYS_REGS
    
init_free_loop:
    beq $t1, $t2, init_done
    sw $t1, 0($t0)          # Add to free list
    addiu $t0, $t0, 4
    addiu $t1, $t1, 1
    j init_free_loop
    
init_done:
    jr $ra

# Rename registers for instruction
rename_instruction:
    # $a0 = instruction (encoded)
    # This is a simplified example for R-type: add $rd, $rs, $rt
    
    addiu $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)          # rs (source 1)
    sw $s1, 4($sp)          # rt (source 2)  
    sw $s2, 0($sp)          # rd (destination)
    
    # Extract register fields (simplified)
    srl $s0, $a0, 21        # rs field (bits 25-21)
    andi $s0, $s0, 31
    
    srl $s1, $a0, 16        # rt field (bits 20-16)
    andi $s1, $s1, 31
    
    srl $s2, $a0, 11        # rd field (bits 15-11)
    andi $s2, $s2, 31
    
    # Look up physical registers for sources
    la $t0, register_map
    sll $t1, $s0, 2         # rs * 4
    add $t1, $t0, $t1
    lw $t2, 0($t1)          # Physical reg for rs
    
    sll $t3, $s1, 2         # rt * 4
    add $t3, $t0, $t3
    lw $t4, 0($t3)          # Physical reg for rt
    
    # Allocate new physical register for destination
    jal allocate_physical_register
    move $t5, $v0           # New physical reg for rd
    
    # Update mapping table
    sll $t6, $s2, 2         # rd * 4
    add $t6, $t0, $t6
    lw $t7, 0($t6)          # Old physical reg for rd
    sw $t5, 0($t6)          # Update mapping
    
    # Return renamed instruction components
    move $v0, $t2           # Physical rs
    move $v1, $t4           # Physical rt
    move $a0, $t5           # Physical rd
    move $a1, $t7           # Old physical rd (for freeing later)
    
    lw $s2, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addiu $sp, $sp, 16
    jr $ra

allocate_physical_register:
    # Allocate a physical register from free list
    lw $t0, free_list_head
    lw $t1, free_list_tail
    
    beq $t0, $t1, no_free_regs  # Free list empty
    
    # Get register from head of free list
    la $t2, free_list
    sll $t3, $t0, 2         # head * 4
    add $t3, $t2, $t3
    lw $v0, 0($t3)          # Register number
    
    # Advance head pointer
    addiu $t0, $t0, 1
    li $t4, NUM_PHYS_REGS
    beq $t0, $t4, wrap_head
    j update_head
    
wrap_head:
    li $t0, NUM_ARCH_REGS   # Wrap to start of free region
    
update_head:
    sw $t0, free_list_head
    jr $ra
    
no_free_regs:
    # Handle out of physical registers (would trigger stall)
    li $v0, -1              # Error code
    jr $ra

free_physical_register:
    # $a0 = physical register number to free
    lw $t0, free_list_tail
    
    # Add to tail of free list
    la $t1, free_list
    sll $t2, $t0, 2
    add $t2, $t1, $t2
    sw $a0, 0($t2)          # Store at tail
    
    # Advance tail pointer
    addiu $t0, $t0, 1
    li $t3, NUM_PHYS_REGS
    beq $t0, $t3, wrap_tail
    j update_tail
    
wrap_tail:
    li $t0, NUM_ARCH_REGS
    
update_tail:
    sw $t0, free_list_tail
    jr $ra
```

Kết luận nâng cao
Pipeline architecture trong MIPS là fundamental concept that bridges gap между:

1. **Theoretical Performance**: Ideal speedup calculations
2. **Practical Implementation**: Hazards, stalls, branch prediction
3. **Advanced Techniques**: Superscalar, out-of-order execution
4. **System Integration**: Cache interaction, memory hierarchy
5. **Performance Analysis**: Profiling, simulation, optimization

Key insights:
- **Pipeline depth** affects both performance và complexity
- **Hazard detection và resolution** critical for correctness
- **Branch prediction** dramatically impacts performance
- **Cache design** interacts with pipeline behavior
- **Instruction scheduling** can hide latencies
- **Register renaming** enables advanced optimizations

Real-world applications:
- **Processor Design**: Understanding modern CPU architecture
- **Compiler Optimization**: Instruction scheduling, loop unrolling
- **Performance Analysis**: Identifying bottlenecks, measuring CPI
- **System Programming**: Understanding hardware behavior
- **Emulation/Simulation**: Building architectural simulators

Pipeline concepts особенно important для:
- **Computer Architecture Students**: Foundation for advanced topics
- **System Software Developers**: Performance-critical code optimization
- **Hardware Engineers**: CPU design, verification
- **Game Developers**: Console optimization, performance tuning
- **HPC Programmers**: Maximizing computational throughput

Understanding pipeline behavior enables написание more efficient code và better appreciation of hardware-software co-design principles.

