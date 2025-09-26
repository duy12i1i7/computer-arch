Tuần 10 — Memory Hierarchy: Cache Systems, Locality Principles, và Performance Analysis

## Introduction to Memory Hierarchy

Memory hierarchy design is a fundamental aspect of computer architecture that bridges the gap between fast, expensive storage (registers, cache) and slow, inexpensive storage (DRAM, disk). Understanding memory hierarchy is crucial for writing high-performance code and designing efficient computer systems.

**Memory Hierarchy Levels:**
```
                Speed    Size     Cost/bit    Access Time
Registers:      Fastest  Smallest  Highest    < 1 cycle
L1 Cache:       Fast     Small     High       1-2 cycles  
L2 Cache:       Medium   Medium    Medium     3-10 cycles
L3 Cache:       Slower   Large     Lower      10-30 cycles
Main Memory:    Slow     Large     Low        100-300 cycles
Secondary:      Slowest  Largest   Lowest     10^6 cycles
```

1) Understanding Locality Principles

**Temporal Locality Analysis:**
```assembly
.data
array: .space 1000          # 250-word array
counter: .space 4

.text
# Poor temporal locality example
poor_temporal_example:
    li $t0, 0               # counter
    li $t1, 250             # array size
    
poor_loop:
    beq $t0, $t1, poor_done
    
    # Load counter from memory each time (poor temporal locality)
    lw $t2, counter
    la $t3, array
    sll $t4, $t0, 2         # offset = i * 4
    add $t3, $t3, $t4
    lw $t5, 0($t3)          # array[i]
    
    # Process element
    addiu $t5, $t5, 1
    sw $t5, 0($t3)
    
    # Store counter back (unnecessary memory traffic)
    addiu $t2, $t2, 1
    sw $t2, counter
    
    addiu $t0, $t0, 1
    j poor_loop
    
poor_done:
    jr $ra

# Good temporal locality example
good_temporal_example:
    li $t0, 0               # Keep counter in register
    li $t1, 250             # Array size
    la $t2, array           # Keep base address in register
    
good_loop:
    beq $t0, $t1, good_done
    
    sll $t3, $t0, 2         # offset = i * 4
    add $t4, $t2, $t3       # address = base + offset
    lw $t5, 0($t4)          # array[i] - good spatial locality
    
    # Process element
    addiu $t5, $t5, 1
    sw $t5, 0($t4)
    
    addiu $t0, $t0, 1       # Increment counter in register
    j good_loop
    
good_done:
    jr $ra

# Temporal locality with data reuse
matrix_multiply_temporal:
    # C[i][j] += A[i][k] * B[k][j]
    # Demonstrates temporal locality in C[i][j] access
    
    li $t0, 0               # i
    li $t1, 4               # matrix size (4x4)
    
i_loop:
    beq $t0, $t1, mult_done
    li $t2, 0               # j
    
j_loop:
    beq $t2, $t1, next_i
    
    # Load C[i][j] once for entire k loop (temporal locality)
    la $t3, matrix_c
    mul $t4, $t0, $t1       # i * size
    add $t4, $t4, $t2       # + j
    sll $t4, $t4, 2         # * 4 (word size)
    add $t3, $t3, $t4
    lw $t5, 0($t3)          # C[i][j] - will be reused
    
    li $t6, 0               # k
    
k_loop:
    beq $t6, $t1, store_c
    
    # Load A[i][k]
    la $t7, matrix_a
    mul $t8, $t0, $t1       # i * size
    add $t8, $t8, $t6       # + k
    sll $t8, $t8, 2
    add $t7, $t7, $t8
    lw $t8, 0($t7)          # A[i][k]
    
    # Load B[k][j]
    la $t7, matrix_b
    mul $t9, $t6, $t1       # k * size
    add $t9, $t9, $t2       # + j
    sll $t9, $t9, 2
    add $t7, $t7, $t9
    lw $t9, 0($t7)          # B[k][j]
    
    # Multiply and accumulate
    mul $s0, $t8, $t9       # A[i][k] * B[k][j]
    add $t5, $t5, $s0       # C[i][j] += product
    
    addiu $t6, $t6, 1
    j k_loop
    
store_c:
    sw $t5, 0($t3)          # Store accumulated C[i][j]
    
    addiu $t2, $t2, 1
    j j_loop
    
next_i:
    addiu $t0, $t0, 1
    j i_loop
    
mult_done:
    jr $ra
```

