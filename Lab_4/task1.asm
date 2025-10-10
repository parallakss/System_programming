section .data
    prompt     db "Enter n: "
    prompt_len equ $ - prompt
    result1    db "Numbers from 1 to "
    result2    db " divisible by 37 and 13: "
    newline    db 10

section .bss
    input_buf resb 12
    n_str     resb 12
    count_str resb 12

section .text
    global _start

_start:
    ; Вывод приглашения
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt
    mov rdx, prompt_len
    syscall

    ; Ввод n через системный вызов read
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buf
    mov rdx, 12
    syscall

    ; Преобразование строки в число
    mov rsi, input_buf
    call atoi
    mov r8, rax        ; сохраняем n в r8

    ; Подсчет чисел
    mov r9, 1          ; i = 1
    xor r10, r10       ; count = 0

count_loop:
    cmp r9, r8
    jg end_count

    ; Проверка деления на 37
    mov rax, r9
    xor rdx, rdx
    mov rbx, 37
    div rbx
    test rdx, rdx
    jnz next_num

    ; Проверка деления на 13
    mov rax, r9
    xor rdx, rdx
    mov rbx, 13
    div rbx
    test rdx, rdx
    jnz next_num

    ; Оба условия выполнены
    inc r10

next_num:
    inc r9
    jmp count_loop

end_count:
    ; Вывод первой части результата
    mov rax, 1
    mov rdi, 1
    mov rsi, result1
    mov rdx, 17
    syscall

    ; Преобразование n в строку и вывод
    mov rax, r8
    mov rdi, n_str
    call itoa
    mov rsi, n_str
    call print_str

    ; Вывод второй части результата
    mov rax, 1
    mov rdi, 1
    mov rsi, result2
    mov rdx, 24
    syscall

    ; Преобразование count в строку и вывод
    mov rax, r10
    mov rdi, count_str
    call itoa
    mov rsi, count_str
    call print_str

    ; Новая строка
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Завершение программы
    mov rax, 60
    xor rdi, rdi
    syscall

; Преобразование строки в число (atoi)
atoi:
    xor rax, rax
    xor rcx, rcx
atoi_loop:
    mov cl, [rsi]
    cmp cl, 10
    je atoi_done
    cmp cl, '0'
    jb atoi_done
    cmp cl, '9'
    ja atoi_done
    sub cl, '0'
    imul rax, 10
    add rax, rcx
    inc rsi
    jmp atoi_loop
atoi_done:
    ret

; Преобразование числа в строку (itoa)
itoa:
    mov rbx, 10
    mov rcx, 0
    test rax, rax
    jnz itoa_loop
    mov byte [rdi], '0'
    mov byte [rdi+1], 0
    ret
itoa_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz itoa_loop
    mov rsi, rdi
itoa_pop:
    pop rax
    mov [rdi], al
    inc rdi
    loop itoa_pop
    mov byte [rdi], 0
    ret

; Вывод строки
print_str:
    mov rdi, rsi
    call strlen
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    syscall
    ret

; Длина строки
strlen:
    xor rax, rax
strlen_loop:
    cmp byte [rdi+rax], 0
    je strlen_done
    inc rax
    jmp strlen_loop
strlen_done:
    ret