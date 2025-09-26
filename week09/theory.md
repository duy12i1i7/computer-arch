Tuần 09 — Hazards: Dữ Liệu/Điều Khiển/Cấu Trúc; Forwarding

Mục tiêu
- Phân loại hazard và tác động đến pipeline.
- Hiểu cơ chế forwarding/bypassing và logic phát hiện hazard (hazard detection unit).
- Kỹ thuật lập lịch lệnh (instruction scheduling) để giảm stall.

1) Data hazards
- RAW (Read After Write): phụ thuộc đọc sau viết (thường gặp nhất). Ví dụ: `add $t1,...` sau đó `add $t2, $t1, ...`.
- WAR và WAW phổ biến hơn trong máy superscalar/ghi muộn; MIPS pipeline cổ điển tránh được.

2) Hazard lw-use
- `lw rt, ...` ngay sau đó dùng `rt` trong EX → dữ liệu chưa sẵn sàng ở ID/EX.
- Giải pháp: stall 1 chu kỳ, hoặc chèn lệnh độc lập giữa `lw` và lệnh dùng.

3) Forwarding/Bypassing
- Luồng dữ liệu: EX/MEM → ID/EX hoặc MEM/WB → ID/EX để cấp trước kết quả.
- Cần logic so sánh số hiệu thanh ghi đích/nguồn để chọn mux đường chuyển tiếp.

4) Control hazards
- Nhánh/nhảy thay đổi PC: pipeline đã lấy trước lệnh sai → flush.
- Giảm hại: delay slot, dự đoán tĩnh/động (bộ đếm 2-bit, BTB), hoán đổi lệnh vào delay slot có ích.

5) Structural hazards
- Tranh chấp tài nguyên (ví dụ bộ nhớ đơn cổng cho lệnh và dữ liệu). Giải pháp: tách I-cache/D-cache.

6) Scheduling thủ công
- Hoán đổi lệnh độc lập xen giữa cặp phụ thuộc để che giấu độ trễ (hide latency).
- Tận dụng phát lệnh ở delay slot nhánh (nếu có) để làm việc hữu ích.

7) Ảnh hưởng tới hiệu năng
- CPI thực tế = 1 + (chu kỳ stall do hazard)/số lệnh.
- Tái cấu trúc mã giảm stall, tăng locality, giảm nhánh khó đoán → cải thiện đáng kể.

8) Advanced Hazard Detection

