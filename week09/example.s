# Tuần 09 — Ví dụ: Lập lịch lệnh tránh lw-use

.data
ARR:   .word 10, 20, 30, 40
X:     .word  5
Y:     .word  2

.text
.globl main

main:
    la    $t0, ARR
    lw    $t1, 0($t0)     # t1 = ARR[0]
    lw    $t2, 4($t0)     # t2 = ARR[1]

    # Mau xau: dung ngay t1 sau lw (co the stall)
    # addu  $t3, $t1, $t2

    # Lich lai: chen mot cong viec doc lap giua de an do tre lw
    lw    $t4, X          # doc X (doc lap voi t1)
    addu  $t3, $t1, $t2   # bay gio du lieu t1 da toi kip qua forwarding
    subu  $t5, $t3, $t4

    # Tiep tuc chen cong viec truoc khi dung t2 nua lan
    lw    $t6, Y
    addu  $t7, $t5, $t6

    li    $v0, 10
    syscall

