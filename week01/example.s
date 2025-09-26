# Tuần 01 — Ví dụ: Hello + Cộng hai số

.data
msg_hello: .asciiz "Xin chao MIPS!\n"
msg_sum:   .asciiz "Tong a + b = "

.text
.globl main

main:
    # In chuoi chao
    li   $v0, 4          # syscall 4: print_string
    la   $a0, msg_hello
    syscall

    # Tinh tong don gian tren thanh ghi (load/store se hoc sau)
    li   $t0, 7          # a = 7
    li   $t1, 13         # b = 13
    addu $t2, $t0, $t1   # t2 = a + b (khong bao tran)

    # In thong bao
    li   $v0, 4
    la   $a0, msg_sum
    syscall

    # In ket qua so nguyen
    li   $v0, 1          # syscall 1: print_int
    move $a0, $t2
    syscall

    # Ket thuc chuong trinh
    li   $v0, 10         # syscall 10: exit
    syscall

