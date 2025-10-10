section .data
    correct_pass db "secret123", 0
    prompt       db "Enter password (attempts left: "
    prompt_len   equ $ - prompt
    attempt_msg  db "): "
    attempt_len  equ $ - attempt_msg
    wrong_pass   db "Wrong password", 10
    wrong_len    equ $ - wrong_pass
    success      db "Access granted", 10
    success_len  equ $ - success
    failure      db "Access denied", 10
    failure_len  equ $ - failure

section .bss
    input_buf resb 20
    attempts_str resb 4

section .text
    global _start

_start:
    mov r12, 5          ; количество попыток

auth_loop:
    ; Проверка количества попыток
    cmp r12, 0
    jle auth_failure

    ; Вывод приглашения
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt
    mov rdx, prompt_len
    syscall

    ; Преобразование номера попытки в строку
    mov rax, r12
    mov rdi, attempts_str
    call itoa
    mov rsi, attempts_str
    call print_str

    ; Вывод ": "
    mov rax, 1
    mov rdi, 1
    mov rsi, attempt_msg
    mov rdx, attempt_len
    syscall

    ; Ввод пароля через системный вызов read
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buf
    mov rdx, 20
    syscall

    ; Удаление символа новой строки
    mov rdi, input_buf
    call remove_newline

    ; Сравнение паролей
    mov rsi, input_buf
    mov rdi, correct_pass
    call strcmp
    test rax, rax
    jz password_correct

    ; Пароль неверный
    mov rax, 1
    mov rdi, 1
    mov rsi, wrong_pass
    mov rdx, wrong_len
    syscall

    dec r12
    jmp auth_loop

password_correct:
    ; Пароль верный
    mov rax, 1
    mov rdi, 1
    mov rsi, success
    mov rdx, success_len
    syscall
    jmp exit

auth_failure:
    mov rax, 1
    mov rdi, 1
    mov rsi, failure
    mov rdx, failure_len
    syscall

exit:
    ; Завершение программы
    mov rax, 60
    xor rdi, rdi
    syscall

; Сравнение строк
strcmp:
strcmp_loop:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne strcmp_diff
    test al, al
    jz strcmp_equal
    inc rdi
    inc rsi
    jmp strcmp_loop
strcmp_equal:
    xor rax, rax
    ret
strcmp_diff:
    mov rax, 1
    ret

; Удаление символа новой строки
remove_newline:
    mov rsi, rdi
remove_loop:
    mov al, [rsi]
    cmp al, 10
    je found_newline
    cmp al, 0
    je remove_done
    inc rsi
    jmp remove_loop
found_newline:
    mov byte [rsi], 0
remove_done:
    ret

; Функции itoa и print_str
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