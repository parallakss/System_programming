format ELF64

; Системные вызовы
SYS_READ = 0
SYS_WRITE = 1
SYS_EXIT = 60

section '.text' executable
public _start

_start:
    ; Вывод приглашения
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, prompt_msg
    mov rdx, prompt_len
    syscall
    
    ; Чтение символа
    mov rax, SYS_READ
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 2
    syscall

    ; Сохраняем введенный символ
    mov al, [input_buffer]
    mov [char], al
    
    ; Вывод начала результата
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, result_label
    mov rdx, result_label_len
    syscall

    ; Преобразуем ASCII-код символа в строку
    movzx rax, byte [char]    ; Загружаем символ с нулевым расширением
    mov rdi, output_buffer
    call int_to_string
    
    ; Добавляем перевод строки
    mov byte [rdi], 10
    inc rdi
    
    ; Вычисляем длину строки для вывода
    mov rdx, rdi
    sub rdx, output_buffer
    
    ; Вывод ASCII-кода
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, output_buffer
    syscall
    
    ; Завершение программы
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; Функция преобразования числа в строку
; Вход: RAX = число, RDI = буфер для строки
; Выход: RDI указывает на конец строки
int_to_string:
    mov rbx, 10          ; делитель для десятичной системы
    xor rcx, rcx         ; счетчик цифр
    
    ; Особый случай для числа 0
    test rax, rax
    jnz .push_loop
    push 0
    inc rcx
    jmp .pop_loop
    
.push_loop:
    xor rdx, rdx
    div rbx              ; RDX = остаток, RAX = частное
    add dl, '0'          ; преобразуем цифру в символ
    push rdx
    inc rcx
    test rax, rax
    jnz .push_loop
    
.pop_loop:
    pop rax
    mov [rdi], al
    inc rdi
    loop .pop_loop
    
    mov byte [rdi], 0    ; нулевой терминатор
    ret

section '.data' writeable
    prompt_msg db 'Enter character: ', 0
    prompt_len = $ - prompt_msg
    result_label db 'ASCII code: ', 0
    result_label_len = $ - result_label

section '.bss' writeable
    char db ?
    input_buffer rb 2
    output_buffer rb 16