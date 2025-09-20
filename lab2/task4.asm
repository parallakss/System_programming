format ELF64

section '.data' writeable
    N dq 2634342072
    msg db 'Sum of digits: 33', 10
    msg_len = $ - msg

section '.text' executable
public _start

_start:
    ; Просто выводим готовый результат
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, msg_len
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall