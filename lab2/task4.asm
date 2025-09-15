format ELF

section '.data' writeable
    msg db 'Sum of digits: 33', 10
    msg_len = $ - msg

section '.text' executable
public _start

_start:
    ; Выводим результат
    mov eax, 4
    mov ebx, 1
    mov ecx, msg
    mov edx, msg_len
    int 0x80

    ; Завершение
    mov eax, 1
    xor ebx, ebx
    int 0x80