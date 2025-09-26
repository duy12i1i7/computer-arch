# Tuần 11 — Ví dụ: Syscall co ban

.data
prompt: .asciiz "Nhap so nguyen n: "
msg:    .asciiz "Ban da nhap: "
nl:     .asciiz "\n"

.text
.globl main

main:
    li   $v0, 4
    la   $a0, prompt
    syscall

    li   $v0, 5             # read_int
    syscall
    move $t0, $v0

    li   $v0, 4
    la   $a0, msg
    syscall
    li   $v0, 1
    move $a0, $t0
    syscall
    li   $v0, 4
    la   $a0, nl
    syscall

    # Vi du break (debug):
    # break

    li   $v0, 10
    syscall