**Dynamic Hazard Detection Unit:**
```assembly
.data
# Instruction buffer for hazard analysis
INST_BUFFER_SIZE = 8
instruction_buffer: .space 32       # 8 instructions * 4 bytes
buffer_head: .word 0
buffer_tail: .word 0
buffer_count: .word 0

# Register dependency tracking
REG_COUNT = 32
reg_producers: .space 128           # Track which instruction produces each register
reg_ready_time: .space 128          # When each register will be ready

.text
# Initialize hazard detection unit
init_hazard_detection:
    # Clear instruction buffer
    la $t0, instruction_buffer
    li $t1, INST_BUFFER_SIZE
    
clear_buffer:
    beq $t1, $zero, init_reg_tracking
    sw $zero, 0($t0)
    addiu $t0, $t0, 4
    addiu $t1, $t1, -1
    j clear_buffer
    
init_reg_tracking:
    # Initialize register tracking
    la $t0, reg_producers
    la $t1, reg_ready_time
    li $t2, REG_COUNT
    
init_reg_loop:
    beq $t2, $zero, hazard_init_done
    sw $zero, 0($t0)        # No producer initially
    sw $zero, 0($t1)        # Ready at time 0
    addiu $t0, $t0, 4
    addiu $t1, $t1, 4
    addiu $t2, $t2, -1
    j init_reg_loop
    
hazard_init_done:
    sw $zero, buffer_head
    sw $zero, buffer_tail
    sw $zero, buffer_count
    jr $ra

# Add instruction to analysis buffer
add_instruction_to_buffer:
    # $a0 = instruction word
    # $a1 = instruction ID
    # $a2 = current cycle
    
    addiu $sp, $sp, -12
    sw $ra, 8($sp)
    sw $a0, 4($sp)
    sw $a1, 0($sp)
    
    # Check if buffer is full
    lw $t0, buffer_count
    li $t1, INST_BUFFER_SIZE
    beq $t0, $t1, buffer_full
    
    # Add to buffer tail
    lw $t2, buffer_tail
    la $t3, instruction_buffer
    sll $t4, $t2, 2         # tail * 4
    add $t3, $t3, $t4
    sw $a0, 0($t3)          # Store instruction
    
    # Update tail pointer
    addiu $t2, $t2, 1
    beq $t2, $t1, wrap_tail
    j update_tail
wrap_tail:
    li $t2, 0
update_tail:
    sw $t2, buffer_tail
    
    # Increment count
    addiu $t0, $t0, 1
    sw $t0, buffer_count
    
    # Analyze instruction for dependencies
    lw $a0, 4($sp)          # Restore instruction
    lw $a1, 0($sp)          # Restore ID
    jal analyze_instruction_dependencies
    
    j add_buffer_done
    
buffer_full:
    # Handle buffer overflow (would trigger stall in real processor)
    li $v0, -1              # Error code
    
add_buffer_done:
    lw $ra, 8($sp)
    addiu $sp, $sp, 12
    jr $ra

# Analyze instruction dependencies
analyze_instruction_dependencies:
    # $a0 = instruction word
    # $a1 = instruction ID  
    # $a2 = current cycle
    
    addiu $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)         # instruction
    sw $s1, 8($sp)          # instruction ID
    sw $s2, 4($sp)          # current cycle
    sw $s3, 0($sp)          # working register
    
    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    
    # Determine instruction type
    srl $t0, $s0, 26        # Extract opcode
    
    # Check for R-type (opcode = 0)
    beq $t0, $zero, analyze_r_type
    
    # Check for common I-type instructions
    li $t1, 8               # addi
    beq $t0, $t1, analyze_i_type_alu
    li $t1, 35              # lw
    beq $t0, $t1, analyze_load
    li $t1, 43              # sw
    beq $t0, $t1, analyze_store
    li $t1, 4               # beq
    beq $t0, $t1, analyze_branch
    
    # Default: treat as no dependencies
    j analyze_done
    
analyze_r_type:
    # R-type: rd = rs op rt
    # Extract register fields
    srl $t0, $s0, 21
    andi $t0, $t0, 31       # rs
    srl $t1, $s0, 16  
    andi $t1, $t1, 31       # rt
    srl $t2, $s0, 11
    andi $t2, $t2, 31       # rd
    
    # Check RAW hazards for source registers
    jal check_raw_hazard    # $a0 = rs
    move $a0, $t0
    jal check_raw_hazard
    move $s3, $v0           # Save stall cycles for rs
    
    move $a0, $t1           # $a0 = rt  
    jal check_raw_hazard
    slt $t3, $s3, $v0       # max(rs_stall, rt_stall)
    beq $t3, $zero, rs_longer
    move $s3, $v0
rs_longer:
    
    # Record this instruction as producer of rd
    move $a0, $t2           # rd
    move $a1, $s1           # instruction ID
    add $a2, $s2, $s3       # ready_time = current_cycle + stall
    addiu $a2, $a2, 1       # + execution latency
    jal record_producer
    
    j analyze_done
    
analyze_i_type_alu:
    # I-type ALU: rt = rs op immediate
    srl $t0, $s0, 21
    andi $t0, $t0, 31       # rs
    srl $t1, $s0, 16
    andi $t1, $t1, 31       # rt (destination)
    
    move $a0, $t0
    jal check_raw_hazard
    move $s3, $v0           # Stall cycles
    
    # Record producer
    move $a0, $t1           # rt
    move $a1, $s1           # instruction ID
    add $a2, $s2, $s3
    addiu $a2, $a2, 1
    jal record_producer
    
    j analyze_done
    
analyze_load:
    # Load: rt = MEM[rs + offset]
    srl $t0, $s0, 21
    andi $t0, $t0, 31       # rs (base)
    srl $t1, $s0, 16
    andi $t1, $t1, 31       # rt (destination)
    
    move $a0, $t0
    jal check_raw_hazard
    move $s3, $v0
    
    # Load has 2-cycle latency (access + writeback)
    move $a0, $t1
    move $a1, $s1
    add $a2, $s2, $s3
    addiu $a2, $a2, 2       # Load latency
    jal record_producer
    
    j analyze_done
    
analyze_store:
    # Store: MEM[rs + offset] = rt
    srl $t0, $s0, 21
    andi $t0, $t0, 31       # rs (base)
    srl $t1, $s0, 16
    andi $t1, $t1, 31       # rt (data)
    
    # Check dependencies for both source registers
    move $a0, $t0
    jal check_raw_hazard
    move $s3, $v0
    
    move $a0, $t1
    jal check_raw_hazard
    slt $t2, $s3, $v0
    beq $t2, $zero, base_longer
    move $s3, $v0
base_longer:
    
    # Store doesn't produce a register value
    j analyze_done
    
analyze_branch:
    # Branch: compare rs and rt
    srl $t0, $s0, 21
    andi $t0, $t0, 31       # rs
    srl $t1, $s0, 16
    andi $t1, $t1, 31       # rt
    
    # Check dependencies for both operands
    move $a0, $t0
    jal check_raw_hazard
    move $s3, $v0
    
    move $a0, $t1
    jal check_raw_hazard
    slt $t2, $s3, $v0
    beq $t2, $zero, branch_done
    move $s3, $v0
branch_done:
    
    # Branches don't produce register values
    
analyze_done:
    move $v0, $s3           # Return stall cycles needed
    
    lw $s3, 0($sp)
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    addiu $sp, $sp, 20
    jr $ra

check_raw_hazard:
    # $a0 = register number
    # $a2 = current cycle (from caller)
    # Returns: $v0 = stall cycles needed
    
    # Skip $zero register
    beq $a0, $zero, no_hazard
    
    # Check when register will be ready
    la $t0, reg_ready_time
    sll $t1, $a0, 2
    add $t0, $t0, $t1
    lw $t2, 0($t0)          # Ready time for this register
    
    # Calculate stall needed
    sub $v0, $t2, $s2       # ready_time - current_cycle
    bltz $v0, no_hazard     # Already ready
    jr $ra
    
no_hazard:
    li $v0, 0               # No stall needed
    jr $ra

record_producer:
    # $a0 = register number
    # $a1 = producer instruction ID
    # $a2 = ready time
    
    # Skip $zero register
    beq $a0, $zero, record_done
    
    # Update producer tracking
    la $t0, reg_producers
    sll $t1, $a0, 2
    add $t0, $t0, $t1
    sw $a1, 0($t0)
    
    # Update ready time
    la $t0, reg_ready_time
    add $t0, $t0, $t1
    sw $a2, 0($t0)
    
record_done:
    jr $ra
```

