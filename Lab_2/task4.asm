section .data
    number dq 2634342072  ; заданное число
    newline db 10

section .bss
    buffer resb 21        ; буфер для вывода числа (максимум 20 цифр + символ новой строки)

section .text
    global _start

_start:
    mov rax, [number]     ; загружаем число в rax
    xor rbx, rbx          ; обнуляем rbx (здесь будет сумма цифр)

calculate_sum:
    xor rdx, rdx          ; обнуляем rdx для деления
    mov rcx, 10           ; делитель 10
    div rcx               ; rax = rax/10, rdx = остаток (последняя цифра)
    
    add rbx, rdx          ; добавляем цифру к сумме
    
    test rax, rax         ; проверяем, не стало ли частное нулем
    jnz calculate_sum     ; если не ноль, продолжаем

    ; Теперь в rbx сумма цифр, нужно преобразовать в строку и вывести
    mov rax, rbx          ; число для вывода (сумма цифр)
    mov rdi, buffer + 20  ; указатель на конец буфера
    mov byte [rdi], 10    ; записываем символ новой строки
    mov rcx, 10           ; основание системы счисления

convert_to_string:
    dec rdi               ; перемещаемся к предыдущему байту
    xor rdx, rdx          ; обнуляем rdx для деления
    div rcx               ; rax = rax/10, rdx = остаток
    add dl, '0'           ; преобразуем цифру в символ
    mov [rdi], dl         ; сохраняем символ в буфер
    
    test rax, rax         ; проверяем, не ноль ли
    jnz convert_to_string ; если не ноль, продолжаем

    ; Вычисляем длину строки для вывода
    mov rsi, rdi          ; начало строки
    mov rdx, buffer + 21  ; конец буфера
    sub rdx, rsi          ; длина строки

    ; Вывод результата
    mov rax, 1            ; sys_write
    mov rdi, 1            ; stdout
    syscall

    ; Завершение программы
    mov rax, 60           ; sys_exit
    xor rdi, rdi          ; код возврата 0
    syscall