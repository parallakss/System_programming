format ELF

section '.data' writeable
    symbol db '8'
    newline db 10
    total_msg db 'Total symbols in triangle: 210',10
    total_msg_len = $ - total_msg

section '.bss' writeable
    line_buffer rb 256

section '.text' executable
public _start

_start:
    mov ebx, 20               ; счетчик строк
    mov ecx, 1                ; символов в строке
    
.triangle_loop:
    push ecx
    push ebx
    
    ; Заполняем строку
    mov edi, line_buffer
    mov eax, ecx
    mov al, [symbol]
    
.fill_line:
    mov [edi], al
    inc edi
    dec ecx
    jnz .fill_line
    
    mov byte [edi], 10
    
    ; Восстанавливаем количество символов
    pop ebx
    pop ecx
    push ecx
    
    ; Выводим строку
    mov eax, 4
    mov ebx, 1
    mov ecx, line_buffer
    mov edx, ecx
    inc edx
    int 0x80
    
    pop ecx
    inc ecx                   ; увеличиваем для следующей строки
    dec ebx                   ; уменьшаем счетчик строк
    jnz .triangle_loop
    
    ; Выводим сообщение
    mov eax, 4
    mov ebx, 1
    mov ecx, total_msg
    mov edx, total_msg_len
    int 0x80
    
    ; Завершение
    mov eax, 1
    xor ebx, ebx
    int 0x80