**Spatial Locality Patterns:**
```assembly
.data
matrix: .space 1024         # 16x16 integer matrix
vector: .space 64           # 16-element vector

.text
# Poor spatial locality - column-major access on row-major data
poor_spatial_access:
    li $t0, 0               # column index
    li $t1, 16              # matrix dimension
    
column_loop:
    beq $t0, $t1, column_done
    li $t2, 0               # row index
    
row_loop:
    beq $t2, $t1, next_column
    
    # Access matrix[row][column] - poor spatial locality
    # Address = base + (row * 16 + column) * 4
    la $t3, matrix
    mul $t4, $t2, $t1       # row * 16
    add $t4, $t4, $t0       # + column
    sll $t4, $t4, 2         # * 4 bytes
    add $t3, $t3, $t4
    lw $t5, 0($t3)          # Load with poor cache utilization
    
    # Process element
    addiu $t5, $t5, 1
    sw $t5, 0($t3)
    
    addiu $t2, $t2, 1
    j row_loop
    
next_column:
    addiu $t0, $t0, 1
    j column_loop
    
column_done:
    jr $ra

# Good spatial locality - row-major access
good_spatial_access:
    li $t0, 0               # row index
    li $t1, 16              # matrix dimension
    
row_major_loop:
    beq $t0, $t1, row_done
    li $t2, 0               # column index
    
    # Calculate row base address once
    la $t3, matrix
    mul $t4, $t0, $t1       # row * 16
    sll $t4, $t4, 2         # * 4 bytes
    add $t3, $t3, $t4       # Base address for this row
    
column_major_loop:
    beq $t2, $t1, next_row
    
    # Access consecutive elements - excellent spatial locality
    sll $t5, $t2, 2         # column * 4
    add $t6, $t3, $t5       # row_base + column_offset
    lw $t7, 0($t6)          # Sequential access pattern
    
    # Process element
    addiu $t7, $t7, 1
    sw $t7, 0($t6)
    
    addiu $t2, $t2, 1
    j column_major_loop
    
next_row:
    addiu $t0, $t0, 1
    j row_major_loop
    
row_done:
    jr $ra

# Advanced spatial locality - blocking/tiling
blocked_matrix_multiply:
    # Block size = 4x4 to improve cache utilization
    li $s0, 16              # Matrix dimension
    li $s1, 4               # Block size
    li $t0, 0               # Block row index
    
block_i_loop:
    add $t1, $t0, $s1       # Block end
    bge $t1, $s0, blocked_done
    li $t2, 0               # Block column index
    
block_j_loop:
    add $t3, $t2, $s1       # Block end
    bge $t3, $s0, next_block_i
    li $t4, 0               # Block k index
    
block_k_loop:
    add $t5, $t4, $s1       # Block end
    bge $t5, $s0, next_block_j
    
    # Process 4x4 block with good spatial locality
    move $a0, $t0           # Block i start
    move $a1, $t1           # Block i end
    move $a2, $t2           # Block j start
    move $a3, $t3           # Block j end
    addiu $sp, $sp, -8
    sw $t4, 4($sp)          # Block k start
    sw $t5, 0($sp)          # Block k end
    
    jal multiply_block
    
    lw $t5, 0($sp)
    lw $t4, 4($sp)
    addiu $sp, $sp, 8
    
    add $t4, $t4, $s1       # Next k block
    j block_k_loop
    
next_block_j:
    add $t2, $t2, $s1       # Next j block
    j block_j_loop
    
next_block_i:
    add $t0, $t0, $s1       # Next i block
    j block_i_loop
    
blocked_done:
    jr $ra

multiply_block:
    # Multiply a 4x4 block with optimal spatial locality
    # Arguments: $a0-$a3 = block boundaries, stack has k boundaries
    
    lw $t8, 4($sp)          # k start
    lw $t9, 8($sp)          # k end
    move $t0, $a0           # i
    
block_mult_i:
    bge $t0, $a1, block_mult_done
    move $t1, $a2           # j
    
block_mult_j:
    bge $t1, $a3, block_mult_next_i
    
    # Load C[i][j] once for k loop
    la $t2, matrix_c
    li $t3, 16              # matrix dimension
    mul $t4, $t0, $t3       # i * 16
    add $t4, $t4, $t1       # + j
    sll $t4, $t4, 2         # * 4
    add $t2, $t2, $t4
    lw $t5, 0($t2)          # C[i][j]
    
    move $t6, $t8           # k
    
block_mult_k:
    bge $t6, $t9, block_store_c
    
    # A[i][k] - good spatial locality in i dimension
    la $t7, matrix_a
    mul $s0, $t0, $t3       # i * 16
    add $s0, $s0, $t6       # + k
    sll $s0, $s0, 2
    add $t7, $t7, $s0
    lw $s0, 0($t7)          # A[i][k]
    
    # B[k][j] - reasonable locality
    la $t7, matrix_b
    mul $s1, $t6, $t3       # k * 16
    add $s1, $s1, $t1       # + j
    sll $s1, $s1, 2
    add $t7, $t7, $s1
    lw $s1, 0($t7)          # B[k][j]
    
    mul $s2, $s0, $s1       # A[i][k] * B[k][j]
    add $t5, $t5, $s2       # Accumulate
    
    addiu $t6, $t6, 1
    j block_mult_k
    
block_store_c:
    sw $t5, 0($t2)          # Store C[i][j]
    
    addiu $t1, $t1, 1
    j block_mult_j
    
block_mult_next_i:
    addiu $t0, $t0, 1
    j block_mult_i
    
block_mult_done:
    jr $ra
```

