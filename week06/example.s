# Tuần 06 — Ví dụ: Tính tổng mảng và độ dài chuỗi

.data
arr:     .word 3, 1, 4, 1, 5, 9
N:       .word 6
msg_sum: .asciiz "Tong mang = "
str:     .asciiz "MIPS"
msg_len: .asciiz "\nDo dai chuoi = "

.text
.globl main

main:
    # Tinh tong mang arr[0..N-1]
    la    $t0, arr         # base
    lw    $t1, N           # N
    move  $t2, $zero       # sum = 0
    move  $t3, $zero       # i = 0

SUM_LOOP:
    slt   $t4, $t3, $t1    # i < N ?
    beq   $t4, $zero, SUM_DONE
    sll   $t5, $t3, 2      # i*4
    addu  $t6, $t0, $t5    # &arr[i]
    lw    $t7, 0($t6)
    addu  $t2, $t2, $t7    # sum += arr[i]
    addiu $t3, $t3, 1      # i++
    j     SUM_LOOP
    nop
SUM_DONE:
    # In sum
    li    $v0, 4
    la    $a0, msg_sum
    syscall
    li    $v0, 1
    move  $a0, $t2
    syscall

    # Tinh do dai chuoi (strlen)
    la    $t0, str
    move  $t1, $zero       # len = 0
LEN_LOOP:
    lbu   $t2, 0($t0)      # doc 1 byte (zero-extend)
    beq   $t2, $zero, LEN_DONE
    addiu $t1, $t1, 1
    addiu $t0, $t0, 1
    j     LEN_LOOP
    nop
LEN_DONE:
    li    $v0, 4
    la    $a0, msg_len
    syscall
    li    $v0, 1
    move  $a0, $t1
    syscall

    li    $v0, 10
    syscall

