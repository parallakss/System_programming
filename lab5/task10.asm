format ELF64

; Константы для системных вызовов
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

    ; Инициализируем буфер предложения
    mov qword [sentence_len], 0

process_file:
    ; Читаем из файла
    mov rax, SYS_READ
    mov rdi, [input_fd]
    mov rsi, buffer
    mov rdx, BUFFER_SIZE
    syscall

    ; Проверяем результат чтения
    cmp rax, 0
    jl read_error
    je process_final_sentence    ; Конец файла

    ; Обрабатываем прочитанные данные
    mov rcx, rax                ; Длина прочитанных данных
    mov rsi, buffer             ; Указатель на данные

process_char:
    mov al, [rsi]               ; Текущий символ

    ; Сохраняем символ в буфер предложения
    mov rdi, [sentence_len]
    mov [sentence_buffer + rdi], al
    inc qword [sentence_len]

    ; Проверяем конец предложения
    cmp al, '.'
    je found_sentence_end
    cmp al, '!'
    je found_sentence_end
    cmp al, '?'
    je found_sentence_end
    cmp al, 10                  ; Перевод строки
    je found_sentence_end
    
    jmp next_char

found_sentence_end:
    ; Обрабатываем предложение
    call reverse_and_write_sentence
    
    ; Сбрасываем буфер для следующего предложения
    mov qword [sentence_len], 0
    
next_char:
    inc rsi
    dec rcx
    jnz process_char
    jmp process_file

process_final_sentence:
    ; Обрабатываем последнее предложение (если есть)
    cmp qword [sentence_len], 0
    je close_files
    call reverse_and_write_sentence

close_files:
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

; Функция переворота предложения и записи в файл
reverse_and_write_sentence:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    mov rcx, [sentence_len]
    test rcx, rcx
    jz .done                    ; Пустое предложение
    
    ; Находим позицию последнего символа (исключая символ конца)
    mov rbx, rcx
    dec rbx                     ; rbx = sentence_len - 1
    
    ; Проверяем, является ли последний символ концом предложения
    mov al, [sentence_buffer + rbx]
    cmp al, '.'
    je .has_end
    cmp al, '!'
    je .has_end
    cmp al, '?'
    je .has_end
    cmp al, 10
    je .has_end
    ; Если нет символа конца, переворачиваем всю строку
    inc rbx
    jmp .reverse_all

.has_end:
    ; Сохраняем символ конца
    mov [end_char], al
    
    ; Переворачиваем часть до символа конца
    mov rdx, output_buffer      ; Буфер для результата
    mov rsi, rbx
    dec rsi                     ; Позиция перед символом конца
    
.reverse_loop:
    test rsi, rsi
    js .add_end_char            ; Если rsi < 0
    mov al, [sentence_buffer + rsi]
    mov [rdx], al
    inc rdx
    dec rsi
    jmp .reverse_loop

.reverse_all:
    ; Переворачиваем всю строку (нет символа конца)
    mov rdx, output_buffer
    mov rsi, rbx
    dec rsi
    
.reverse_all_loop:
    test rsi, rsi
    js .add_newline
    mov al, [sentence_buffer + rsi]
    mov [rdx], al
    inc rdx
    dec rsi
    jmp .reverse_all_loop

.add_end_char:
    ; Добавляем сохраненный символ конца
    mov al, [end_char]
    mov [rdx], al
    inc rdx
    jmp .add_newline

.add_newline:
    ; Добавляем перевод строки
    mov byte [rdx], 10
    inc rdx
    
    ; Вычисляем длину
    mov rcx, rdx
    sub rcx, output_buffer
    
    ; Записываем в файл
    mov rax, SYS_WRITE
    mov rdi, [output_fd]
    mov rsi, output_buffer
    mov rdx, rcx
    syscall

.done:
    pop rdi
    pop rsi
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

section '.bss' writeable

; Переменные
input_file dq 0
output_file dq 0
input_fd dq 0
output_fd dq 0
sentence_len dq 0
end_char db 0

; Буферы
buffer rb BUFFER_SIZE
sentence_buffer rb 1024         ; Буфер для одного предложения
output_buffer rb 1024           ; Буфер для вывода

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