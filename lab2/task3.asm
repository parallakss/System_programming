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
    mov ebx, 20              
    mov ecx, 1                
    
.triangle_loop:
    push ecx
    push ebx
    
    mov edi, line_buffer
    mov eax, ecx
    mov al, [symbol]
    
.fill_line:
    mov [edi], al
    inc edi
    dec ecx
    jnz .fill_line
    
    mov byte [edi], 10
    
    pop ebx
    pop ecx
    push ecx
    
    mov eax, 4
    mov ebx, 1
    mov ecx, line_buffer
    mov edx, ecx
    inc edx
    int 0x80
    
    pop ecx
    inc ecx                   
    dec ebx                   
    jnz .triangle_loop
    
    mov eax, 4
    mov ebx, 1
    mov ecx, total_msg
    mov edx, total_msg_len
    int 0x80
    
    mov eax, 1
    xor ebx, ebx
    int 0x80