format ELF

section '.data' writeable
    original_str db 'eWTAghRYsHMeIYxtfCbeQoDvnQaKdRkKzJboR',0
    str_len = $ - original_str - 1
    newline db 10

section '.bss' writeable
    reversed_str rb str_len + 1

section '.text' executable
public _start

_start:
    mov esi, original_str
    mov edi, reversed_str
    mov ecx, str_len
    
.reverse_loop:
    mov al, [esi + ecx - 1]
    mov [edi], al
    inc edi
    dec ecx
    jnz .reverse_loop
    
    mov byte [edi], 10
    
    mov eax, 4
    mov ebx, 1
    mov ecx, original_str
    mov edx, str_len
    int 0x80
    
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    
    mov eax, 4
    mov ebx, 1
    mov ecx, reversed_str
    mov edx, str_len + 1
    int 0x80
    
    mov eax, 1
    xor ebx, ebx
    int 0x80