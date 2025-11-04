format ELF64

; Системные вызовы
SYS_READ = 0
SYS_WRITE = 1
SYS_EXIT = 60

section '.text' executable
public _start

_start:
    ; Инициализация счетчика попыток
    mov byte [attempts], 5

auth_loop:
    ; Выводим приглашение для ввода пароля
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

    ; Убираем символ перевода строки из ввода
    mov rdi, input_buffer
    call remove_newline

    ; Проверяем пароль
    call check_password
    
    ; Если пароль верный - выход
    cmp byte [auth_success], 1
    je success
    
    ; Уменьшаем счетчик попыток
    dec byte [attempts]
    cmp byte [attempts], 0
    jle failure
    
    ; Выводим сообщение о неверном пароле
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, wrong_msg
    mov rdx, wrong_len
    syscall
    
    jmp auth_loop

success:
    ; Выводим сообщение об успехе
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, success_msg
    mov rdx, success_len
    syscall
    jmp exit_program

failure:
    ; Выводим сообщение о неудаче
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, failure_msg
    mov rdx, failure_len
    syscall

exit_program:
    ; Завершаем программу
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

remove_newline:
    ; Убираем символ перевода строки из буфера
    mov rcx, 32
.remove_loop:
    mov al, [rdi]
    cmp al, 10
    je .found_newline
    cmp al, 0
    je .done
    inc rdi
    loop .remove_loop
    ret
.found_newline:
    mov byte [rdi], 0
.done:
    ret

check_password:
    ; Сбрасываем флаг успеха
    mov byte [auth_success], 0
    
    ; Сравниваем с правильным паролем "password123"
    mov rsi, correct_password
    mov rdi, input_buffer
    
compare_loop:
    mov al, [rsi]
    mov bl, [rdi]
    cmp al, bl
    jne .not_equal
    
    ; Если оба символа нулевые - строки равны
    cmp al, 0
    je .equal
    
    inc rsi
    inc rdi
    jmp compare_loop
    
.equal:
    ; Пароль верный
    mov byte [auth_success], 1
    ret

.not_equal:
    ; Пароль неверный
    ret

section '.data' writeable
    prompt_msg db 'Enter password: ', 0
    prompt_len = $ - prompt_msg
    
    correct_password db 'password123', 0
    
    wrong_msg db 'Wrong password. Try again.', 10, 0
    wrong_len = $ - wrong_msg
    
    success_msg db 'Success! Access granted.', 10, 0
    success_len = $ - success_msg
    
    failure_msg db 'Failure! Too many attempts.', 10, 0
    failure_len = $ - failure_msg

section '.bss' writeable
    attempts db ?
    auth_success db ?
    input_buffer rb 32