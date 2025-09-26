# Tuần 03 — Ví dụ: R/I/J và lệnh giả

.data
msg: .asciiz "Gia tri = "

.text
.globl main

main:
    # I-type: nap hang so 32-bit bang lui+ori (assembler sinh ra tu 'li')
    li    $t0, 0x12345678   # pseudo → lui/ori

    # R-type: phep toan tren thanh ghi
    li    $t1, 10
    li    $t2, 32
    addu  $t3, $t1, $t2     # t3 = 42

    # Luu ket qua vao $a0 de in
    li    $v0, 4
    la    $a0, msg
    syscall

    li    $v0, 1
    move  $a0, $t3          # pseudo → addu $a0, $t3, $zero
    syscall

    # J-type: jal luu $ra, sau do jr $ra
    jal   demo
    nop                      # (co the) delay slot tuy mo phong

    li    $v0, 10
    syscall

demo:
    # Chi la demo, khong lam gi phuc tap
    jr    $ra
    nop