9) Advanced Forwarding Implementation

**Complete Forwarding Unit:**
```assembly
.data
# Pipeline register contents (simplified representation)
# EX/MEM stage
exmem_valid: .word 0
exmem_regwrite: .word 0
exmem_rd: .word 0
exmem_result: .word 0

# MEM/WB stage  
memwb_valid: .word 0
memwb_regwrite: .word 0
memwb_rd: .word 0
memwb_result: .word 0

.text
# Forwarding unit for EX stage
forwarding_unit:
    # $a0 = ID/EX.rs (source register 1)
    # $a1 = ID/EX.rt (source register 2)
    # $a2 = rs value from register file
    # $a3 = rt value from register file
    # Returns: $v0 = forwarded rs value, $v1 = forwarded rt value
    
    addiu $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)          # rs
    sw $s1, 4($sp)          # rt
    sw $s2, 0($sp)          # working register
    
    move $s0, $a0           # rs
    move $s1, $a1           # rt
    move $v0, $a2           # Default rs value
    move $v1, $a3           # Default rt value
    
    # Forward rs if needed
    jal forward_operand
    move $a0, $s0           # rs register number
    move $a1, $a2           # rs default value
    move $v0, $v0           # Store forwarded rs
    
    # Forward rt if needed
    move $a0, $s1           # rt register number
    move $a1, $a3           # rt default value
    jal forward_operand
    move $v1, $v0           # Store forwarded rt
    
    lw $s2, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addiu $sp, $sp, 16
    jr $ra

forward_operand:
    # $a0 = register number to forward
    # $a1 = default value from register file
    # Returns: $v0 = forwarded value
    
    move $v0, $a1           # Default to register file value
    
    # Skip $zero register
    beq $a0, $zero, forward_done
    
    # Check EX/MEM forwarding (higher priority)
    lw $t0, exmem_valid
    beq $t0, $zero, check_memwb
    lw $t1, exmem_regwrite
    beq $t1, $zero, check_memwb
    lw $t2, exmem_rd
    bne $t2, $a0, check_memwb
    
    # Forward from EX/MEM
    lw $v0, exmem_result
    j forward_done
    
check_memwb:
    # Check MEM/WB forwarding
    lw $t0, memwb_valid
    beq $t0, $zero, forward_done
    lw $t1, memwb_regwrite
    beq $t1, $zero, forward_done
    lw $t2, memwb_rd
    bne $t2, $a0, forward_done
    
    # Forward from MEM/WB
    lw $v0, memwb_result
    
forward_done:
    jr $ra

# Update pipeline registers (called each cycle)
update_pipeline_registers:
    # $a0 = new EX/MEM contents
    # $a1 = new MEM/WB contents
    # This would be more complex in reality
    
    # Move EX/MEM to MEM/WB
    lw $t0, exmem_valid
    sw $t0, memwb_valid
    lw $t0, exmem_regwrite
    sw $t0, memwb_regwrite
    lw $t0, exmem_rd
    sw $t0, memwb_rd
    lw $t0, exmem_result
    sw $t0, memwb_result
    
    # Update EX/MEM with new values
    # (In real implementation, would extract from pipeline)
    # For demo, just clear
    sw $zero, exmem_valid
    
    jr $ra
```

