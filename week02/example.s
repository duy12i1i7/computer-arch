# Tuần 02 — Ví dụ: Sign-extend vs Zero-extend

.data
msg_lb:  .asciiz "Gia tri (lb, sign-extend) = "
msg_lbu: .asciiz "\nGia tri (lbu, zero-extend) = "

.text
.globl main

main:
    # Dat mot byte 0xFF vao bo nho tam thoi tren stack (mo phong)
    addiu $sp, $sp, -8
    li    $t0, 0xFF
    sb    $t0, 0($sp)         # luu 0xFF (255) vao dia chi $sp

    # lb: sign-extend thanh so co dau 32-bit -> -1
    lb    $t1, 0($sp)

    # lbu: zero-extend thanh 255
    lbu   $t2, 0($sp)

    # In ket qua lb (ky vong -1)
    li    $v0, 4
    la    $a0, msg_lb
    syscall
    li    $v0, 1
    move  $a0, $t1
    syscall

    # In ket qua lbu (ky vong 255)
    li    $v0, 4
    la    $a0, msg_lbu
    syscall
    li    $v0, 1
    move  $a0, $t2
    syscall

    # Thu gon stack va thoat
    addiu $sp, $sp, 8
    li    $v0, 10
    syscall

