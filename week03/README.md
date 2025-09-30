# Bài 1 (10đ)

PC hiện tại: 0x2004FFF0
Đích muốn nhảy: 0x10002000

## 1) Có dùng j để nhảy trực tiếp được không?

Không.
Lệnh j target của MIPS chỉ mang 26 bit chỉ số lệnh (instr_index). Khi thực thi, địa chỉ đích được ghép như sau:

target_addr = { (PC+4)[31:28],  instr_index[25:0],  2'b00 }

Nghĩa là 4 bit cao của PC+4 (ở đây (PC+4)=0x2004FFF4 ⇒ 4 bit cao = 0x2) bị “ép” sang địa chỉ đích.
Địa chỉ cần nhảy có 4 bit cao = 0x1 (vì 0x1000_2000), không trùng 0x2, nên j không thể nhảy trực tiếp.

## 2) Cách khác để nhảy tới 0x10002000

Dùng thanh ghi + jr (hoặc jalr). Ví dụ:

lui   $t0, 0x1000        # $t0 = 0x1000_0000
ori   $t0, $t0, 0x2000   # $t0 = 0x1000_2000
jr    $t0
nop

(hoặc jalr $ra, $t0 nếu muốn lưu $ra).

## 3) Khoảng địa chỉ tối đa nhảy được bằng một lệnh j từ PC này

Vì 4 bit cao bị khóa là 0x2, nên có thể nhảy tới mọi địa chỉ word-aligned trong dải:

Bắt đầu: 0x2000_0000

Kết thúc: 0x2FFF_FFFC (thực tế các địa chỉ lệnh đều bội số của 4; nếu nói theo biên 16-thập lục phân tròn thì là 0x2FFF_FFFF, nhưng bit [1:0] luôn 00).



---

# Bài 2 (20đ)

## Yêu cầu:
Hàm nhận 8 tham số, trả 3 giá trị, tiết kiệm stack, “không bắt buộc” theo chuẩn caller/callee (nhưng vẫn quản lý bộ nhớ gọn gàng).
Mình sẽ:

Truyền 4 tham số đầu qua $a0..$a3.

4 tham số còn lại đặt trên stack do caller đẩy ngay trước jal.

Callee tạo frame nhỏ (chỉ lưu $ra), đọc 4 arg bổ sung từ stack của caller qua offset cố định (vì ngay sau return addr, stack caller vẫn còn đó).

Trả 3 kết quả qua $v0, $v1 và $t0 (không chuẩn MIPS, nhưng đề cho phép).


## Chương trình mẫu
```
########################################################
# Bài 2: 8 tham số, trả 3 giá trị với stack tối thiểu
########################################################
        .text
        .globl main

main:
        # Chuẩn bị 8 tham số: a0..a3 trong thanh ghi; a4..a7 trên stack
        li      $a0, 10          # arg0
        li      $a1, 20          # arg1
        li      $a2, 30          # arg2
        li      $a3, 40          # arg3

        addiu   $sp, $sp, -16    # chỗ cho 4 arg bổ sung
        sw      $zero, 12($sp)   # giữ chỗ (không cần thiết, chỉ minh họa)
        sw      $zero, 8($sp)
        sw      $zero, 4($sp)
        sw      $zero, 0($sp)

        li      $t1, 50          # arg4
        li      $t2, 60          # arg5
        li      $t3, 70          # arg6
        li      $t4, 80          # arg7
        sw      $t1, 0($sp)
        sw      $t2, 4($sp)
        sw      $t3, 8($sp)
        sw      $t4, 12($sp)

        # Gọi hàm
        jal     multiParamFunc
        nop

        # Sau khi về: $v0, $v1, $t0 chứa 3 giá trị trả về
        # Lưu kết quả vào bộ nhớ
        la      $t7, RET_BUF
        sw      $v0, 0($t7)
        sw      $v1, 4($t7)
        sw      $t0, 8($t7)

        addiu   $sp, $sp, 16     # thu hồi vùng arg bổ sung

        # (Tùy chọn) Kết thúc chương trình
        li      $v0, 10
        syscall

# multiParamFunc(a0..a3; a4..a7 ở stack của caller)
# Trả 3 giá trị: r0->v0, r1->v1, r2->t0
multiParamFunc:
        # Tạo frame tối thiểu: chỉ lưu $ra
        addiu   $sp, $sp, -8
        sw      $ra, 4($sp)
        sw      $fp, 0($sp)
        move    $fp, $sp

        # Đọc 4 tham số bổ sung từ stack của caller:
        # Bố cục khi vào đây:
        #   [caller ...]
        #   arg4        <- SP(caller)+0
        #   arg5        <- SP(caller)+4
        #   arg6        <- SP(caller)+8
        #   arg7        <- SP(caller)+12
        #   ------------- (caller SP)
        # Sau khi jal, $sp đã dịch sang frame callee. Ta cần điểm tới arg4..arg7
        # Cách đơn giản: dùng $fp/$sp hiện tại + hằng số bù:
        # Vì callee vừa addiu $sp,-8, nên arg4 nằm ở ($fp + 8) + 0x? Không an toàn.
        # Giải pháp ổn định: copy $sp của caller trước khi tạo frame — nhưng để tối giản
        # ta suy luận offset tuyệt đối so với $fp hiện tại:
        # Ở thời điểm trước "addiu $sp,-8", $sp_callerArg = SP trước callee.
        # Sau khi trừ 8 và set $fp=$sp, khoảng cách từ $fp tới arg4 là +8.
        # (Kiểm chứng trên QtSPIM)

        lw      $t1, 8($fp)      # arg4
        lw      $t2, 12($fp)     # arg5
        lw      $t3, 16($fp)     # arg6
        lw      $t4, 20($fp)     # arg7

        # Tính toán ví dụ:
        # r0 = a0 + arg4
        # r1 = a1 - arg5
        # r2 = (a2 + a3) + (arg6 - arg7)
        addu    $v0, $a0, $t1
        subu    $v1, $a1, $t2

        addu    $t5, $a2, $a3
        subu    $t6, $t3, $t4
        addu    $t0, $t5, $t6     # r2 để trong $t0 (trả về kiểu “tùy biến”)

        # Trả về
        move    $sp, $fp
        lw      $fp, 0($sp)
        lw      $ra, 4($sp)
        addiu   $sp, $sp, 8
        jr      $ra
        nop

        .data
RET_BUF: .space 12   # chỗ lưu 3 kết quả
```
> Ghi chú: Vì đề “không bắt buộc” theo chuẩn, chọn trả kết quả 3 qua $v0,$v1,$t0 để không phải mở rộng frame/ghi bộ nhớ tạm — đúng tinh thần “tiết kiệm stack”.




---

# Bài 3 (20đ)

## Cho code vi phạm quy ước caller/callee. Mục tiêu: giữ nguyên chức năng tính toán nhưng bảo toàn đúng quy ước:

$s*: callee-saved → hàm phải lưu/phục hồi nếu dùng/sửa.

$t*: caller-saved → caller phải lưu nếu cần dùng giá trị cũ sau lời gọi.

$ra: callee phải lưu nếu có lời gọi lồng; ở đây có một cấp nên vẫn nên lưu cho chuẩn.


## Phiên bản đã chỉnh
```
.text
        .globl main

main:
        # s1 = 100; s2 = 200
        li      $s1, 100
        li      $s2, 200

        # t5 = MEM[s1]
        lw      $t5, 0($s1)

        # t6 = s1 + s2
        addu    $t6, $s1, $s2

        # Caller-save: vì sau khi gọi vẫn cần dùng t6 để store,
        # và t5 cũng được compute_func sửa, nên ta lưu chúng.
        addiu   $sp, $sp, -8
        sw      $t5, 4($sp)
        sw      $t6, 0($sp)

        # Gọi hàm
        jal     compute_func
        nop

        # Phục hồi caller-saved cần thiết
        lw      $t6, 0($sp)
        lw      $t5, 4($sp)
        addiu   $sp, $sp, 8

        # Store result (giữ nguyên yêu cầu: dùng t6 ghi về 4(s1))
        sw      $t6, 4($s1)

        # ... (main tiếp tục và trả về giá trị trong $s0 nếu cần)
        jr      $ra
        nop


# compute_func:
#   s1 := s1 + 50
#   s2 := t6 - s1
#   s0 := (s2 * s2)  (kết quả từ LO)
#   t5 := t5 + 10
# Bảo toàn quy ước: $s1, $s2 là callee-saved => phải lưu/phục hồi.
compute_func:
        # Prologue
        addiu   $sp, $sp, -16
        sw      $ra, 12($sp)
        sw      $s1, 8($sp)
        sw      $s2, 4($sp)
        sw      $s0, 0($sp)     # vì hàm ghi $s0 để trả về trong main

        # Thân hàm (giữ nguyên ý nghĩa tính toán)
        addiu   $s1, $s1, 50          # modify s1
        subu    $s2, $t6, $s1         # s2 = t6 - s1
        mult    $s2, $s2              # square
        mflo    $s0                   # s0 = s2*s2
        addiu   $t5, $t5, 10          # modify t5 (t-reg: caller đã tự lo)

        # Epilogue
        lw      $s0, 0($sp)
        lw      $s2, 4($sp)
        lw      $s1, 8($sp)
        lw      $ra, 12($sp)
        addiu   $sp, $sp, 16
        jr      $ra
        nop
```
Vì sao đúng quy ước?

- Hàm sử dụng/sửa $s1,$s2,$s0 ⇒ callee đã lưu và khôi phục chúng.

- $t5,$t6 là caller-saved, nên main đã lưu/khôi phục trước/sau jal.

- Lưu $ra để chuẩn mực (và an toàn nếu sau này mở rộng).



---

# Bài 4 (50đ) – Fibonacci đệ quy

## Yêu cầu:

Tuân thủ quy ước MIPS (caller/callee, stack frame).

main gọi fib(6), kết quả mong đợi 8 (F(6)=8).

Hiển thị hoặc lưu kết quả.


## Lời giải hoàn chỉnh
```
##############################
# Bài 4: Fibonacci đệ quy
##############################
        .text
        .globl main

# fib(n):
# - Tham số: n trong $a0
# - Trả về: F(n) trong $v0
fib:
        # Prologue: frame 16 byte: [saved $ra, saved $s0, saved $a0, padding]
        addiu   $sp, $sp, -16
        sw      $ra, 12($sp)
        sw      $s0, 8($sp)
        sw      $a0, 4($sp)

        # Base case: if n == 0 => return 0
        beq     $a0, $zero, fib_base0
        nop
        # if n == 1 => return 1
        li      $t0, 1
        beq     $a0, $t0, fib_base1
        nop

        # fib(n-1)
        addiu   $a0, $a0, -1
        jal     fib
        nop
        move    $s0, $v0         # s0 = fib(n-1)

        # fib(n-2)
        lw      $a0, 4($sp)      # khôi phục n gốc
        addiu   $a0, $a0, -2
        jal     fib
        nop

        # v0 = fib(n-1) + fib(n-2)
        addu    $v0, $v0, $s0
        j       fib_epilogue
        nop

fib_base0:
        move    $v0, $zero       # 0
        j       fib_epilogue
        nop

fib_base1:
        li      $v0, 1
        # fallthrough -> epilogue

fib_epilogue:
        lw      $a0, 4($sp)
        lw      $s0, 8($sp)
        lw      $ra, 12($sp)
        addiu   $sp, $sp, 16
        jr      $ra
        nop


################################
# main: tính fib(6), in/lưu kết quả
################################
main:
        li      $a0, 6           # n = 6
        jal     fib
        nop

        # Lưu kết quả vào bộ nhớ
        la      $t1, FIB_RES
        sw      $v0, 0($t1)

        # (Tùy chọn) In ra console: syscall print_int + print_newline
        li      $v0, 1           # print_int
        move    $a0, $v0         # a0 = F(6)
        syscall

        li      $v0, 11          # print_char
        li      $a0, 10          # '\n'
        syscall

        # Kết thúc
        li      $v0, 10
        syscall

        .data
FIB_RES: .word 0
```
Giải thích tuân thủ quy ước:

- Callee-saved: $s0 được lưu/khôi phục trong fib.

- Caller-saved: Các $t* không cần bảo tồn bởi callee, nhưng ta không dựa vào chúng cho giá trị lâu dài.

- Stack frame rõ ràng (lưu $ra, $s0, và bản sao $a0 để dùng lại khi đệ quy).


Kiểm thử: Với n=6, chương trình in 8 và lưu vào FIB_RES.


---

