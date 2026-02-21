format ELF64

SYS_READ = 0
SYS_WRITE = 1
SYS_EXIT = 60
SYS_FORK = 57
SYS_WAIT4 = 61
SYS_MMAP = 9
SYS_MUNMAP = 11

STDIN = 0
STDOUT = 1
STDERR = 2

PROT_READ = 0x1
PROT_WRITE = 0x2
MAP_PRIVATE = 0x02
MAP_ANONYMOUS = 0x20

ARRAY_SIZE = 9         

section '.text' executable
public _start

_start:
    ; Инициализация генератора случайных чисел
    rdtsc
    mov [seed], eax

    ; Создание анонимного отображения для массива
    mov rax, SYS_MMAP
    xor rdi, rdi
    mov rsi, ARRAY_SIZE * 4
    mov rdx, PROT_READ or PROT_WRITE
    mov r10, MAP_PRIVATE or MAP_ANONYMOUS
    mov r8, -1
    xor r9, r9
    syscall
    cmp rax, -1
    je mmap_error
    mov [array_ptr], rax

    ; Заполнение массива случайными числами
    mov rbx, rax
    mov rcx, ARRAY_SIZE
    xor rdx, rdx

fill_loop:
    cmp rdx, rcx
    jge fill_done
    call random_number
    and eax, 0x7F
    mov [rbx + rdx*4], eax
    inc rdx
    jmp fill_loop

fill_done:
    ; ===== ВЫВОД СГЕНЕРИРОВАННЫХ ЧИСЕЛ =====
    mov rsi, msg_numbers
    call print_string
    call print_newline

    mov rbx, [array_ptr]
    mov r14, ARRAY_SIZE          ; r14 = размер 
    xor r15, r15                 ; индекс

print_numbers_loop:
    cmp r15, r14
    jge print_numbers_done

    mov eax, [rbx + r15*4]
    call print_int

    ; выводим пробел
    push rax
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, space
    mov rdx, 1
    syscall
    pop rax

    inc r15
    jmp print_numbers_loop

print_numbers_done:
    call print_newline
    call print_newline

    ; Создание 4 дочерних процессов
    mov r12, 0

create_processes:
    cmp r12, 4
    jge parent_wait

    mov rax, SYS_FORK
    syscall
    cmp rax, 0
    je child_process
    jl fork_error
    inc r12
    jmp create_processes

child_process:
    mov r13, r12
    cmp r13, 0
    je task1
    cmp r13, 1
    je task2
    cmp r13, 2
    je task3
    cmp r13, 3
    je task4
    jmp child_exit

; Задание 1
task1:
    mov rbx, [array_ptr]
    mov rcx, ARRAY_SIZE
    xor r14, r14
    xor r15, r15
task1_loop:
    cmp r15, rcx
    jge task1_done
    mov eax, [rbx + r15*4]
    xor edx, edx
    mov edi, 5
    div edi
    cmp edx, 0
    jne task1_next
    inc r14
task1_next:
    inc r15
    jmp task1_loop
task1_done:
    mov rsi, msg1
    call print_string
    mov rax, r14
    call print_int
    call print_newline
    jmp child_exit

; Задание 2
task2:
    mov rbx, [array_ptr]
    mov rcx, ARRAY_SIZE
    xor r14, r14
    xor r15, r15
task2_loop:
    cmp r15, rcx
    jge task2_calc
    add r14d, [rbx + r15*4]
    inc r15
    jmp task2_loop
task2_calc:
    mov eax, r14d
    xor edx, edx
    div ecx
    mov rsi, msg2
    call print_string
    call print_int
    call print_newline
    jmp child_exit

; Задание 3
task3:
    mov rbx, [array_ptr]
    mov rcx, ARRAY_SIZE
    xor r14, r14
    xor r15, r15
task3_loop:
    cmp r15, rcx
    jge task3_done
    mov eax, [rbx + r15*4]
    call digit_sum
    xor edx, edx
    mov edi, 3
    div edi
    cmp edx, 0
    jne task3_next
    inc r14
task3_next:
    inc r15
    jmp task3_loop
task3_done:
    mov rsi, msg3
    call print_string
    mov rax, r14
    call print_int
    call print_newline
    jmp child_exit

; Задание 4
; Задание 4: Пятый по минимальности элемент (5-й наименьший)
task4:
    mov rbx, [array_ptr]                   ; RBX = указатель на массив
    mov rcx, ARRAY_SIZE                     ; RCX = размер массива
    
    ; Копируем массив для сортировки (чтобы не портить оригинал)
    ; Но у нас каждый процесс работает с копией памяти (MAP_PRIVATE),
    ; так что можно сортировать оригинал - изменения не затронут другие процессы
    
    ; Простейшая сортировка пузырьком для нахождения 5-го наименьшего
    mov r14, 0                               ; Внешний цикл (i)

