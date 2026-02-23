format ELF64

; Системные вызовы
SYS_WRITE = 1
SYS_EXIT = 60
SYS_BRK = 12
STDOUT = 1

section '.text' executable

; Инициализация очереди
; rdi - начальная емкость
; возвращает rax - указатель на очередь или 0 при ошибке
public queue_init
queue_init:
    push rdi
    ; Выделяем память под структуру (40 байтов)
    mov rax, SYS_BRK
    xor rdi, rdi
    syscall
    mov rsi, rax    ; сохраняем текущий brk
    
    add rax, 40     ; место под структуру (5 qword = 40 байтов)
    mov rdi, rax
    mov rax, SYS_BRK
    syscall
    cmp rax, rsi
    jle .error
    
    ; Инициализируем структуру
    mov qword [rsi + 0], 0   ; buffer_ptr
    mov qword [rsi + 8], 0   ; capacity
    mov qword [rsi + 16], 0  ; size
    mov qword [rsi + 24], 0  ; front
    mov qword [rsi + 32], 0  ; rear
    
    ; Создаем начальный буфер если емкость > 0
    pop rdi
    test rdi, rdi
    jz .no_buffer
    
    push rsi
    push rdi
    mov r12, rsi    ; сохраняем указатель на структуру
    mov r13, rdi    ; сохраняем емкость
    
    ; Выделяем память под буфер
    mov rax, SYS_BRK
    xor rdi, rdi
    syscall
    mov r14, rax    ; сохраняем начало буфера
    
    shl r13, 3      ; capacity * 8 (размер в байтах)
    add rax, r13
    mov rdi, rax
    mov rax, SYS_BRK
    syscall
    cmp rax, r14
    jle .buffer_error
    
    ; Инициализируем структуру с буфером
    mov [r12 + 0], r14     ; buffer_ptr
    mov [r12 + 8], r13     ; capacity (в байтах)
    shr r13, 3
    mov [r12 + 8], r13     ; capacity (в элементах)
    
    pop rdi
    pop rsi
    mov rax, rsi
    ret
    
.buffer_error:
    pop rdi
    pop rsi
    ; Освобождаем структуру при ошибке
    mov rdi, rsi
    mov rax, SYS_BRK
    syscall
    xor rax, rax
    ret
    
.no_buffer:
    mov rax, rsi
    ret
    
.error:
    pop rdi
    xor rax, rax
    ret

; Вспомогательная функция для изменения размера буфера
; rdi - указатель на очередь, rsi - новая емкость
resize_buffer:
    push r12
    push r13
    push r14
    push r15
    push rbx
    
    mov r12, rdi    ; queue
    mov r13, rsi    ; new_capacity
    
    ; Сохраняем текущее состояние
    mov r14, [r12 + 16] ; size
    mov r15, [r12 + 24] ; front
    mov rbx, [r12 + 0]  ; старый буфер
    mov r10, [r12 + 8]  ; старая емкость
    
    ; Выделяем память под новый буфер
    mov rax, SYS_BRK
    xor rdi, rdi
    syscall
    mov r8, rax     ; новый буфер
    
    mov rdi, rax
    mov rax, r13
    shl rax, 3      ; new_capacity * 8
    add rdi, rax
    mov rax, SYS_BRK
    syscall
    cmp rax, r8
    jle .resize_error
    
    ; Копируем элементы из старого буфера
    test r14, r14
    jz .copy_done
    
    mov r9, rbx      ; старый буфер
    xor r11, r11     ; индекс в новом буфере
    mov rcx, r14     ; счетчик элементов
    mov rdx, r15     ; текущий индекс в старом буфере (front)
    
.copy_loop:
    ; Получаем элемент из старого буфера
    mov rax, [r9 + rdx*8]
    mov [r8 + r11*8], rax
    
    ; Обновляем индексы
    inc rdx
    cmp rdx, r10
    jl .no_wrap_old
    xor rdx, rdx
.no_wrap_old:
    inc r11
    loop .copy_loop
    
