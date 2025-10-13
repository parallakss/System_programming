section .data
    newline db 10
    space db ' '

section .bss
    matrix resb 153

section .text
    global _start

_start:
    ; Заполняем всю матрицу символами '$'
    mov rdi, matrix
    mov rcx, 153
    mov al, '$'
    rep stosb

    ; Вывод матрицы 9×17
    mov rsi, matrix      ; указатель на матрицу
    mov rbx, 17          ; 17 строк

print_rows:
    mov rcx, 9           ; 9 символов в строке

print_chars:
    ; Вывод символа '$'
    push rbx
    push rcx
    push rsi
    
    mov rax, 1           ; sys_write
    mov rdi, 1           ; stdout
    mov rdx, 1           ; длина
    mov rsi, matrix      ; символ '$' (любой из матрицы)
    syscall
    
    ; Вывод пробела
    mov rax, 1
    mov rdi, 1
    mov rsi, space
    mov rdx, 1
    syscall
    
    pop rsi
    pop rcx
    pop rbx
    
    inc rsi              ; следующий символ
    loop print_chars

    ; Вывод новой строки
    push rbx
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    pop rbx
    
    dec rbx
    jnz print_rows

    ; Выход
    mov rax, 60
    xor rdi, rdi
    syscall