format ELF

section '.data' writeable
    symbol db '$'
    newline db 10

section '.bss' writeable
    buffer rb 153
    matrix_buffer rb 10

section '.text' executable
public _start

_start:
    ; Заполняем буфер
    mov edi, buffer
    mov ecx, 153
    mov al, [symbol]
.fill_buffer:
    mov [edi], al
    inc edi
    loop .fill_buffer
    
    ; Выводим матрицу 9x17
    mov esi, buffer
    mov ecx, 17
    
.matrix_loop:
    push ecx
    mov edi, matrix_buffer
    mov ecx, 9
    
.fill_row:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    loop .fill_row
    
    mov byte [edi], 10
    
    ; Вывод строки
    mov eax, 4
    mov ebx, 1
    mov ecx, matrix_buffer
    mov edx, 10
    int 0x80
    
    pop ecx
    loop .matrix_loop
    
    ; Завершение
    mov eax, 1
    xor ebx, ebx
    int 0x80