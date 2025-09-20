format ELF64

section '.data' writeable
    original_str db 'eWTAghRYsHMeIYxtfCbeQoDvnQaKdRkKzJboR',0
    str_len = $ - original_str - 1
    newline db 10

section '.bss' writeable
    reversed_str rb str_len + 1

section '.text' executable
public _start

_start:
    mov rsi, original_str
    mov rdi, reversed_str
    mov rcx, str_len
    
.reverse_loop:
    mov al, [rsi + rcx - 1]
    mov [rdi], al
    inc rdi
    dec rcx
    jnz .reverse_loop
    
    mov byte [rdi], 10
    
    ; Выводим исходную строку
    mov rax, 1
    mov rdi, 1
    mov rsi, original_str
    mov rdx, str_len
    syscall
    
    ; Перевод строки
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    ; Выводим перевернутую строку
    mov rax, 1
    mov rdi, 1
    mov rsi, reversed_str
    mov rdx, str_len + 1
    syscall
    
    ; Завершение
    mov rax, 60
    xor rdi, rdi
    syscall