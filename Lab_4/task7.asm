section .data
    prompt     db "Enter number m: "
    prompt_len equ $ - prompt
    result1    db "Digits of "
    result2    db " in reverse: "
    newline    db 10

section .bss
    input_buf resb 12
    m_str     resb 12
    rev_str   resb 12

section .text
    global _start

_start:
    ; Вывод приглашения
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt
    mov rdx, prompt_len
    syscall

    ; Ввод m через системный вызов read
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buf
    mov rdx, 12
    syscall

    ; Преобразование строки в число
    mov rsi, input_buf
    call atoi
    mov r8, rax        ; сохраняем m в r8

    ; Сохраняем оригинальное число
    mov r9, r8

    ; Обработка отрицательных чисел
    test r8, r8
    jns extract_digits
    neg r8

extract_digits:
    ; Извлечение цифр в обратном порядке
    mov rdi, rev_str
    mov rax, r8
    mov rbx, 10

    ; Обработка нуля
    test rax, rax
    jnz extract_loop
    mov byte [rdi], '0'
    inc rdi
    jmp finish_extract

extract_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    inc rdi
    test rax, rax
    jnz extract_loop

finish_extract:
    mov byte [rdi], 0

    ; Вывод результата
    mov rax, 1
    mov rdi, 1
    mov rsi, result1
    mov rdx, 10
    syscall

    ; Преобразование оригинального числа в строку
    mov rax, r9
    mov rdi, m_str
    call itoa
    mov rsi, m_str
    call print_str

    ; Вывод второй части
    mov rax, 1
    mov rdi, 1
    mov rsi, result2
    mov rdx, 13
    syscall

    ; Вывод обратных цифр
    mov rsi, rev_str
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

; Функции такие же как в task1
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

print_str:
    mov rdi, rsi
    call strlen
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    syscall
    ret

strlen:
    xor rax, rax
strlen_loop:
    cmp byte [rdi+rax], 0
    je strlen_done
    inc rax
    jmp strlen_loop
strlen_done:
    ret