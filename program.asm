format ELF64 executable 3
entry _start

; Системные вызовы
SYS_WRITE   = 1
SYS_EXIT    = 60
SYS_CLONE   = 56
SYS_WAITPID = 61

; Флаги для clone
CLONE_VM    = 0x00000100
CLONE_FS    = 0x00000200
CLONE_FILES = 0x00000400
CLONE_SIGHAND = 0x00000800
SIGCHLD     = 17

STACK_SIZE = 4096

segment readable executable

_start:
    ; Получаем аргументы командной строки
    pop rcx          ; argc
    cmp rcx, 2
    jl .no_arg
    
    pop rdi          ; argv[0]
    pop rdi          ; argv[1] - значение N
    call atoi
    mov [N], rax
    
    ; Инициализируем общую память
    mov qword [sum_add], 0
    mov qword [sum_sub], 0
    
    ; Создаем первый дочерний процесс (для сложения)
    mov rax, SYS_CLONE
    mov rdi, CLONE_VM or CLONE_FS or CLONE_FILES or CLONE_SIGHAND or SIGCHLD
    mov rsi, child_add_stack + STACK_SIZE  ; Указатель на вершину стека
    xor rdx, rdx
    xor r10, r10
    xor r8, r8
    xor r9, r9
    syscall
    
    test rax, rax
    jz .child_add_process     ; Если 0 - мы в дочернем процессе
    
    ; Сохраняем PID первого процесса
    mov [pid1], rax
    
    ; Создаем второй дочерний процесс (для вычитания)
    mov rax, SYS_CLONE
    mov rdi, CLONE_VM or CLONE_FS or CLONE_FILES or CLONE_SIGHAND or SIGCHLD
    mov rsi, child_sub_stack + STACK_SIZE  ; Указатель на вершину стека
    xor rdx, rdx
    xor r10, r10
    xor r8, r8
    xor r9, r9
    syscall
    
    test rax, rax
    jz .child_sub_process     ; Если 0 - мы в дочернем процессе
    
    ; Сохраняем PID второго процесса
    mov [pid2], rax
    
    ; Ожидаем завершения первого дочернего процесса
.wait_first:
    mov rax, SYS_WAITPID
    mov rdi, [pid1]
    xor rsi, rsi                ; status (NULL)
    xor rdx, rdx                ; options
    syscall
    
    ; Ожидаем завершения второго дочернего процесса
.wait_second:
    mov rax, SYS_WAITPID
    mov rdi, [pid2]
    xor rsi, rsi                ; status (NULL)
    xor rdx, rdx                ; options
    syscall
    
    ; Вычисляем итоговую сумму
    mov rax, [sum_add]
    sub rax, [sum_sub]
    
    ; Выводим результат
    call print_number
    
    ; Завершаем программу
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.no_arg:
    ; Выводим сообщение об ошибке
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, error_msg
    mov rdx, error_len
    syscall
    
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

; Процесс для сложения
.child_add_process:
    mov rcx, 0               ; i - текущее число (начинаем с 0)
    mov r8, [N]              ; N
    
.add_loop:
    cmp rcx, r8
    jg .add_done
    
    ; Определяем знак для текущего числа
    ; Паттерн: 0+, 1+, 2+, 3-, 4-, 5+, 6+, 7-, 8-, ...
    ; Можно заметить: (i % 4) = 0,1 -> +, (i % 4) = 2,3 -> -
    ; Но нужно учесть что мы начинаем с 0
    
    ; Для i от 0 до 2 включительно: +
    cmp rcx, 2
    jle .do_add
    
    ; Для i >= 3: проверяем позицию в цикле из 4 чисел
    mov rax, rcx
    sub rax, 3               ; (i - 3)
    xor rdx, rdx
    mov rbx, 4               ; Группы по 4 числа
    div rbx                  ; rax = номер группы, rdx = позиция в группе (0,1,2,3)
    
    ; В группе: позиция 0,1 -> вычитание, позиция 2,3 -> сложение
    cmp rdx, 2
    jge .do_add
    jmp .skip_add

.do_add:
    ; Добавляем число к сумме положительных
    mov rax, rcx
    lock add [sum_add], rax
    jmp .next_add

.skip_add:
    ; Это число не добавляется в сумму положительных
    ; (оно будет обработано вторым процессом как отрицательное)