2) Cache Organization and Design

**Direct-Mapped Cache Simulation:**
```assembly
.data
# Cache parameters
CACHE_SIZE = 1024           # 1KB cache
BLOCK_SIZE = 16             # 16-byte blocks
NUM_BLOCKS = 64             # CACHE_SIZE / BLOCK_SIZE
INDEX_BITS = 6              # log2(NUM_BLOCKS)
OFFSET_BITS = 4             # log2(BLOCK_SIZE)
TAG_BITS = 22               # 32 - INDEX_BITS - OFFSET_BITS

# Cache data structure
cache_valid: .space 64      # Valid bits (1 bit per block)
cache_tags: .space 256      # Tags (4 bytes per block)
cache_data: .space 1024     # Data (16 bytes per block)

# Statistics
cache_hits: .word 0
cache_misses: .word 0
cache_accesses: .word 0

# Memory simulation (4KB)
main_memory: .space 4096

.text
# Initialize cache
init_cache:
    # Clear valid bits
    la $t0, cache_valid
    li $t1, NUM_BLOCKS
    
clear_valid:
    beq $t1, $zero, clear_tags
    sb $zero, 0($t0)
    addiu $t0, $t0, 1
    addiu $t1, $t1, -1
    j clear_valid
    
clear_tags:
    # Clear tags
    la $t0, cache_tags
    li $t1, NUM_BLOCKS
    
clear_tag_loop:
    beq $t1, $zero, clear_data
    sw $zero, 0($t0)
    addiu $t0, $t0, 4
    addiu $t1, $t1, -1
    j clear_tag_loop
    
clear_data:
    # Clear data (optional)
    la $t0, cache_data
    li $t1, CACHE_SIZE
    
clear_data_loop:
    beq $t1, $zero, clear_stats
    sb $zero, 0($t0)
    addiu $t0, $t0, 1
    addiu $t1, $t1, -1
    j clear_data_loop
    
clear_stats:
    # Clear statistics
    sw $zero, cache_hits
    sw $zero, cache_misses
    sw $zero, cache_accesses
    
    jr $ra

# Cache lookup and access
cache_access:
    # $a0 = memory address
    # $a1 = access type (0=read, 1=write)
    # $a2 = data (for writes)
    # Returns: $v0 = data (for reads), $v1 = hit(1)/miss(0)
    
    addiu $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)         # address
    sw $s1, 8($sp)          # access type
    sw $s2, 4($sp)          # data
    sw $s3, 0($sp)          # working register
    
    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    
    # Update access counter
    lw $t0, cache_accesses
    addiu $t0, $t0, 1
    sw $t0, cache_accesses
    
    # Extract address fields
    # Offset = address[3:0]
    andi $t0, $s0, 15       # Offset bits
    
    # Index = address[9:4]
    srl $t1, $s0, 4         # Shift right 4
    andi $t1, $t1, 63       # Extract 6 bits
    
    # Tag = address[31:10]
    srl $t2, $s0, 10        # Shift right 10
    
    # Check cache hit
    # Get valid bit
    la $t3, cache_valid
    add $t3, $t3, $t1       # &valid[index]
    lbu $t4, 0($t3)         # Load valid bit
    
    beq $t4, $zero, cache_miss  # Invalid block
    
    # Check tag match
    la $t3, cache_tags
    sll $t5, $t1, 2         # index * 4
    add $t3, $t3, $t5       # &tags[index]
    lw $t6, 0($t3)          # Load stored tag
    
    bne $t6, $t2, cache_miss    # Tag mismatch
    
cache_hit:
    # Update hit counter
    lw $t0, cache_hits
    addiu $t0, $t0, 1
    sw $t0, cache_hits
    
    # Calculate data address in cache
    la $t3, cache_data
    sll $t4, $t1, 4         # index * BLOCK_SIZE
    add $t3, $t3, $t4       # Block base address
    add $t3, $t3, $t0       # + offset
    
    beq $s1, $zero, cache_read_hit
    
cache_write_hit:
    # Write data to cache
    sw $s2, 0($t3)
    # In write-through, would also write to memory
    # In write-back, would set dirty bit
    li $v1, 1               # Signal hit
    j cache_access_done
    
cache_read_hit:
    # Read data from cache
    lw $v0, 0($t3)
    li $v1, 1               # Signal hit
    j cache_access_done
    
cache_miss:
    # Update miss counter
    lw $t0, cache_misses
    addiu $t0, $t0, 1
    sw $t0, cache_misses
    
    # Load block from memory
    jal load_block_from_memory
    move $a0, $s0           # Address
    move $a1, $t1           # Index
    move $a2, $t2           # Tag
    
    # Retry access after loading block
    beq $s1, $zero, cache_read_miss
    
cache_write_miss:
    # Handle write miss (depends on write-allocate policy)
    # For write-allocate: block is now loaded, perform write
    la $t3, cache_data
    sll $t4, $t1, 4         # index * BLOCK_SIZE
    add $t3, $t3, $t4       # Block base
    andi $t5, $s0, 15       # Offset
    add $t3, $t3, $t5       # Final address
    sw $s2, 0($t3)          # Write data
    
    li $v1, 0               # Signal miss
    j cache_access_done
    
cache_read_miss:
    # Read data from newly loaded block
    la $t3, cache_data
    sll $t4, $t1, 4         # index * BLOCK_SIZE
    add $t3, $t3, $t4       # Block base
    andi $t5, $s0, 15       # Offset
    add $t3, $t3, $t5       # Final address
    lw $v0, 0($t3)          # Read data
    
    li $v1, 0               # Signal miss
    
cache_access_done:
    lw $s3, 0($sp)
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    addiu $sp, $sp, 20
    jr $ra

load_block_from_memory:
    # $a0 = address, $a1 = cache index, $a2 = tag
    
    # Calculate block-aligned address
    srl $t0, $a0, 4         # Remove offset bits
    sll $t0, $t0, 4         # Block-aligned address
    
    # Set valid bit and tag
    la $t1, cache_valid
    add $t1, $t1, $a1       # &valid[index]
    li $t2, 1
    sb $t2, 0($t1)          # Set valid
    
    la $t1, cache_tags
    sll $t2, $a1, 2         # index * 4
    add $t1, $t1, $t2       # &tags[index]
    sw $a2, 0($t1)          # Store tag
    
    # Copy block from memory to cache
    la $t1, main_memory
    add $t1, $t1, $t0       # Memory block address
    
    la $t2, cache_data
    sll $t3, $a1, 4         # index * BLOCK_SIZE
    add $t2, $t2, $t3       # Cache block address
    
    li $t4, BLOCK_SIZE      # Bytes to copy
    
copy_loop:
    beq $t4, $zero, copy_done
    lbu $t5, 0($t1)         # Load from memory
    sb $t5, 0($t2)          # Store to cache
    addiu $t1, $t1, 1
    addiu $t2, $t2, 1
    addiu $t4, $t4, -1
    j copy_loop
    
copy_done:
    jr $ra
```