10) Load-Use Hazard Handling

**Load-Use Detection and Stalling:**
```assembly
.data
# ID/EX pipeline register contents
idex_memread: .word 0           # Is this a load instruction?
idex_rt: .word 0                # Destination register of load
idex_valid: .word 0

# Hazard detection unit state
stall_pipeline: .word 0         # Should pipeline stall?
flush_ifid: .word 0             # Should flush IF/ID?

.text
# Hazard detection for load-use
detect_load_use_hazard:
    # $a0 = IF/ID.rs (current instruction source 1)
    # $a1 = IF/ID.rt (current instruction source 2)  
    # $a2 = IF/ID opcode (to determine if current is branch/jump)
    
    addiu $sp, $sp, -12
    sw $ra, 8($sp)
    sw $a0, 4($sp)
    sw $a1, 0($sp)
    
    # Check if there's a load in EX stage
    lw $t0, idex_valid
    beq $t0, $zero, no_load_hazard
    lw $t1, idex_memread
    beq $t1, $zero, no_load_hazard
    
    # Get load destination register
    lw $t2, idex_rt
    
    # Check if current instruction reads the load destination
    beq $t2, $a0, load_use_hazard   # Hazard with rs
    beq $t2, $a1, load_use_hazard   # Hazard with rt
    
    # Special case: branch instructions need both operands in ID stage
    li $t3, 4               # beq opcode
    beq $a2, $t3, branch_hazard_check
    li $t3, 5               # bne opcode  
    beq $a2, $t3, branch_hazard_check
    
    j no_load_hazard
    
branch_hazard_check:
    # Branch needs operands immediately, cannot wait for forwarding
    beq $t2, $a0, load_use_hazard
    beq $t2, $a1, load_use_hazard
    j no_load_hazard
    
load_use_hazard:
    # Stall the pipeline
    li $t0, 1
    sw $t0, stall_pipeline
    sw $t0, flush_ifid      # Also need to flush IF/ID
    
    # Insert nop in EX stage (bubble)
    jal insert_pipeline_bubble
    
    li $v0, 1               # Hazard detected
    j hazard_check_done
    
no_load_hazard:
    sw $zero, stall_pipeline
    sw $zero, flush_ifid
    li $v0, 0               # No hazard
    
hazard_check_done:
    lw $a1, 0($sp)
    lw $a0, 4($sp)
    lw $ra, 8($sp)
    addiu $sp, $sp, 12
    jr $ra

insert_pipeline_bubble:
    # Insert a bubble (nop) into the pipeline
    # Clear EX stage control signals
    sw $zero, idex_memread
    sw $zero, idex_rt
    # In real implementation, would clear all EX control signals
    jr $ra

# Advanced load-use optimization: load-use scheduling
optimize_load_use:
    # Attempt to schedule independent instructions between load and use
    # $a0 = pointer to instruction stream
    # $a1 = number of instructions
    
    addiu $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)         # instruction pointer
    sw $s1, 8($sp)          # instruction count
    sw $s2, 4($sp)          # current instruction
    sw $s3, 0($sp)          # next instruction
    
    move $s0, $a0
    move $s1, $a1
    li $t0, 0               # index
    
optimize_loop:
    bge $t0, $s1, optimize_done
    
    # Get current instruction
    sll $t1, $t0, 2
    add $t2, $s0, $t1
    lw $s2, 0($t2)          # Current instruction
    
    # Check if it's a load
    srl $t3, $s2, 26        # Extract opcode
    li $t4, 35              # lw opcode
    bne $t3, $t4, next_instruction
    
    # Found a load - check next instruction
    addiu $t5, $t0, 1       # Next index
    bge $t5, $s1, next_instruction
    
    sll $t6, $t5, 2
    add $t7, $s0, $t6
    lw $s3, 0($t7)          # Next instruction
    
    # Check if next instruction uses load result
    jal check_load_use_dependency
    move $a0, $s2           # Load instruction
    move $a1, $s3           # Potential user instruction
    
    beq $v0, $zero, next_instruction    # No dependency
    
    # Found load-use pair - try to find instruction to move between them
    addiu $t8, $t0, 2       # Start searching from instruction after user
    
search_independent:
    bge $t8, $s1, next_instruction
    
    sll $t9, $t8, 2
    add $s4, $s0, $t9
    lw $s5, 0($s4)          # Candidate instruction
    
    # Check if candidate is independent of load and user
    jal check_independence
    move $a0, $s2           # Load
    move $a1, $s3           # User
    move $a2, $s5           # Candidate
    
    beq $v0, $zero, try_next_candidate
    
    # Found independent instruction - move it between load and user
    sw $s5, 0($t7)          # Move candidate to position after load
    sw $s3, 0($s4)          # Move user to candidate's position
    
    # Optimization successful
    j next_instruction
    
try_next_candidate:
    addiu $t8, $t8, 1
    j search_independent
    
next_instruction:
    addiu $t0, $t0, 1
    j optimize_loop
    
optimize_done:
    lw $s3, 0($sp)
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    addiu $sp, $sp, 20
    jr $ra

check_load_use_dependency:
    # $a0 = load instruction, $a1 = potential user instruction
    # Returns: $v0 = 1 if dependency exists, 0 otherwise
    
    # Extract load destination (rt field)
    srl $t0, $a0, 16
    andi $t0, $t0, 31       # Load rt
    
    # Extract user source registers
    srl $t1, $a1, 21        # User rs
    andi $t1, $t1, 31
    srl $t2, $a1, 16        # User rt  
    andi $t2, $t2, 31
    
    # Check for dependency
    beq $t0, $t1, dependency_found
    beq $t0, $t2, dependency_found
    
    li $v0, 0               # No dependency
    jr $ra
    
dependency_found:
    li $v0, 1               # Dependency exists
    jr $ra

check_independence:
    # $a0 = load instruction
    # $a1 = user instruction  
    # $a2 = candidate instruction
    # Returns: $v0 = 1 if candidate is independent, 0 otherwise
    
    # Simplified independence check
    # Real implementation would check:
    # 1. Candidate doesn't use load result
    # 2. Candidate doesn't interfere with user's sources
    # 3. No other dependencies exist
    
    # For demo, assume independence
    li $v0, 1
    jr $ra
```