.next_add:
    inc rcx
    jmp .add_loop

.add_done:
    ; Завершаем дочерний процесс
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; Процесс для вычитания
.child_sub_process:
    mov rcx, 0               ; i - текущее число
    mov r8, [N]              ; N
    
.sub_loop:
    cmp rcx, r8
    jg .sub_done
    
    ; Определяем знак для текущего числа
    ; Только числа, которые должны вычитаться
    
    ; Для i от 0 до 2 включительно: не вычитаются (они +)
    cmp rcx, 2
    jle .skip_sub
    
    ; Для i >= 3: проверяем позицию в цикле из 4 чисел
    mov rax, rcx
    sub rax, 3               ; (i - 3)
    xor rdx, rdx
    mov rbx, 4               ; Группы по 4 числа
    div rbx                  ; rax = номер группы, rdx = позиция в группе (0,1,2,3)
    
    ; В группе: позиция 0,1 -> вычитание, позиция 2,3 -> сложение
    cmp rdx, 2
    jge .skip_sub
    ; Иначе (0 или 1) -> вычитание

.do_sub:
    ; Добавляем число к сумме вычитаемых (потом будем вычитать из общей суммы)
    mov rax, rcx
    lock add [sum_sub], rax
    jmp .next_sub

.skip_sub:
    ; Это число не добавляется в сумму вычитаемых
    ; (оно будет обработано первым процессом как положительное)

.next_sub:
    inc rcx
    jmp .sub_loop

.sub_done:
    ; Завершаем дочерний процесс
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; Функция преобразования строки в число (atoi)
atoi:
    xor rax, rax            ; Обнуляем результат
    xor rcx, rcx            ; Для загрузки символа
    xor rbx, rbx            ; Для временных вычислений
    
.next_char:
    mov cl, byte [rdi]
    test cl, cl
    jz .done
    
    ; Проверяем, что символ - цифра
    cmp cl, '0'
    jl .invalid
    cmp cl, '9'
    jg .invalid
    
    ; Преобразуем цифру
    sub cl, '0'
    
    ; Умножаем текущий результат на 10 и добавляем новую цифру
    mov rbx, 10
    mul rbx
    add rax, rcx
    
    inc rdi
    jmp .next_char

.invalid:
    mov rax, -1
    
.done:
    ret

; Функция вывода числа (исправленная)
print_number:
    push rbx
    push r12
    push r13
    
    ; Сохраняем число
    mov r12, rax
    
    ; Выделяем буфер для строки (21 байт достаточно для 64-битного числа со знаком)
    sub rsp, 24
    mov rbx, rsp
    add rbx, 23
    mov byte [rbx], 0       ; Завершающий нуль
    
    ; Проверяем, отрицательное ли число
    test r12, r12
    jns .positive
    ; Отрицательное число - обрабатываем модуль
    mov r13, r12            ; Сохраняем оригинальное значение
    neg r12                 ; Берем модуль
    jmp .convert

.positive:
    mov r13, r12            ; Сохраняем оригинальное значение
    
    ; Проверяем особый случай 0
    test r12, r12
    jnz .convert
    dec rbx
    mov byte [rbx], '0'
    jmp .output

.convert:
    ; Конвертируем число в строку
    mov rax, r12
    mov rcx, 10
    
.convert_loop:
    dec rbx
    xor rdx, rdx
    div rcx
    add dl, '0'
    mov [rbx], dl
    test rax, rax
    jnz .convert_loop
    
    ; Добавляем знак минус для отрицательных чисел
    test r13, r13
    jns .output
    dec rbx
    mov byte [rbx], '-'

.output:
    ; Вычисляем длину строки
    mov rdx, rsp
    add rdx, 24
    sub rdx, rbx
    
    ; Выводим строку
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, rbx
    syscall
    
    ; Выводим символ новой строки
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    add rsp, 24
    pop r13
    pop r12
    pop rbx
    ret

segment readable writeable

; Общие переменные
N           dq 0
sum_add     dq 0
sum_sub     dq 0
pid1        dq 0
pid2        dq 0

; Сообщения
error_msg   db "Usage: program N", 10
error_len   = $ - error_msg
newline     db 10

; Стеки для дочерних процессов
child_add_stack rb STACK_SIZE
child_sub_stack rb STACK_SIZE