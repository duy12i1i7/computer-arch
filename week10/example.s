# Tuần 10 — Ví dụ: Duyệt tuần tự vs stride (minh hoạ locality)

.data
ARR: .space 4000            # mang ~1000 so byte (chi minh hoa)
N:   .word 1000

.text
.globl main

main:
    la   $t0, ARR
    lw   $t1, N

    # Duyet tuan tu: for i=0..N-1: sum += ARR[i]
    move $t2, $zero         # sum_seq = 0
    move $t3, $zero         # i = 0
SEQ_LOOP:
    slt  $t4, $t3, $t1
    beq  $t4, $zero, SEQ_DONE
    addu $t5, $t0, $t3      # dia chi byte ARR[i]
    lbu  $t6, 0($t5)
    addu $t2, $t2, $t6
    addiu $t3, $t3, 1
    j    SEQ_LOOP
    nop
SEQ_DONE:

    # Duyet stride lon: for i=0..N-1 step 32: sum += ARR[i]
    move $t7, $zero         # sum_stride = 0
    move $t8, $zero
STR_LOOP:
    slt  $t4, $t8, $t1
    beq  $t4, $zero, STR_DONE
    addu $t5, $t0, $t8
    lbu  $t6, 0($t5)
    addu $t7, $t7, $t6
    addiu $t8, $t8, 32
    j    STR_LOOP
    nop
STR_DONE:

    li   $v0, 10
    syscall