bubble_sort_outer:
    cmp r14, 5                               ; Нам нужно только 5 проходов, чтобы 5 наименьших всплыли
    jge get_fifth_min
    
    mov r15, 0                               ; Внутренний цикл (j)
    mov r12, rcx
    dec r12                                  ; r12 = размер - 1

bubble_sort_inner:
    cmp r15, r12
    jge bubble_next_outer
    
    ; Сравниваем [j] и [j+1]
    mov eax, [rbx + r15*4]
    mov edx, [rbx + r15*4 + 4]
    cmp eax, edx
    jle no_swap
    
    ; Меняем местами
    mov [rbx + r15*4], edx
    mov [rbx + r15*4 + 4], eax

no_swap:
    inc r15
    jmp bubble_sort_inner

bubble_next_outer:
    inc r14
    jmp bubble_sort_outer

get_fifth_min:
    ; После 5 проходов пузырька 5-й наименьший элемент будет на позиции 4 (индекс с 0)
    mov eax, [rbx + 4*4]                     ; 5-й наименьший (индекс 4)
    
    mov rsi, msg4                            ; Адрес сообщения
    call print_string                         ; Выводим сообщение
    call print_int                            ; Выводим число
    call print_newline                        ; Переводим строку
    jmp child_exit                            ; Выходим                      ; Выходим                       ; Выходим

child_exit:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

parent_wait:
    mov r12, 4
wait_loop:
    mov rax, SYS_WAIT4
    mov rdi, -1
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    syscall
    dec r12
    jnz wait_loop

    ; освобождение памяти
    mov rax, SYS_MUNMAP
    mov rdi, [array_ptr]
    mov rsi, ARRAY_SIZE * 4
    syscall

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; Функция вывода строки
print_string:
    push rax
    push rdi
    push rdx
    mov rdi, rsi
    call strlen
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    pop rdx
    pop rdi
    pop rax
    ret

; Функция вывода числа (десятичного)
print_int:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    mov rbx, 10
    xor rcx, rcx
    lea rdi, [num_buffer + 31]
    mov byte [rdi], 0
    test rax, rax
    jnz convert_int
    mov byte [rdi-1], '0'
    dec rdi
    inc rcx
    jmp print_num
convert_int:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rdi
    mov [rdi], dl
    inc rcx
    test rax, rax
    jnz convert_int
print_num:
    mov rsi, rdi
    mov rdx, rcx
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; Функция вывода перевода строки
print_newline:
    push rax
    push rdi
    push rsi
    push rdx
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, newline
    mov rdx, 1
    syscall
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Функция вычисления длины строки
strlen:
    push rcx
    push rdi
    mov rcx, -1
    xor al, al
    repne scasb
    mov rax, rcx
    not rax
    dec rax
    pop rdi
    pop rcx
    ret

; Генератор случайных чисел
random_number:
    push rdx
    push rcx
    mov eax, [seed]
    mov edx, eax
    shl eax, 13
    xor eax, edx
    mov edx, eax
    shr eax, 17
    xor eax, edx
    mov edx, eax
    shl eax, 5
    xor eax, edx
    mov [seed], eax
    pop rcx
    pop rdx
    ret

; Функция вычисления суммы цифр числа
digit_sum:
    push rbx
    push rcx
    push rdx
    mov ebx, 10
    xor ecx, ecx
digit_sum_loop:
    test eax, eax
    jz digit_sum_done
    xor edx, edx
    div ebx
    add ecx, edx
    jmp digit_sum_loop
digit_sum_done:
    mov eax, ecx
    pop rdx
    pop rcx
    pop rbx
    ret

; Обработчики ошибок
mmap_error:
    mov rax, SYS_WRITE
    mov rdi, STDERR
    mov rsi, mmap_error_msg
    mov rdx, mmap_error_len
    syscall
    jmp exit_error

fork_error:
    mov rax, SYS_WRITE
    mov rdi, STDERR
    mov rsi, fork_error_msg
    mov rdx, fork_error_len
    syscall
    jmp parent_wait

exit_error:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

section '.data' writeable

msg_numbers db 'Сгенерированные числа:', 0
msg1 db 'Количество чисел кратных пяти: ', 0
msg2 db 'Среднее арифметическое: ', 0
msg3 db 'Количество чисел, сумма цифр которых кратна 3: ', 0
msg4 db 'Пятое после минимального: ', 0

mmap_error_msg db 'Ошибка при создании отображения памяти', 10
mmap_error_len = $ - mmap_error_msg

fork_error_msg db 'Ошибка при создании процесса', 10
fork_error_len = $ - fork_error_msg

newline db 10
space db ' '

section '.bss' writeable

num_buffer rb 32
seed dd 0
array_ptr dq 0