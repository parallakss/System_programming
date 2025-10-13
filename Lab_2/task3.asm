section .data
    symbol db '$'
    newline db 10
    space db ' '

section .text
    global _start

_start:
    mov rbx, 1           ; начальное количество символов в строке (первая строка)
    mov rcx, 21          ; общее количество символов для треугольника

print_triangle:
    ; Вывод строки с rbx символами '$'
    push rbx
    push rcx
    
    mov rcx, rbx         ; количество символов для текущей строки

print_symbols:
    push rcx
    
    ; Вывод символа '$'
    mov rax, 1           ; sys_write
    mov rdi, 1           ; stdout
    mov rsi, symbol      ; символ '$'
    mov rdx, 1           ; длина
    syscall
    
    ; Вывод пробела (кроме последнего символа в строке)
    pop rcx
    push rcx
    cmp rcx, 1
    je no_space
    
    mov rax, 1
    mov rdi, 1
    mov rsi, space
    mov rdx, 1
    syscall

no_space:
    pop rcx
    loop print_symbols

    ; Вывод новой строки
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    pop rcx
    pop rbx
    
    ; Увеличиваем количество символов для следующей строки
    inc rbx
    
    ; Проверяем, не превысили ли общее количество символов
    mov rax, rbx
    dec rax
    mov rdx, rax
    inc rax
    mul rdx              ; rax = n*(n+1)/2 (формула треугольного числа)
    shr rax, 1
    cmp rax, 21
    jle print_triangle

    ; Выход
    mov rax, 60
    xor rdi, rdi
    syscall