format ELF64

section '.data' writeable
    symbol db '$'
    newline db 10

section '.bss' writeable
    buffer rb 153
    matrix_buffer rb 10

section '.text' executable
public _start

_start:
    ; Заполняем буфер
    mov rdi, buffer
    mov rcx, 153
    mov al, [symbol]
.fill_buffer:
    mov [rdi], al
    inc rdi
    loop .fill_buffer
    
    ; Выводим матрицу 9x17
    mov rsi, buffer
    mov rcx, 17
    
.matrix_loop:
    push rcx
    mov rdi, matrix_buffer
    mov rcx, 9
    
.fill_row:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    loop .fill_row
    
    mov byte [rdi], 10
    
    ; Вывод строки
    mov rax, 1
    mov rdi, 1
    mov rsi, matrix_buffer
    mov rdx, 10
    syscall
    
    pop rcx
    loop .matrix_loop
    
    ; Завершение
    mov rax, 60
    xor rdi, rdi
    syscall