section .data
    prompt   db "Введите число m: ", 0
    format_in db "%d", 0
    result   db "Цифры числа %d в обратном порядке: ", 0
    newline  db 10, 0

section .bss
    m resd 1
    buffer resb 20

section .text
    global main
    extern printf, scanf

main:
    push rbp
    mov rbp, rsp
    
    ; Вывод приглашения
    mov rdi, prompt
    xor eax, eax
    call printf

    ; Ввод m
    mov rdi, format_in
    mov rsi, m
    xor eax, eax
    call scanf

    ; Получаем число
    mov eax, [m]
    mov r8, rax         ; сохраняем оригинальное число для вывода
    
    ; Подготавливаем обратный вывод цифр
    mov rdi, buffer
    mov byte [rdi], 0   ; нулевой байт в конце
    mov ebx, 10         ; основание системы
    
    ; Обрабатываем отрицательные числа
    test eax, eax
    jns extract_digits
    neg eax

extract_digits:
    ; Если число 0
    test eax, eax
    jnz extract_loop
    mov byte [rdi], '0'
    inc rdi
    jmp finish_buffer

extract_loop:
    xor edx, edx
    div ebx
    add dl, '0'
    mov [rdi], dl
    inc rdi
    test eax, eax
    jnz extract_loop

finish_buffer:
    mov byte [rdi], 0   ; завершающий нуль
    
    ; Вывод результата
    mov rdi, result
    mov esi, r8d        ; оригинальное число
    xor eax, eax
    call printf
    
    ; Вывод обратных цифр
    mov rdi, buffer
    xor eax, eax
    call printf
    
    ; Новая строка
    mov rdi, newline
    xor eax, eax
    call printf

    pop rbp
    mov rax, 60
    xor rdi, rdi
    syscall