**Set-Associative Cache Implementation:**
```assembly
.data
# 2-way set-associative cache parameters
ASSOC_CACHE_SIZE = 1024     # 1KB cache
ASSOC_BLOCK_SIZE = 16       # 16-byte blocks
ASSOC_WAYS = 2              # 2-way associative
ASSOC_NUM_SETS = 32         # CACHE_SIZE / (BLOCK_SIZE * WAYS)
ASSOC_SET_BITS = 5          # log2(NUM_SETS)

# Cache data structures (2 ways)
assoc_valid: .space 64      # Valid bits (32 sets * 2 ways)
assoc_tags: .space 256      # Tags (32 sets * 2 ways * 4 bytes)
assoc_data: .space 1024     # Data (32 sets * 2 ways * 16 bytes)
assoc_lru: .space 32        # LRU bits (1 bit per set)

.text
# Set-associative cache access
assoc_cache_access:
    # $a0 = address, $a1 = access type, $a2 = data
    # Returns: $v0 = data, $v1 = hit/miss, $v2 = way_used
    
    addiu $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)          # address
    sw $s1, 4($sp)          # set index
    sw $s2, 0($sp)          # tag
    
    move $s0, $a0
    
    # Extract address fields
    andi $t0, $s0, 15       # Offset
    srl $s1, $s0, 4         # Shift right 4
    andi $s1, $s1, 31       # Set index (5 bits)
    srl $s2, $s0, 9         # Tag (shift right 9)
    
    # Check both ways for hit
    li $t1, 0               # Way 0
    jal check_assoc_way
    move $a0, $s1           # Set index
    move $a1, $s2           # Tag
    move $a2, $t1           # Way
    
    beq $v0, $zero, check_way1  # Way 0 miss
    
    # Way 0 hit
    move $v2, $t1           # Return way 0
    j assoc_hit_found
    
check_way1:
    li $t1, 1               # Way 1
    jal check_assoc_way
    move $a0, $s1           # Set index
    move $a1, $s2           # Tag
    move $a2, $t1           # Way
    
    beq $v0, $zero, assoc_miss  # Both ways miss
    
    # Way 1 hit
    move $v2, $t1           # Return way 1
    
assoc_hit_found:
    # Update LRU (set bit to indicate which way was used)
    la $t2, assoc_lru
    add $t2, $t2, $s1       # &lru[set]
    lbu $t3, 0($t2)         # Current LRU bit
    
    beq $v2, $zero, set_lru_way0
    # Way 1 used - set LRU bit to 0 (way 0 is LRU)
    sb $zero, 0($t2)
    j perform_assoc_access
    
set_lru_way0:
    # Way 0 used - set LRU bit to 1 (way 1 is LRU)
    li $t4, 1
    sb $t4, 0($t2)
    
perform_assoc_access:
    # Perform actual read/write
    jal perform_way_access
    move $a0, $s1           # Set
    move $a1, $v2           # Way
    move $a2, $t0           # Offset
    # $a1 (access type) and $a2 (data) already set
    
    li $v1, 1               # Hit
    j assoc_access_done
    
assoc_miss:
    # Find replacement way using LRU
    la $t2, assoc_lru
    add $t2, $t2, $s1       # &lru[set]
    lbu $t3, 0($t2)         # LRU bit
    # LRU bit indicates which way to replace
    move $v2, $t3           # Victim way
    
    # Load block into victim way
    jal load_assoc_block
    move $a0, $s0           # Address
    move $a1, $s1           # Set
    move $a2, $v2           # Way
    move $a3, $s2           # Tag
    
    # Update LRU (opposite of victim way)
    li $t4, 1
    sub $t4, $t4, $v2       # 1 - way
    sb $t4, 0($t2)          # Update LRU
    
    # Perform access on newly loaded block
    jal perform_way_access
    move $a0, $s1           # Set
    move $a1, $v2           # Way  
    move $a2, $t0           # Offset
    
    li $v1, 0               # Miss
    
assoc_access_done:
    lw $s2, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addiu $sp, $sp, 16
    jr $ra

check_assoc_way:
    # $a0 = set, $a1 = tag, $a2 = way
    # Returns: $v0 = hit(1)/miss(0)
    
    # Calculate valid bit index
    sll $t0, $a0, 1         # set * 2
    add $t0, $t0, $a2       # + way
    
    # Check valid bit
    la $t1, assoc_valid
    add $t1, $t1, $t0       # &valid[set][way]
    lbu $t2, 0($t1)         # Load valid bit
    beq $t2, $zero, way_miss
    
    # Check tag
    la $t1, assoc_tags
    sll $t3, $t0, 2         # index * 4
    add $t1, $t1, $t3       # &tags[set][way]
    lw $t4, 0($t1)          # Load stored tag
    
    beq $t4, $a1, way_hit
    
way_miss:
    li $v0, 0               # Miss
    jr $ra
    
way_hit:
    li $v0, 1               # Hit
    jr $ra

load_assoc_block:
    # $a0 = address, $a1 = set, $a2 = way, $a3 = tag
    
    # Set valid bit
    sll $t0, $a1, 1         # set * 2
    add $t0, $t0, $a2       # + way
    
    la $t1, assoc_valid
    add $t1, $t1, $t0       # &valid[set][way]
    li $t2, 1
    sb $t2, 0($t1)          # Set valid
    
    # Set tag
    la $t1, assoc_tags
    sll $t3, $t0, 2         # index * 4
    add $t1, $t1, $t3       # &tags[set][way]
    sw $a3, 0($t1)          # Store tag
    
    # Load data block from memory
    srl $t4, $a0, 4         # Block-aligned address
    sll $t4, $t4, 4
    
    la $t1, main_memory
    add $t1, $t1, $t4       # Memory address
    
    la $t2, assoc_data
    sll $t3, $t0, 4         # (set*2+way) * BLOCK_SIZE
    add $t2, $t2, $t3       # Cache block address
    
    li $t5, ASSOC_BLOCK_SIZE
    
assoc_copy_loop:
    beq $t5, $zero, assoc_copy_done
    lbu $t6, 0($t1)
    sb $t6, 0($t2)
    addiu $t1, $t1, 1
    addiu $t2, $t2, 1
    addiu $t5, $t5, -1
    j assoc_copy_loop
    
assoc_copy_done:
    jr $ra

perform_way_access:
    # $a0 = set, $a1 = way, $a2 = offset
    # Global $a1 = access_type, $a2 = write_data
    
    # Calculate data address
    sll $t0, $a0, 1         # set * 2
    add $t0, $t0, $a1       # + way
    sll $t0, $t0, 4         # * BLOCK_SIZE
    add $t0, $t0, $a2       # + offset
    
    la $t1, assoc_data
    add $t1, $t1, $t0       # Final address
    
    # Check access type (assumed in global context)
    # This would need proper parameter passing in real implementation
    lw $v0, 0($t1)          # For now, always read
    
    jr $ra
```

