format ELF64

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
    mov [a], eax          ; сохраняем как 32-битное число

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
    mov [b], eax          ; сохраняем как 32-битное число

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
    mov [c], eax          ; сохраняем как 32-битное число

    ; Вычисляем выражение: ((((a/b)-a)/b)*c)+a
    call calculate_expression

    ; Выводим результат
    call print_result

    ; Завершаем программу
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

string_to_int:
    ; Преобразует строку в число (32-битное)
    xor eax, eax
    xor ecx, ecx
.convert_loop:
    mov cl, [rdi]
    cmp cl, 10
    je .done
    cmp cl, 0
    je .done
    sub cl, '0'
    imul eax, 10
    add eax, ecx
    inc rdi
    jmp .convert_loop
.done:
    ret

calculate_expression:
    ; Вычисляем ((((a/b)-a)/b)*c)+a (32-битная арифметика)
    
    ; a/b
    mov eax, [a]
    cdq                   ; расширяем eax в edx:eax
    idiv dword [b]        ; eax = a/b, edx = остаток
    
    ; (a/b) - a
    sub eax, [a]          ; eax = (a/b) - a
    
    ; ((a/b)-a)/b
    cdq                   ; расширяем eax в edx:eax
    idiv dword [b]        ; eax = ((a/b)-a)/b
    
    ; (((a/b)-a)/b)*c
    imul eax, [c]         ; eax = (((a/b)-a)/b)*c
    
    ; ((((a/b)-a)/b)*c)+a
    add eax, [a]          ; eax = ((((a/b)-a)/b)*c)+a
    
    mov [result], eax
    ret

print_result:
    ; Выводим "Result: "
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, result_label
    mov rdx, result_label_len
    syscall

    ; Выводим число
    mov eax, [result]
    mov rdi, output_buffer
    call int_to_string
    
    ; Добавляем перевод строки
    mov byte [rdi], 10
    inc rdi
    
    ; Вычисляем длину
    mov rdx, rdi
    sub rdx, output_buffer
    
    ; Выводим число
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, output_buffer
    syscall
    
    ret

int_to_string:
    ; Преобразует целое (32-битное) в строку
    test eax, eax
    jnz .convert
    
    ; Случай числа 0
    mov byte [rdi], '0'
    inc rdi
    ret
    
.convert:
    ; Проверяем знак
    cmp eax, 0
    jge .positive
    
    ; Отрицательное число
    mov byte [rdi], '-'
    inc rdi
    neg eax
    
.positive:
    push rbx
    mov ebx, 10
    xor ecx, ecx
    
.push_loop:
    xor edx, edx
    div ebx
    push rdx
    inc ecx
    test eax, eax
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
    input_buffer rb 32
    output_buffer rb 32