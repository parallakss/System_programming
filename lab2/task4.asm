format ELF

section '.data' writeable
    number dd 2634342072     ; Исходное число (32-битное)
    buffer rb 20             ; Буфер для преобразования числа в строку
    result_msg db 'Sum of digits: '
    result_len = $ - result_msg
    newline db 10

section '.text' executable
public _start

_start:
    ; Вычисляем сумму цифр
    mov eax, [number]        ; Загружаем число в eax
    mov ecx, 10              ; Делитель для получения цифр
    xor ebx, ebx             ; ebx будет содержать сумму цифр (обнуляем)
    
sum_loop:
    xor edx, edx             ; Обнуляем edx перед делением
    div ecx                  ; eax / 10: eax = частное, edx = остаток (цифра)
    add ebx, edx             ; Добавляем цифру к сумме
    
    test eax, eax            ; Проверяем, осталось ли что-то в числе
    jnz sum_loop             ; Если eax != 0, продолжаем
    
    
    mov eax, 4
    mov ebx, 1
    mov ecx, result_msg
    mov edx, result_len
    int 0x80
    

    mov eax, ebx             ; Копируем сумму в eax
    mov edi, buffer + 19     ; Указатель на конец буфера
    mov byte [edi], 0        ; Завершающий нуль (не обязательно для write)
    mov ecx, 10              ; Делитель для преобразования в десятичную
    
convert_loop:
    dec edi                  ; Перемещаемся назад в буфере
    xor edx, edx             ; Обнуляем edx
    div ecx                  ; eax / 10: eax = частное, edx = остаток
    add dl, '0'              ; Преобразуем цифру в символ
    mov [edi], dl            ; Сохраняем символ в буфер
    
    test eax, eax            ; Проверяем, осталось ли число
    jnz convert_loop         ; Если да, продолжаем
    

    mov esi, edi             ; Сохраняем начало строки
    mov edi, buffer + 19     ; Конец буфера
    sub edi, esi             ; edi = длина строки
    
   
    mov eax, 4
    mov ebx, 1
    mov ecx, esi             ; Указатель на начало строки
    mov edx, edi             ; Длина строки
    int 0x80
    
   
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    

    mov eax, 1
    xor ebx, ebx
    int 0x80