3) AMAT Calculation and Optimization

**Performance Analysis Framework:**
```assembly
.data
# Performance counters
total_accesses: .word 0
l1_hits: .word 0
l1_misses: .word 0
l2_hits: .word 0  
l2_misses: .word 0
memory_accesses: .word 0

# Timing parameters (in cycles)
l1_hit_time: .word 1
l1_miss_penalty: .word 10
l2_hit_time: .word 3
l2_miss_penalty: .word 100
memory_access_time: .word 100

# Cache hierarchy simulation
l1_cache_size: .word 8192       # 8KB L1
l2_cache_size: .word 262144     # 256KB L2

.text
# Calculate AMAT for cache hierarchy
calculate_amat:
    # AMAT = L1_hit_time + L1_miss_rate * L1_miss_penalty
    # L1_miss_penalty = L2_hit_time + L2_miss_rate * L2_miss_penalty
    
    addiu $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s0, 4($sp)          # L1 miss rate (fixed point)
    sw $s1, 0($sp)          # L2 miss rate (fixed point)
    
    # Calculate L1 miss rate (multiply by 1000 for precision)
    lw $t0, l1_misses
    lw $t1, total_accesses
    beq $t1, $zero, amat_error
    
    li $t2, 1000            # Scale factor
    mul $t0, $t0, $t2       # misses * 1000
    div $t0, $t1            # (misses * 1000) / total_accesses
    mflo $s0               # L1 miss rate * 1000
    
    # Calculate L2 miss rate among L1 misses
    lw $t0, l2_misses
    lw $t1, l1_misses
    beq $t1, $zero, l2_perfect
    
    mul $t0, $t0, $t2       # l2_misses * 1000
    div $t0, $t1            # (l2_misses * 1000) / l1_misses
    mflo $s1               # L2 miss rate * 1000
    j calculate_penalty
    
l2_perfect:
    li $s1, 0               # Perfect L2 hit rate
    
calculate_penalty:
    # L2 miss penalty
    lw $t0, l2_miss_penalty
    
    # L1 miss penalty = L2_hit_time + L2_miss_rate * L2_miss_penalty
    lw $t1, l2_hit_time
    mul $t2, $s1, $t0       # L2_miss_rate * L2_miss_penalty
    div $t2, $t2, 1000      # Scale back
    add $t1, $t1, $t2       # L1_miss_penalty
    
    # AMAT = L1_hit_time + L1_miss_rate * L1_miss_penalty
    lw $t0, l1_hit_time
    mul $t3, $s0, $t1       # L1_miss_rate * L1_miss_penalty
    div $t3, $t3, 1000      # Scale back
    add $v0, $t0, $t3       # Final AMAT
    
    j amat_done
    
amat_error:
    li $v0, -1              # Error indicator
    
amat_done:
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addiu $sp, $sp, 12
    jr $ra

# Benchmark different access patterns
benchmark_access_patterns:
    addiu $sp, $sp, -8
    sw $ra, 4($sp)
    sw $s0, 0($sp)
    
    # Test 1: Sequential access pattern
    jal reset_performance_counters
    jal test_sequential_access
    jal calculate_amat
    move $s0, $v0           # Store sequential AMAT
    
    # Print results
    la $a0, seq_msg
    li $v0, 4
    syscall
    move $a0, $s0
    li $v0, 1
    syscall
    
    # Test 2: Random access pattern
    jal reset_performance_counters
    jal test_random_access
    jal calculate_amat
    
    # Print results
    la $a0, rand_msg
    li $v0, 4
    syscall
    move $a0, $v0
    li $v0, 1
    syscall
    
    # Test 3: Strided access pattern
    jal reset_performance_counters
    jal test_strided_access
    jal calculate_amat
    
    # Print results
    la $a0, stride_msg
    li $v0, 4
    syscall
    move $a0, $v0
    li $v0, 1
    syscall
    
    lw $s0, 0($sp)
    lw $ra, 4($sp)
    addiu $sp, $sp, 8
    jr $ra

test_sequential_access:
    # Access 1000 consecutive memory locations
    li $t0, 0               # Index
    li $t1, 1000            # Count
    la $t2, test_array      # Base address
    
seq_loop:
    beq $t0, $t1, seq_done
    
    sll $t3, $t0, 2         # i * 4
    add $t4, $t2, $t3       # &array[i]
    
    # Simulate cache access
    move $a0, $t4           # Address
    li $a1, 0               # Read access
    li $a2, 0               # No data for read
    jal simulate_cache_access
    
    addiu $t0, $t0, 1
    j seq_loop
    
seq_done:
    jr $ra

test_random_access:
    # Access 1000 random memory locations
    li $t0, 0               # Counter
    li $t1, 1000            # Count
    la $t2, test_array      # Base address
    li $t3, 12345           # Simple PRNG seed
    
rand_loop:
    beq $t0, $t1, rand_done
    
    # Simple linear congruential generator
    li $t4, 1103515245      # Multiplier
    mul $t3, $t3, $t4       # seed * multiplier
    addiu $t3, $t3, 12345   # + increment
    
    # Get index (mod 1000)
    li $t4, 1000
    div $t3, $t4
    mfhi $t5               # index = seed % 1000
    
    sll $t6, $t5, 2         # index * 4
    add $t7, $t2, $t6       # &array[index]
    
    # Simulate cache access
    move $a0, $t7           # Address
    li $a1, 0               # Read access
    li $a2, 0               # No data
    jal simulate_cache_access
    
    addiu $t0, $t0, 1
    j rand_loop
    
rand_done:
    jr $ra

test_strided_access:
    # Access with stride of 16 (poor cache utilization)
    li $t0, 0               # Index
    li $t1, 250             # Count (1000/4)
    la $t2, test_array      # Base address
    
stride_loop:
    beq $t0, $t1, stride_done
    
    sll $t3, $t0, 6         # i * 64 (stride of 16 words)
    add $t4, $t2, $t3       # &array[i*16]
    
    # Simulate cache access
    move $a0, $t4           # Address
    li $a1, 0               # Read access
    li $a2, 0               # No data
    jal simulate_cache_access
    
    addiu $t0, $t0, 1
    j stride_loop
    
stride_done:
    jr $ra

simulate_cache_access:
    # Simplified cache simulation
    # $a0 = address, $a1 = access type, $a2 = data
    
    # Update total accesses
    lw $t0, total_accesses
    addiu $t0, $t0, 1
    sw $t0, total_accesses
    
    # Simple hash-based simulation
    # Real implementation would use actual cache structures
    srl $t1, $a0, 4         # Block address
    andi $t2, $t1, 127      # Simple hash for L1 (128 blocks)
    
    # Simulate L1 access (70% hit rate for sequential, 30% for random)
    li $t3, 7               # Hit threshold out of 10
    
    # Get pseudo-random number based on address
    mul $t4, $t1, 1103515245
    srl $t4, $t4, 24        # Get upper bits
    andi $t4, $t4, 9        # Mod 10
    
    blt $t4, $t3, l1_hit_sim
    
l1_miss_sim:
    # L1 miss
    lw $t0, l1_misses
    addiu $t0, $t0, 1
    sw $t0, l1_misses
    
    # Simulate L2 access (90% hit rate on L1 misses)
    li $t3, 9               # Hit threshold out of 10
    blt $t4, $t3, l2_hit_sim
    
l2_miss_sim:
    # L2 miss - access main memory
    lw $t0, l2_misses
    addiu $t0, $t0, 1
    sw $t0, l2_misses
    
    lw $t0, memory_accesses
    addiu $t0, $t0, 1
    sw $t0, memory_accesses
    jr $ra
    
l2_hit_sim:
    # L2 hit
    lw $t0, l2_hits
    addiu $t0, $t0, 1
    sw $t0, l2_hits
    jr $ra
    
l1_hit_sim:
    # L1 hit
    lw $t0, l1_hits
    addiu $t0, $t0, 1
    sw $t0, l1_hits
    jr $ra

reset_performance_counters:
    sw $zero, total_accesses
    sw $zero, l1_hits
    sw $zero, l1_misses
    sw $zero, l2_hits
    sw $zero, l2_misses
    sw $zero, memory_accesses
    jr $ra

.data
test_array: .space 4000     # 1000-word test array
seq_msg: .asciiz "Sequential AMAT: "
rand_msg: .asciiz "\nRandom AMAT: "
stride_msg: .asciiz "\nStrided AMAT: "
newline: .asciiz "\n"
```

Kết luận
Memory hierarchy optimization is the key to achieving high performance in modern computer systems. Critical principles include:

**Performance Fundamentals:**
- **Locality of Reference**: Temporal and spatial locality drive cache effectiveness
- **AMAT Optimization**: Balance hit time, miss rate, and miss penalty
- **Multi-level Hierarchies**: Each level filters accesses to slower levels

**Design Trade-offs:**
- **Cache Size vs Hit Time**: Larger caches have longer access times
- **Associativity vs Complexity**: Higher associativity reduces conflicts but increases hardware cost
- **Write Policies**: Write-through vs write-back affects consistency and performance

**Software Optimization:**
- **Data Structure Layout**: Arrange data to maximize spatial locality
- **Algorithm Design**: Choose algorithms that exhibit good temporal locality
- **Loop Optimization**: Blocking, tiling, and loop interchange improve cache utilization

**Advanced Techniques:**
- **Prefetching**: Predict future accesses to hide memory latency
- **Cache-Conscious Algorithms**: Design algorithms specifically for cache hierarchy
- **Memory Access Pattern Analysis**: Profile and optimize critical access patterns

Understanding memory hierarchy enables developers to write high-performance software that effectively utilizes the complex storage systems in modern computers.

