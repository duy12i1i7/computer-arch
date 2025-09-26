# Tuần 12 — Ví dụ: Lập lịch và gộp lệnh để giảm stall

.data
A: .word 1,2,3,4,5,6,7,8
B: .word 8,7,6,5,4,3,2,1
N: .word 8

.text
.globl main

main:
    la    $t0, A
    la    $t1, B
    lw    $t2, N
    move  $t3, $zero    # i
    move  $t4, $zero    # acc (dot)

# Phien ban chua lich (co the tao nhieu lw-use sat nhau)
UNSCHED_LOOP:
    slt   $t5, $t3, $t2
    beq   $t5, $zero, DONE
    sll   $t6, $t3, 2
    addu  $t7, $t0, $t6
    lw    $t8, 0($t7)   # A[i]
    addu  $t7, $t1, $t6
    lw    $t9, 0($t7)   # B[i]
    mul   $t8, $t8, $t9 # A[i]*B[i]
    addu  $t4, $t4, $t8 # acc +=
    addiu $t3, $t3, 1
    j     UNSCHED_LOOP
    nop

# Phien ban da lich (chen cong viec doc lap giua load va su dung)
    move  $t3, $zero
    move  $t4, $zero
SCHED_LOOP:
    slt   $t5, $t3, $t2
    beq   $t5, $zero, DONE
    sll   $t6, $t3, 2
    addu  $t7, $t0, $t6
    lw    $t8, 0($t7)   # A[i]
    addu  $t7, $t1, $t6
    # chen tinh toan doc lap: tinh dia chi cho vong sau (prefetch tinh)
    addiu $t10, $t3, 1
    sll   $t11, $t10, 2
    addu  $t12, $t0, $t11   # addr A[i+1] (khong dung ngay)
    lw    $t9, 0($t7)       # B[i]
    mul   $t8, $t8, $t9
    addu  $t4, $t4, $t8
    move  $t12, $t12        # giu cong viec nhe de gan day slot (neu co)
    addiu $t3, $t3, 1
    j     SCHED_LOOP
    nop

DONE:
    li    $v0, 10
    syscall

