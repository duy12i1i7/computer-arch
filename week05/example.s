# Tuần 05 — Ví dụ: giai thừa đệ quy với prologue/epilogue

.data
msg_in:  .asciiz "n = "
msg_out: .asciiz "\n n! = "

.text
.globl main

main:
    # Nhap n tu ban phim (syscall 5)
    li   $v0, 4
    la   $a0, msg_in
    syscall
    li   $v0, 5
    syscall
    move $a0, $v0      # a0 = n

    # goi fact(n)
    jal  fact
    move $t0, $v0      # luu ket qua

    # In ket qua
    li   $v0, 4
    la   $a0, msg_out
    syscall
    li   $v0, 1
    move $a0, $t0
    syscall

    li   $v0, 10
    syscall

# int fact(int n) {
#   if (n <= 1) return 1;
#   return n * fact(n-1);
# }
fact:
    # Prologue: cap phat frame 16 byte: luu $ra, $s0 (giu n)
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    sw    $s0, 8($sp)
    move  $s0, $a0        # s0 = n

    # if (n <= 1) return 1;
    addiu $t0, $s0, -1
    blez  $t0, BASE

    # goi fact(n-1)
    addiu $a0, $s0, -1
    jal   fact
    nop
    # v0 = fact(n-1)
    mul   $v0, $s0, $v0    # v0 = n * v0 (mul pseudo → mult/mflo tren may asm)
    j     RET
    nop

BASE:
    li    $v0, 1

RET:
    # Epilogue: khoi phuc
    lw    $ra, 12($sp)
    lw    $s0, 8($sp)
    addiu $sp, $sp, 16
    jr    $ra
    nop

