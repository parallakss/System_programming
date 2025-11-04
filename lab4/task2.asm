format ELF64

; Системные вызовы
SYS_READ = 0
SYS_WRITE = 1
SYS_EXIT = 60

section '.text' executable
public _start

_start:
    ; Выводим приглашение для ввода
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, prompt_msg
    mov rdx, prompt_len
    syscall

    ; Читаем ввод пользователя
    mov rax, SYS_READ
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 32
    syscall

    ; Преобразуем строку в число
    mov rdi, input_buffer
    xor rax, rax
    xor rcx, rcx
convert_loop:
    mov cl, [rdi]
    cmp cl, 10             ; остановиться на переводе строки
    je done_convert
    cmp cl, 0              ; или на нулевом байте
    je done_convert
    sub cl, '0'
    imul rax, 10
    add rax, rcx
    inc rdi
    jmp convert_loop
done_convert:

    ; Сохраняем n
    mov [n], rax

    ; Вычисляем сумму ряда
    call compute_sum

    ; Выводим результат
    call print_result

    ; Завершаем программу
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

compute_sum:
    ; Инициализация суммы S = 0
    xor r12, r12
    
    ; k начинается с 1 до n
    mov r8, 1
    mov r9, 1              ; начальный знак = +1 (т.к. (-1)^(1+1) = 1)

sum_loop:
    ; Вычисляем k²
    mov rax, r8
    imul rax, rax          ; rax = k²

    ; Умножаем на знак (-1)^(k+1)
    imul rax, r9           ; rax = (-1)^(k+1) * k²

    ; Добавляем к сумме
    add r12, rax

    ; Меняем знак для следующей итерации
    neg r9
    
    ; Увеличиваем k
    inc r8
    cmp r8, [n]
    jle sum_loop
    
    ; Сохраняем результат
    mov [result], r12
    ret

print_result:
    ; Выводим "Result: "
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, result_label
    mov rdx, result_label_len
    syscall

    ; Выводим число
    mov rax, [result]
    mov rdi, number_buffer
    call int_to_string
    
    ; Добавляем перевод строки
    mov byte [rdi], 10
    inc rdi
    
    ; Вычисляем длину
    mov rdx, rdi
    sub rdx, number_buffer
    
    ; Выводим число
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, number_buffer
    syscall
    
    ret

int_to_string:
    ; Преобразует целое в строку
    test rax, rax
    jnz .convert
    
    ; Случай числа 0
    mov byte [rdi], '0'
    inc rdi
    ret
    
.convert:
    ; Проверяем знак
    cmp rax, 0
    jge .positive
    
    ; Отрицательное число
    mov byte [rdi], '-'
    inc rdi
    neg rax
    
.positive:
    push rbx
    mov rbx, 10
    xor rcx, rcx
    
.push_loop:
    xor rdx, rdx
    div rbx
    push rdx
    inc rcx
    test rax, rax
    jnz .push_loop
    
.pop_loop:
    pop rax
    add al, '0'
    mov [rdi], al
    inc rdi
    loop .pop_loop
    
    pop rbx
    ret

section '.data' writeable
    prompt_msg db 'Enter n: ', 0
    prompt_len = $ - prompt_msg
    result_label db 'Result: ', 0
    result_label_len = $ - result_label

section '.bss' writeable
    n dq ?
    result dq ?
    input_buffer rb 32
    number_buffer rb 32