11) Branch Target Buffer Implementation

**Dynamic Branch Prediction with BTB:**
```assembly
.data
# Branch Target Buffer entries
BTB_SIZE = 128
btb_tags: .space 512            # 128 * 4 bytes (tag + valid)
btb_targets: .space 512         # 128 * 4 bytes (target addresses)
btb_predictions: .space 128     # 128 * 1 byte (2-bit predictors)

# Return Address Stack for function calls
RAS_SIZE = 16
return_stack: .space 64         # 16 * 4 bytes
ras_top: .word 0

.text
# Initialize branch predictor
init_branch_predictor_advanced:
    # Clear BTB
    la $t0, btb_tags
    la $t1, btb_targets  
    la $t2, btb_predictions
    li $t3, BTB_SIZE
    
init_btb:
    beq $t3, $zero, init_ras
    sw $zero, 0($t0)        # Clear tag (valid = 0)
    sw $zero, 0($t1)        # Clear target
    li $t4, 1               # Weakly not taken
    sb $t4, 0($t2)          # Initialize predictor
    
    addiu $t0, $t0, 4
    addiu $t1, $t1, 4
    addiu $t2, $t2, 1
    addiu $t3, $t3, -1
    j init_btb
    
init_ras:
    # Clear return address stack
    la $t0, return_stack
    li $t1, RAS_SIZE
    
init_ras_loop:
    beq $t1, $zero, init_predictor_done
    sw $zero, 0($t0)
    addiu $t0, $t0, 4
    addiu $t1, $t1, -1
    j init_ras_loop
    
init_predictor_done:
    sw $zero, ras_top
    jr $ra

# Predict branch outcome and target
predict_branch_advanced:
    # $a0 = branch PC
    # $a1 = instruction (to determine branch type)
    # Returns: $v0 = prediction (1=taken), $v1 = target address
    
    addiu $sp, $sp, -12
    sw $ra, 8($sp)
    sw $a0, 4($sp)
    sw $a1, 0($sp)
    
    # Determine branch type
    srl $t0, $a1, 26        # Extract opcode
    
    # Check for function call (jal)
    li $t1, 3               # jal opcode
    beq $t0, $t1, predict_call
    
    # Check for function return (jr $ra)
    beq $t0, $zero, check_jr    # R-type
    j predict_conditional
    
check_jr:
    # Check if it's jr $ra (return)
    srl $t2, $a1, 21        # rs field
    andi $t2, $t2, 31
    li $t3, 31              # $ra register
    beq $t2, $t3, predict_return
    j predict_indirect
    
predict_call:
    # Function call - always predict taken
    # Calculate target from J-type instruction
    andi $t0, $a1, 0x3FFFFFF # Extract 26-bit target
    sll $t0, $t0, 2         # Shift left 2 (word alignment)
    lw $t1, 4($sp)          # Get PC
    addiu $t1, $t1, 4       # PC + 4
    srl $t2, $t1, 28        # Upper 4 bits of PC+4
    sll $t2, $t2, 28
    or $v1, $t2, $t0        # Combine upper PC bits with target
    
    # Push return address onto RAS
    addiu $t3, $t1, 4       # Return address = PC + 8
    jal ras_push
    move $a0, $t3
    
    li $v0, 1               # Always predict taken
    j predict_done
    
predict_return:
    # Function return - predict taken, target from RAS
    jal ras_pop
    move $v1, $v0           # Target from RAS
    beq $v1, $zero, predict_fallthrough
    li $v0, 1               # Predict taken if RAS not empty
    j predict_done
    
predict_indirect:
    # Indirect jump - use BTB
    lw $a0, 4($sp)          # Get PC
    jal btb_lookup
    # $v0 = prediction, $v1 = target (set by btb_lookup)
    j predict_done
    
predict_conditional:
    # Conditional branch - use BTB + 2-bit predictor
    lw $a0, 4($sp)          # Get PC
    jal btb_lookup
    # $v0 = prediction, $v1 = target
    
    beq $v0, $zero, predict_fallthrough
    j predict_done
    
predict_fallthrough:
    # Predict not taken - target is PC + 4
    lw $v1, 4($sp)          # Get PC
    addiu $v1, $v1, 4       # PC + 4
    li $v0, 0               # Not taken
    
predict_done:
    lw $a1, 0($sp)
    lw $a0, 4($sp)
    lw $ra, 8($sp)
    addiu $sp, $sp, 12
    jr $ra

# BTB lookup
btb_lookup:
    # $a0 = PC
    # Returns: $v0 = prediction, $v1 = target
    
    # Hash PC to get BTB index
    srl $t0, $a0, 2         # Remove alignment bits
    andi $t0, $t0, 127      # Modulo BTB_SIZE
    
    # Check BTB entry
    la $t1, btb_tags
    sll $t2, $t0, 2         # index * 4
    add $t1, $t1, $t2
    lw $t3, 0($t1)          # Load tag entry
    
    # Extract valid bit and tag
    andi $t4, $t3, 1        # Valid bit (LSB)
    beq $t4, $zero, btb_miss
    
    srl $t5, $t3, 1         # Extract tag
    srl $t6, $a0, 7         # PC tag (remove index + alignment bits)
    bne $t5, $t6, btb_miss
    
btb_hit:
    # Get prediction from 2-bit counter
    la $t1, btb_predictions
    add $t1, $t1, $t0       # &predictions[index]
    lbu $t2, 0($t1)         # Load 2-bit counter
    
    srl $v0, $t2, 1         # Prediction = counter[1]
    andi $v0, $v0, 1
    
    # Get target address
    la $t1, btb_targets
    sll $t2, $t0, 2
    add $t1, $t1, $t2
    lw $v1, 0($t1)          # Load target
    
    jr $ra
    
btb_miss:
    # Default prediction (not taken, PC+4)
    li $v0, 0
    addiu $v1, $a0, 4
    jr $ra

# Update BTB with actual outcome
update_btb:
    # $a0 = PC, $a1 = taken (1/0), $a2 = actual target
    
    # Hash PC to get index
    srl $t0, $a0, 2
    andi $t0, $t0, 127
    
    # Update 2-bit predictor
    la $t1, btb_predictions
    add $t1, $t1, $t0
    lbu $t2, 0($t1)         # Current counter
    
    beq $a1, $zero, update_not_taken
    
update_taken:
    # Increment counter (saturate at 3)
    addiu $t3, $t2, 1
    slti $t4, $t3, 4
    bne $t4, $zero, store_counter
    li $t3, 3
    j store_counter
    
update_not_taken:
    # Decrement counter (saturate at 0)
    addiu $t3, $t2, -1
    bgez $t3, store_counter
    li $t3, 0
    
store_counter:
    sb $t3, 0($t1)
    
    # Update BTB entry if branch was taken
    beq $a1, $zero, update_done
    
    # Install/update BTB entry
    la $t1, btb_tags
    sll $t2, $t0, 2
    add $t1, $t1, $t2
    
    srl $t3, $a0, 7         # PC tag
    sll $t3, $t3, 1         # Make room for valid bit
    ori $t3, $t3, 1         # Set valid bit
    sw $t3, 0($t1)          # Store tag
    
    la $t1, btb_targets
    add $t1, $t1, $t2
    sw $a2, 0($t1)          # Store target
    
update_done:
    jr $ra

# Return Address Stack operations
ras_push:
    # $a0 = return address
    lw $t0, ras_top
    li $t1, RAS_SIZE
    beq $t0, $t1, ras_full
    
    la $t2, return_stack
    sll $t3, $t0, 2
    add $t2, $t2, $t3
    sw $a0, 0($t2)          # Push address
    
    addiu $t0, $t0, 1       # Increment top
    sw $t0, ras_top
    jr $ra
    
ras_full:
    # RAS overflow - could implement circular buffer
    jr $ra

ras_pop:
    # Returns: $v0 = popped address (0 if empty)
    lw $t0, ras_top
    beq $t0, $zero, ras_empty
    
    addiu $t0, $t0, -1      # Decrement top
    sw $t0, ras_top
    
    la $t1, return_stack
    sll $t2, $t0, 2
    add $t1, $t1, $t2
    lw $v0, 0($t1)          # Pop address
    jr $ra
    
ras_empty:
    li $v0, 0               # Return 0 if empty
    jr $ra
```