.copy_done:
    ; Обновляем структуру очереди
    mov [r12 + 0], r8      ; buffer_ptr
    mov [r12 + 8], r13     ; capacity
    mov qword [r12 + 24], 0 ; front
    mov [r12 + 32], r11    ; rear (равно size)
    ; size остается тем же
    
    mov rax, 1
    jmp .done
    
.resize_error:
    xor rax, rax
    
.done:
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

; Добавление в конец очереди
; rdi - указатель на очередь, rsi - значение
public queue_push_back
queue_push_back:
    push r12
    push r13
    mov r12, rdi    ; указатель на очередь
    mov r13, rsi    ; значение
    
    ; Проверяем, нужно ли расширить буфер
    mov rcx, [r12 + 16] ; size
    cmp rcx, [r12 + 8]  ; capacity
    jl .no_resize
    
    ; Увеличиваем емкость
    mov rdi, [r12 + 8]
    test rdi, rdi
    jnz .not_first
    mov rdi, 4      ; начальная емкость
    jmp .do_resize
.not_first:
    shl rdi, 1      ; удваиваем
.do_resize:
    mov rsi, rdi
    mov rdi, r12
    call resize_buffer
    test rax, rax
    jz .error
    
.no_resize:
    ; Добавляем элемент в конец
    mov rdi, [r12 + 0]   ; buffer_ptr
    mov rcx, [r12 + 32]  ; rear index
    mov [rdi + rcx*8], r13
    
    ; Обновляем rear и size
    inc qword [r12 + 32] ; rear++
    mov rcx, [r12 + 32]
    cmp rcx, [r12 + 8]   ; capacity
    jl .no_wrap
    mov qword [r12 + 32], 0
.no_wrap:
    inc qword [r12 + 16] ; size++
    
    mov rax, 1
    pop r13
    pop r12
    ret
.error:
    xor rax, rax
    pop r13
    pop r12
    ret

; Удаление из начала очереди - ИСПРАВЛЕНО
; rdi - указатель на очередь
; возвращает rax - значение или 0 если очередь пуста
public queue_pop_front
queue_pop_front:
    mov rcx, [rdi + 16]      ; size
    test rcx, rcx
    jz .empty
    
    push rbx
    mov rbx, rdi             ; сохраняем указатель на очередь
    
    mov rsi, [rdi + 0]       ; buffer_ptr
    mov rdx, [rdi + 24]      ; front
    mov rax, [rsi + rdx*8]   ; значение
    
    ; Увеличиваем front (с учётом кольцевого буфера)
    inc rdx
    cmp rdx, [rdi + 8]       ; capacity
    jl .no_wrap
    xor rdx, rdx
.no_wrap:
    mov [rdi + 24], rdx
    
    ; Уменьшаем size - КЛЮЧЕВОЕ ИЗМЕНЕНИЕ!
    dec qword [rdi + 16]
    
    pop rbx
    ret
    
.empty:
    xor rax, rax
    ret

; Заполнение очереди случайными числами
; rdi - указатель на очередь, rsi - количество элементов
public queue_fill_random
queue_fill_random:
    push r12
    push r13
    push r14
    mov r12, rdi    ; queue
    mov r13, rsi    ; count
    
    ; Используем счетчик времени как seed
    rdtsc
    mov r14, rax
    
.fill_loop:
    test r13, r13
    jz .done
    
    ; Простой генератор случайных чисел
    mov rax, r14
    mov rcx, 1103515245
    mul rcx
    add rax, 12345
    mov r14, rax
    shr rax, 16
    and rax, 0x7FFF
    inc rax         ; от 1 до 32768
    
    mov rdi, r12
    mov rsi, rax
    call queue_push_back
    
    dec r13
    jmp .fill_loop
    
.done:
    pop r14
    pop r13
    pop r12
    ret

; Удаление всех четных чисел - ИСПРАВЛЕНО
; rdi - указатель на очередь
public queue_remove_even
queue_remove_even:
    push r12
    push r13
    mov r12, rdi
    
    mov r13, [r12 + 16]       ; сохраняем исходный размер
    mov rcx, r13              ; счетчик для цикла
    
.process_loop:
    test rcx, rcx
    jz .done
    
    mov rdi, r12
    call queue_pop_front      ; извлекаем элемент из начала
    test rax, rax
    jz .done
    
    test rax, 1               ; проверяем на нечетность
    jnz .odd                  ; если нечетное - добавляем обратно
    
    ; Четное - просто пропускаем (не добавляем)
    jmp .next
    
