.section .data
p1: .ascii "Enter first string: "
p1len = . - p1

p2: .ascii "Enter second string: "
p2len = . - p2

label: .ascii "Hamming distance: "
labellen = . - label

nl: .byte 10

.section .bss
    .lcomm s1, 256
    .lcomm s2, 256
    .lcomm numbuf, 32

.section .text
.global _start
_start:
    # read first line -> len1 in r12
    lea s1(%rip), %r8           # buffer
    mov $255, %esi              # max read
    lea p1(%rip), %rdx          # prompt
    mov $p1len, %ecx            # prompt len
    call read_line
    mov %rax, %r12

    # read second line -> len2 in r13
    lea s2(%rip), %r8
    mov $255, %esi
    lea p2(%rip), %rdx
    mov $p2len, %ecx
    call read_line
    mov %rax, %r13

    # minlen in r14
    mov %r12, %r14
    cmp %r13, %r14
    cmova %r13, %r14

    xor %r15d, %r15d            # total = 0

    lea s1(%rip), %rbx          # s1 ptr
    lea s2(%rip), %rdi          # s2 ptr
    xor %r9, %r9                # i = 0

char_loop:
    cmp %r14, %r9
    jae done

    movzbq (%rbx,%r9,1), %rax   # a
    movzbq (%rdi,%r9,1), %rdx   # b
    xor %dl, %al                # al = a XOR b

    mov $8, %ecx
bit_loop:
    shr $1, %al
    adc $0, %r15d
    loop bit_loop

    inc %r9
    jmp char_loop

done:
    # print label (edit/remove easily)
    mov $1, %rax
    mov $1, %rdi
    lea label(%rip), %rsi
    mov $labellen, %rdx
    syscall

    # print number + newline
    mov %r15d, %edi
    call print_u32

    # exit(0)
    mov $60, %rax
    xor %rdi, %rdi
    syscall


# ------------------------------------------------------------
# read_line
# IN:  r8 = buffer, esi = max, rdx = prompt ptr, ecx = prompt len
# OUT: rax = length (after stripping '\n')
# ------------------------------------------------------------
read_line:
    # write(1, prompt, promptlen)
    mov $1, %rax
    mov $1, %rdi
    mov %rdx, %rsi
    mov %rcx, %rdx
    syscall

    # read(0, buffer, max)
    mov $0, %rax
    mov $0, %rdi
    mov %r8, %rsi
    mov %esi, %edx
    syscall                  # rax = bytes read

    test %rax, %rax
    jle .done

    # null terminate at buffer[rax]
    movb $0, (%r8,%rax,1)

    # check if last char is '\n'
    lea -1(%r8,%rax,1), %r9
    cmpb $10, (%r9)
    jne .done
    movb $0, (%r9)
    dec %rax

.done:
    ret


# ------------------------------------------------------------
# print_u32
# IN:  edi = value
# OUT: prints value then '\n'
# ------------------------------------------------------------
print_u32:
    lea numbuf(%rip), %rsi      # start of buffer
    lea 31(%rsi), %r8           # write ptr at end
    movb $0, (%r8)              # terminator (not required, but fine)

    mov %edi, %eax
    test %eax, %eax
    jne .pu_loop

    # value == 0
    dec %r8
    movb $'0', (%r8)
    jmp .pu_write

.pu_loop:
    xor %edx, %edx
    mov $10, %ecx
    div %ecx                    # eax/=10, edx=remainder
    add $'0', %dl
    dec %r8
    mov %dl, (%r8)
    test %eax, %eax
    jne .pu_loop

.pu_write:
    # write digits from r8 to end
    mov $1, %rax
    mov $1, %rdi
    mov %r8, %rsi
    lea numbuf(%rip), %rcx
    lea 31(%rcx), %rcx
    sub %r8, %rcx               # length
    mov %rcx, %rdx
    syscall

    # write newline
    mov $1, %rax
    mov $1, %rdi
    lea nl(%rip), %rsi
    mov $1, %rdx
    syscall

    ret

.section .note.GNU-stack,"",@progbits
