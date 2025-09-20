format ELF64

section '.data' writeable
    symbol db '8'
    newline db 10
    total_msg db 'Total symbols in triangle: 210',10
    total_msg_len = $ - total_msg

section '.bss' writeable
    line_buffer rb 256

section '.text' executable
public _start

_start:
    mov r12, 20               ; высота треугольника (20 строк)
    mov r13, 1                ; текущее количество символов в строке
    
.triangle_loop:
    ; Заполняем строку символами '8'
    mov rdi, line_buffer
    mov rcx, r13
    mov al, [symbol]
    
.fill_line:
    mov [rdi], al
    inc rdi
    loop .fill_line
    
    mov byte [rdi], 10        ; добавляем перевод строки
    
    ; Выводим строку
    mov rax, 1
    mov rdi, 1
    mov rsi, line_buffer
    mov rdx, r13
    inc rdx                   ; +1 для перевода строки
    syscall
    
    ; Увеличиваем количество символов для следующей строки
    inc r13
    
    ; Проверяем, не достигли ли максимальной высоты
    dec r12
    jnz .triangle_loop
    
    ; Выводим сообщение о количестве символов
    ; Сумма арифметической прогрессии: n*(a1+an)/2 = 20*(1+20)/2 = 210
    mov rax, 1
    mov rdi, 1
    mov rsi, total_msg
    mov rdx, total_msg_len
    syscall
    
    ; Завершение
    mov rax, 60
    xor rdi, rdi
    syscall