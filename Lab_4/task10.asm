section .data
    correct_pass db "secret123", 0
    prompt       db "Введите пароль (осталось попыток: ", 0
    attempt_msg  db "): ", 0
    wrong_pass   db "Неверный пароль", 10, 0
    success      db "Вход", 10, 0
    failure      db "Неудача", 10, 0
    format_int   db "%d", 0
    format_str   db "%19s", 0    ; ограничение длины ввода

section .bss
    password  resb 20
    attempts  resd 1

section .text
    global main
    extern printf, scanf, strcmp

main:
    push rbp
    mov rbp, rsp
    
    ; Инициализация счетчика попыток
    mov dword [attempts], 5

auth_loop:
    ; Проверка количества попыток
    cmp dword [attempts], 0
    jle auth_failure

    ; Вывод приглашения
    mov rdi, prompt
    xor eax, eax
    call printf

    ; Вывод номера попытки
    mov rdi, format_int
    mov esi, [attempts]
    xor eax, eax
    call printf

    mov rdi, attempt_msg
    xor eax, eax
    call printf

    ; Ввод пароля
    mov rdi, format_str
    mov rsi, password
    xor eax, eax
    call scanf

    ; Сравнение паролей
    mov rdi, password
    mov rsi, correct_pass
    call strcmp
    test eax, eax
    jz password_correct

    ; Пароль неверный
    mov rdi, wrong_pass
    xor eax, eax
    call printf

    ; Уменьшение счетчика попыток
    dec dword [attempts]
    jmp auth_loop

password_correct:
    ; Пароль верный
    mov rdi, success
    xor eax, eax
    call printf
    jmp exit

auth_failure:
    mov rdi, failure
    xor eax, eax
    call printf

exit:
    ; Завершение программы
    pop rbp
    mov rax, 60
    xor rdi, rdi
    syscall