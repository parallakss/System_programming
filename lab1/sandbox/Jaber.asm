format ELF

section '.data' writeable
    surname    db 'Жабер', 0x0A
    surname_len = $ - surname

    name       db 'Илья', 0x0A
    name_len = $ - name

    patronymic db 'Анварович', 0x0A
    patronymic_len = $ - patronymic

section '.text' executable
public _start

_start:
    
    mov eax, 4          
    mov ebx, 1         
    mov ecx, surname
    mov edx, surname_len
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, name
    mov edx, name_len
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, patronymic
    mov edx, patronymic_len
    int 0x80

    mov eax, 1          
    xor ebx, ebx        
    int 0x80