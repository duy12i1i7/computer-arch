# Tuần 08 — Ví dụ: Chuỗi lệnh va bubble (nop)

.text
.globl main

main:
    # Tinh toan voi phu thuoc du lieu sat nhau (tao hazard lw-use)
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)

    la    $t0, DATA
    lw    $t1, 0($t0)     # t1 = DATA[0]
    # Ngay sau lw dung t1 → co the can stall 1 chu ky tren pipeline co dien
    addu  $t2, $t1, $t1   # t2 = 2 * t1

    # Dat nop de minh hoa bubble thu cong (mot so mo phong khong yeu cau)
    nop
    lw    $t3, 4($t0)     # t3 = DATA[1]
    addu  $t4, $t2, $t3   # t4 = 2*t1 + t3

    lw    $ra, 12($sp)
    addiu $sp, $sp, 16
    li    $v0, 10
    syscall

.data
DATA: .word 7, 5