Kết luận nâng cao
Hazard management trong pipeline architecture представляет собой complex interplay между:

1. **Detection Mechanisms**: Static analysis, dynamic monitoring, compiler assistance
2. **Resolution Strategies**: Stalling, forwarding, speculation, scheduling
3. **Performance Trade-offs**: Hardware complexity vs execution efficiency
4. **Advanced Techniques**: Out-of-order execution, register renaming, branch prediction
5. **Software Cooperation**: Compiler optimization, instruction scheduling

Critical insights:
- **Hazard types interact**: Data hazards affect control hazards affect structural hazards
- **Forwarding networks** are essential для high-performance pipelines  
- **Branch prediction accuracy** dramatically impacts overall performance
- **Load-use hazards** являются particularly challenging для RISC architectures
- **Compiler scheduling** can significantly reduce hazard penalties
- **Advanced prediction** techniques enable deeper pipelines

Real-world applications:
- **Processor Design**: Modern CPUs implement sophisticated hazard resolution
- **Compiler Optimization**: Instruction scheduling, software pipelining
- **Performance Analysis**: Understanding bottlenecks, tuning critical code
- **Architecture Research**: New techniques for hazard reduction
- **Embedded Systems**: Power-efficient hazard management

Advanced concepts showcase:
- **Superscalar Execution**: Multiple instruction issue, register renaming
- **Speculative Execution**: Branch prediction, value prediction
- **Memory Disambiguation**: Load-store ordering, cache coherence
- **Power Management**: Clock gating, voltage scaling based on hazard patterns

Hazard management skills essential для:
- **Systems Programmers**: Writing pipeline-friendly code
- **Compiler Writers**: Implementing effective instruction scheduling
- **Hardware Designers**: Creating efficient pipeline implementations  
- **Performance Engineers**: Optimizing critical code paths
- **Computer Architects**: Designing next-generation processors

Understanding hazards и их resolution является fundamental для mastering computer architecture и writing high-performance software that effectively utilizes modern processor capabilities.

