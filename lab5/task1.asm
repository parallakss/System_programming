format ELF64

SYS_READ = 0
SYS_WRITE = 1
SYS_OPEN = 2
SYS_CLOSE = 3
SYS_EXIT = 60

; Флаги для открытия файлов
O_RDONLY = 0
O_WRONLY = 1
O_CREAT = 64
O_TRUNC = 512

; Размер буфера для чтения
BUFFER_SIZE = 4096

section '.text' executable
public _start

_start:
    ; Получаем аргументы командной строки
    pop rcx
    cmp rcx, 3
    jne usage_error

    ; Пропускаем имя программы
    pop rdi
    
    ; Получаем имена файлов
    pop rdi                     ; Входной файл
    pop rsi                     ; Выходной файл

    ; Сохраняем имена файлов
    mov [input_file], rdi
    mov [output_file], rsi

    ; Открываем входной файл
    mov rax, SYS_OPEN
    mov rdi, [input_file]
    mov rsi, O_RDONLY
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl open_input_error
    mov [input_fd], rax

    ; Открываем выходной файл
    mov rax, SYS_OPEN
    mov rdi, [output_file]
    mov rsi, O_WRONLY or O_CREAT or O_TRUNC
    mov rdx, 0644o
    syscall
    cmp rax, 0
    jl open_output_error
    mov [output_fd], rax

    ; Инициализируем счетчики
    mov qword [letters], 0
    mov qword [digits], 0

read_loop:
    ; Читаем из файла
    mov rax, SYS_READ
    mov rdi, [input_fd]
    mov rsi, buffer
    mov rdx, BUFFER_SIZE
    syscall

    ; Проверяем результат чтения
    cmp rax, 0
    jl read_error
    je write_result             ; Конец файла

    ; Обрабатываем прочитанные данные
    mov rcx, rax                ; Длина прочитанных данных
    mov rsi, buffer             ; Указатель на данные

process_byte:
    mov al, [rsi]               ; Текущий символ

    ; Проверяем, является ли символ буквой
    cmp al, 'A'
    jb not_uppercase
    cmp al, 'Z'
    ja not_uppercase
    inc qword [letters]         ; Нашли заглавную букву
    jmp next_byte

not_uppercase:
    cmp al, 'a'
    jb not_lowercase
    cmp al, 'z'
    ja not_lowercase
    inc qword [letters]         ; Нашли строчную букву
    jmp next_byte

not_lowercase:
    ; Проверяем, является ли символ цифрой
    cmp al, '0'
    jb next_byte
    cmp al, '9'
    ja next_byte
    inc qword [digits]          ; Нашли цифру

next_byte:
    inc rsi
    dec rcx
    jnz process_byte
    jmp read_loop

write_result:
    ; Формируем строку результата
    mov rdi, output_buffer

    ; Копируем "number of letters:"
    mov rsi, letters_msg
copy_letters_msg:
    mov al, [rsi]
    test al, al
    jz add_letters_count
    mov [rdi], al
    inc rsi
    inc rdi
    jmp copy_letters_msg

add_letters_count:
    ; Добавляем количество букв
    mov rax, [letters]
    call number_to_string

    ; Добавляем перевод строки
    mov byte [rdi], 10
    inc rdi

    ; Копируем "number of digits:"
    mov rsi, digits_msg
copy_digits_msg:
    mov al, [rsi]
    test al, al
    jz add_digits_count
    mov [rdi], al
    inc rsi
    inc rdi
    jmp copy_digits_msg

add_digits_count:
    ; Добавляем количество цифр
    mov rax, [digits]
    call number_to_string

    ; Добавляем перевод строки
    mov byte [rdi], 10
    inc rdi

    ; Вычисляем длину результата
    mov rdx, rdi
    sub rdx, output_buffer

    ; Записываем результат в файл
    mov rax, SYS_WRITE
    mov rdi, [output_fd]
    mov rsi, output_buffer
    syscall

    ; Закрываем файлы
    mov rax, SYS_CLOSE
    mov rdi, [input_fd]
    syscall

    mov rax, SYS_CLOSE
    mov rdi, [output_fd]
    syscall

    ; Выход
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; Функция преобразования числа в строку
; Вход: RAX - число, RDI - буфер для записи
number_to_string:
    push rbx
    push rcx
    push rdx

    mov rbx, 10                 ; Основание системы
    lea rcx, [rdi + 32]         ; Конец буфера
    mov byte [rcx], 0           ; Завершающий ноль
    dec rcx

    test rax, rax
    jnz convert_loop
    mov byte [rcx], '0'
    dec rcx
    jmp copy_number

convert_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rcx], dl
    dec rcx
    test rax, rax
    jnz convert_loop

copy_number:
    inc rcx
    mov al, [rcx]
    test al, al
    jz done
    mov [rdi], al
    inc rcx
    inc rdi
    jmp copy_number

done:
    pop rdx
    pop rcx
    pop rbx
    ret

; Обработчики ошибок
usage_error:
    mov rax, SYS_WRITE
    mov rdi, 2
    mov rsi, usage_msg
    mov rdx, usage_len
    syscall
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

open_input_error:
    mov rax, SYS_WRITE
    mov rdi, 2
    mov rsi, input_error_msg
    mov rdx, input_error_len
    syscall
    mov rax, SYS_EXIT
    mov rdi, 2
    syscall

open_output_error:
    mov rax, SYS_WRITE
    mov rdi, 2
    mov rsi, output_error_msg
    mov rdx, output_error_len
    syscall
    mov rax, SYS_EXIT
    mov rdi, 3
    syscall

read_error:
    mov rax, SYS_WRITE
    mov rdi, 2
    mov rsi, read_error_msg
    mov rdx, read_error_len
    syscall
    mov rax, SYS_EXIT
    mov rdi, 4
    syscall

section '.data' writeable

; Сообщения об ошибках
usage_msg db 'Usage: ./program input_file output_file', 10
usage_len = $ - usage_msg

input_error_msg db 'Error: Cannot open input file', 10
input_error_len = $ - input_error_msg

output_error_msg db 'Error: Cannot open output file', 10
output_error_len = $ - output_error_msg

read_error_msg db 'Error: Cannot read from file', 10
read_error_len = $ - read_error_msg

; Сообщения для вывода
letters_msg db 'number of letters:', 0
digits_msg db 'number of digits:', 0

; Переменные
input_file dq 0
output_file dq 0
input_fd dq 0
output_fd dq 0
letters dq 0
digits dq 0

buffer rb BUFFER_SIZE
output_buffer rb 256