.odd:
    mov rdi, r12
    mov rsi, rax
    call queue_push_back      ; нечетное добавляем в конец
    
.next:
    dec rcx
    jmp .process_loop
    
.done:
    pop r13
    pop r12
    ret

; Подсчет количества четных чисел - ИСПРАВЛЕНО (НЕ ИЗМЕНЯЕТ ОЧЕРЕДЬ)
; rdi - указатель на очередь
; возвращает rax - количество
public queue_count_even
queue_count_even:
    push r12
    push r13
    push r14
    push r15
    push rbx
    
    mov r12, rdi              ; сохраняем указатель на очередь
    xor r13, r13              ; счетчик = 0
    
    mov r14, [r12 + 16]       ; size
    test r14, r14
    jz .done
    
    mov rbx, [r12 + 0]        ; buffer_ptr
    mov r15, [r12 + 24]       ; front
    mov rcx, r14              ; счетчик цикла = size
    mov rdx, r15              ; текущий индекс = front (локальная копия!)
    
.count_loop:
    mov rax, [rbx + rdx*8]    ; получаем элемент
    test rax, 1               ; проверяем четность
    jnz .not_even
    inc r13                   ; четное - увеличиваем счетчик
.not_even:
    
    inc rdx                    ; следующий индекс (локальная переменная!)
    cmp rdx, [r12 + 8]         ; сравниваем с capacity
    jl .no_wrap
    xor rdx, rdx               ; заворачиваем в начало
.no_wrap:
    
    loop .count_loop           ; продолжаем цикл
    
.done:
    mov rax, r13
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

; Подсчет чисел, оканчивающихся на 1 - ИСПРАВЛЕНО (НЕ ИЗМЕНЯЕТ ОЧЕРЕДЬ)
; rdi - указатель на очередь
; возвращает rax - количество
public queue_count_ends_with_1
queue_count_ends_with_1:
    push r12
    push r13
    push r14
    push r15
    push rbx
    
    mov r12, rdi              ; сохраняем указатель на очередь
    xor r13, r13              ; счетчик = 0
    
    mov r14, [r12 + 16]       ; size
    test r14, r14
    jz .done
    
    mov rbx, [r12 + 0]        ; buffer_ptr
    mov r15, [r12 + 24]       ; front
    mov rcx, r14              ; счетчик цикла = size
    mov rdx, r15              ; текущий индекс = front (локальная копия!)
    
.count_loop:
    mov rax, [rbx + rdx*8]    ; получаем элемент
    mov r8, rax
    and r8, 0xF               ; берем последнюю цифру (в 16-ричной системе)
    cmp r8, 1                 ; сравниваем с 1
    jne .not_end
    inc r13                   ; оканчивается на 1 - увеличиваем счетчик
.not_end:
    
    inc rdx                    ; следующий индекс (локальная переменная!)
    cmp rdx, [r12 + 8]         ; сравниваем с capacity
    jl .no_wrap
    xor rdx, rdx               ; заворачиваем в начало
.no_wrap:
    
    loop .count_loop           ; продолжаем цикл
    
.done:
    mov rax, r13
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

; Получение размера очереди
; rdi - указатель на очередь
; возвращает rax - размер
public queue_size
queue_size:
    mov rax, [rdi + 16]
    ret

; Проверка пустоты очереди
; rdi - указатель на очередь
; возвращает rax - 1 если пуста, 0 если нет
public queue_is_empty
queue_is_empty:
    mov rax, [rdi + 16]
    test rax, rax
    setz al
    movzx rax, al
    ret

; Уничтожение очереди
; rdi - указатель на очередь
public queue_destroy
queue_destroy:
    push rdi
    ; Освобождаем буфер если он есть
    mov rsi, [rdi + 0]   ; buffer_ptr
    test rsi, rsi
    jz .no_buffer
    
    mov rax, SYS_BRK
    mov rdi, rsi
    syscall
    
.no_buffer:
    pop rdi

    mov rax, SYS_BRK
    syscall
    ret