format ELF64
;(((((a/b)-a)/b)*c)+a)
; Системные вызовы
SYS_READ = 0
SYS_WRITE = 1
SYS_EXIT = 60

section '.text' executable
public _start

_start:
    ; Ввод a
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, prompt_a
    mov rdx, prompt_a_len
    syscall
    
    mov rax, SYS_READ
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 32
    syscall
    
    mov rdi, input_buffer
    call string_to_int
    mov [a], eax          

    ; Ввод b
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, prompt_b
    mov rdx, prompt_b_len
    syscall
    
    mov rax, SYS_READ
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 32
    syscall
    
    mov rdi, input_buffer
    call string_to_int
    mov [b], eax         

    ; Ввод c
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, prompt_c
    mov rdx, prompt_c_len
    syscall
    
    mov rax, SYS_READ
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 32
    syscall
    
    mov rdi, input_buffer
    call string_to_int
    mov [c], eax          

    call calculate_expression

    call print_result

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

string_to_int:
    xor eax, eax
    xor ecx, ecx
    xor edx, edx          ; флаг знака
    mov byte [sign], 0    ; сброс флага знака
    
    ; Проверка на знак минус
    mov cl, [rdi]
    cmp cl, '-'
    jne .convert_loop
    mov byte [sign], 1    ; установить флаг отрицательного числа
    inc rdi
    
.convert_loop:
    mov cl, [rdi]
    cmp cl, 10
    je .check_sign
    cmp cl, 0
    je .check_sign
    cmp cl, '0'
    jb .error
    cmp cl, '9'
    ja .error
    sub cl, '0'
    imul eax, 10
    add eax, ecx
    inc rdi
    jmp .convert_loop
    
.check_sign:
    cmp byte [sign], 1
    jne .done
    neg eax
    jmp .done
    
.error:
    ; Если ввод некорректен, возвращаем 0
    xor eax, eax
    
.done:
    ret

calculate_expression:
    ; Вычисляем a / b
    mov eax, [a]
    cdq                    ; расширяем eax в edx:eax для деления
    idiv dword [b]        ; eax = a / b, edx = a % b
    
    ; (a/b) - a
    sub eax, [a]          ; eax = (a/b) - a
    
    ; ((a/b)-a) / b
    cdq                   ; снова расширяем для деления
    idiv dword [b]        ; eax = ((a/b)-a) / b
    
    ; (((a/b)-a)/b) * c
    imul eax, [c]         ; eax = (((a/b)-a)/b) * c
    
    ; ((((a/b)-a)/b)*c) + a
    add eax, [a]          ; eax = ((((a/b)-a)/b)*c) + a
    
    mov [result], eax
    ret

print_result:
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, result_label
    mov rdx, result_label_len
    syscall

    mov eax, [result]
    mov rdi, output_buffer
    call int_to_string
    
    ; Добавляем перевод строки
    mov byte [rdi], 10
    inc rdi
    
    ; Вычисляем длину строки
    mov rdx, rdi
    sub rdx, output_buffer
    
    ; Выводим результат
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, output_buffer
    syscall
    
    ret

int_to_string:
    ; Сохраняем результат в r8 для безопасного использования
    mov r8d, eax
    
    ; Проверяем на ноль
    test r8d, r8d
    jnz .convert
    
    ; Если ноль
    mov byte [rdi], '0'
    inc rdi
    jmp .done
    
.convert:
    ; Проверяем знак
    mov eax, r8d
    cmp eax, 0
    jge .positive

    ; Отрицательное число
    mov byte [rdi], '-'
    inc rdi
    neg eax
    jmp .convert_digits
    
.positive:
    ; Положительное число
    mov byte [sign], 0
    
.convert_digits:
    push rbx
    mov ebx, 10
    xor ecx, ecx
    
.push_loop:
    xor edx, edx
    div ebx               ; edx = остаток, eax = частное
    add dl, '0'           ; преобразуем цифру в символ
    push rdx
    inc ecx
    test eax, eax
    jnz .push_loop
    
.pop_loop:
    pop rax
    mov [rdi], al
    inc rdi
    loop .pop_loop
    
    pop rbx
    
.done:
    mov byte [rdi], 0     ; нулевой терминатор
    ret

section '.data' writeable
    prompt_a db 'Enter a: ', 0
    prompt_a_len = $ - prompt_a
    prompt_b db 'Enter b: ', 0
    prompt_b_len = $ - prompt_b
    prompt_c db 'Enter c: ', 0
    prompt_c_len = $ - prompt_c
    result_label db 'Result: ', 0
    result_label_len = $ - result_label

section '.bss' writeable
    a dd ?
    b dd ?
    c dd ?
    result dd ?
    sign db ?
    input_buffer rb 32
    output_buffer rb 32