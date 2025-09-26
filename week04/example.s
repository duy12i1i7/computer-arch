# Tuần 04 — Ví dụ: if/else và while

.data
msg_pos:  .asciiz "So duong\n"
msg_nonp: .asciiz "Khong duong\n"
msg_i:    .asciiz "i = "

.text
.globl main

main:
    # if (x > 0) print("So duong") else print("Khong duong")
    li   $t0, 5               # x = 5 (thu thay -3 de kiem tra nhanh)
    blez $t0, ELSE
    # IF-branch
    li   $v0, 4
    la   $a0, msg_pos
    syscall
    j    IF_END
    nop
ELSE:
    li   $v0, 4
    la   $a0, msg_nonp
    syscall
IF_END:

    # while (i < 5) { print(i); i++; }
    li   $t1, 0               # i = 0
LOOP:
    slti $t2, $t1, 5          # t2 = (i < 5)
    beq  $t2, $zero, LOOP_END

    # print("i = ")
    li   $v0, 4
    la   $a0, msg_i
    syscall
    # print(i)
    li   $v0, 1
    move $a0, $t1
    syscall
    # print('\n')
    li   $v0, 11
    li   $a0, 10
    syscall

    addiu $t1, $t1, 1         # i++
    j    LOOP
    nop
LOOP_END:
    li   $v0, 10
    syscall

