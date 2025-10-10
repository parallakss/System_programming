section .data
    prompt     db "Введите n: ", 0
    format_in  db "%d", 0
    format_out db "Количество чисел от 1 до %d, делящихся на 37 и 13: %d", 10, 0

section .bss
    n resd 1

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

    ; Ввод n
    mov rdi, format_in
    mov rsi, n
    xor eax, eax
    call scanf

    ; Инициализация счетчиков
    mov ecx, 1          ; i = 1
    xor ebx, ebx        ; count = 0
    mov esi, [n]        ; ESI = n

loop_start:
    cmp ecx, esi
    jg end_loop

    ; Проверка деления на 37
    mov eax, ecx
    xor edx, edx
    mov edi, 37
    div edi
    test edx, edx
    jnz next_number

    ; Проверка деления на 13
    mov eax, ecx
    xor edx, edx
    mov edi, 13
    div edi
    test edx, edx
    jnz next_number

    ; Оба условия выполнены
    inc ebx

next_number:
    inc ecx
    jmp loop_start

end_loop:
    ; Вывод результата
    mov rdi, format_out
    mov esi, [n]
    mov edx, ebx
    xor eax, eax
    call printf

    ; Завершение программы
    pop rbp
    mov rax, 60
    xor rdi, rdi
    syscall