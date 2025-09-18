format ELF executable
entry start

segment readable executable

start:
    ; Вывод фамилии
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, surname    ; строка фамилии
    mov edx, surname_len ; длина
    int 0x80

    ; Вывод имени
    mov eax, 4
    mov ebx, 1
    mov ecx, name
    mov edx, name_len
    int 0x80

    ; Вывод отчества
    mov eax, 4
    mov ebx, 1
    mov ecx, patronymic
    mov edx, patronymic_len
    int 0x80

    ; Завершение программы
    mov eax, 1          ; sys_exit
    xor ebx, ebx        ; код 0
    int 0x80

segment readable writeable

surname    db 'Жабер', 0x0A    ; 
surname_len = $ - surname

name       db 'Илья', 0x0A      ;
name_len = $ - name

patronymic db 'Анварович', 0x0A  ; 
patronymic_len = $ - patronymic
