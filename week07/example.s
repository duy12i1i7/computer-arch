# Tuần 07 — Ví dụ: HI/LO và dich so hoc/logic

.data
msg_mul: .asciiz "mult: hi = 0x, lo = 0x"
nl:      .asciiz "\n"
msg_srl: .asciiz "srl(0xF0000000,4) = 0x"
msg_sra: .asciiz "sra(0xF0000000,4) = 0x"

.text
.globl main

main:
    # Nhan 0x12345678 * 0x9 (demo HI/LO)
    li    $t0, 0x12345678
    li    $t1, 9
    multu $t0, $t1           # 32x32 -> 64
    mfhi  $t2
    mflo  $t3

    # In (hex) bang syscall 34 (print_int_hex) neu MARS ho tro
    li    $v0, 4
    la    $a0, msg_mul
    syscall
    li    $v0, 34            # print_int_hex
    move  $a0, $t2
    syscall
    li    $v0, 11
    li    $a0, 20            # ' '
    syscall
    li    $v0, 34
    move  $a0, $t3
    syscall
    li    $v0, 4
    la    $a0, nl
    syscall

    # So sanh srl vs sra tren so am (0xF0000000)
    li    $t0, 0xF0000000
    srl   $t1, $t0, 4        # dich phai logic → chen 0 o trai
    sra   $t2, $t0, 4        # dich phai so hoc → sao chep bit dau (1)

    li    $v0, 4
    la    $a0, msg_srl
    syscall
    li    $v0, 34
    move  $a0, $t1
    syscall
    li    $v0, 4
    la    $a0, nl
    syscall

    li    $v0, 4
    la    $a0, msg_sra
    syscall
    li    $v0, 34
    move  $a0, $t2
    syscall
    li    $v0, 4
    la    $a0, nl
    syscall

    li    $v0, 10
    syscall

