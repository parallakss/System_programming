format elf64
public _start

extrn printf
extrn cos

section '.data' writeable
    fmt_table_header db "     X        Точность    Кол-во членов", 0xa, 0
    fmt_table_row    db "  %6.3f      %.0e        %-8d", 0xa, 0
    
    precisions dq 1.0e-1, 1.0e-2, 1.0e-3, 1.0e-4, 1.0e-5, 1.0e-6, 1.0e-7, 1.0e-8
    prec_count = ($ - precisions) / 8
    
    x_values dq 0.628318530717959    ; π/5
             dq 1.25663706143592     ; 2π/5
             dq 1.88495559215388     ; 3π/5
             dq 2.51327412287183     ; 4π/5
             dq 3.14159265358979     ; π
    x_count = ($ - x_values) / 8
    
    pi      dq 3.141592653589793
    three   dq 3.0
    four    dq 4.0
    abs_mask_low dq 0x7FFFFFFFFFFFFFFF
    newline db 0xa, 0

section '.text' executable

;------------------------------------------------
; Точное значение (x^2 - π^2/3)/4
; Вход: xmm0 = x, выход: xmm0 = результат
;------------------------------------------------
compute_exact:
    push rbp
    mov rbp, rsp
    movsd xmm1, xmm0
    mulsd xmm1, xmm1               ; x^2
    movsd xmm2, [pi]
    mulsd xmm2, xmm2               ; π^2
    divsd xmm2, [three]            ; π^2/3
    subsd xmm1, xmm2               ; x^2 - π^2/3
    divsd xmm1, [four]             ; (x^2 - π^2/3)/4
    movsd xmm0, xmm1
    pop rbp
    ret

;------------------------------------------------
; Вычисление суммы ряда с заданной точностью
; Вход: xmm0 = x, xmm1 = точность
; Выход: eax = количество членов
; Использует callee-saved регистры xmm6-xmm9
; Локальные переменные через rbp:
;   [rbp-8]   - x
;   [rbp-16]  - точность
;   [rbp-24]  - сумма
;   [rbp-32]  - точное значение
;   [rbp-36]  - n (dword)
;   [rbp-40]  - terms (dword)
;   [rbp-48]..[rbp-72] - буфер для xmm6-xmm9
;------------------------------------------------
compute_series:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 72                    ; место под локальные переменные + выравнивание

    ; сохраняем входные параметры
    movsd [rbp-8], xmm0            ; x
    movsd [rbp-16], xmm1           ; точность

    ; вычисляем точное значение
    call compute_exact
    movsd [rbp-32], xmm0           ; exact

    ; инициализация
    xorps xmm8, xmm8               ; sum = 0
    movsd [rbp-24], xmm8
    mov dword [rbp-36], 1          ; n = 1
    mov dword [rbp-40], 0          ; terms = 0

    ; загружаем значения в callee-saved регистры для быстрого доступа
    movsd xmm6, [rbp-8]            ; x
    movsd xmm7, [rbp-16]           ; точность
    movsd xmm8, [rbp-24]           ; сумма
    movsd xmm9, [rbp-32]           ; точное значение

.series_loop:
    ; вычислить n*x
    cvtsi2sd xmm0, dword [rbp-36]  ; xmm0 = n
    mulsd xmm0, xmm6               ; xmm0 = n*x

    ; сохраняем xmm6-xmm9 в буфер (не в красную зону)
    movsd [rbp-48], xmm6
    movsd [rbp-56], xmm7
    movsd [rbp-64], xmm8
    movsd [rbp-72], xmm9

    ; вызываем cos (стек уже выровнен после sub rsp,72 + push)
    call cos

    ; восстанавливаем xmm6-xmm9
    movsd xmm6, [rbp-48]
    movsd xmm7, [rbp-56]
    movsd xmm8, [rbp-64]
    movsd xmm9, [rbp-72]

    ; результат cos в xmm0
    ; вычисляем n^2
    cvtsi2sd xmm1, dword [rbp-36]  ; xmm1 = n
    mulsd xmm1, xmm1               ; xmm1 = n^2

    ; член ряда: cos(n*x) / n^2
    divsd xmm0, xmm1

    ; знак: (-1)^n (нечётные n – отрицательные)
    test dword [rbp-36], 1
    jz .positive
    xorpd xmm1, xmm1
    subsd xmm1, xmm0
    movsd xmm0, xmm1
.positive:
    ; добавляем к сумме
    addsd xmm8, xmm0
    movsd [rbp-24], xmm8           ; обновляем в памяти

    ; увеличиваем счётчик членов
    inc dword [rbp-40]

    ; проверка сходимости |sum - exact| < precision
    movsd xmm0, xmm8
    subsd xmm0, xmm9
    ; модуль
    mov rax, [abs_mask_low]
    push rax
    movsd xmm1, [rsp]
    andpd xmm0, xmm1
    pop rax
    comisd xmm0, xmm7
    jb .converged

    ; защита от бесконечного цикла
    cmp dword [rbp-40], 10000
    jge .converged

    ; следующий n
    inc dword [rbp-36]
    jmp .series_loop

.converged:
    mov eax, [rbp-40]              ; количество членов

    add rsp, 72
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

;------------------------------------------------
; Точка входа
;------------------------------------------------
_start:
    ; печать заголовка таблицы
    mov rdi, fmt_table_header
    xor rax, rax
    call printf

    ; обход всех x
    mov rbx, x_values
    mov r13, x_count

.x_loop:
    push rbx
    push r13

    ; обход всех точностей
    mov r12, precisions
    mov r14, prec_count

.precision_loop:
    push rbx
    push r12
    push r14

    ; выравнивание стека перед вызовом compute_series
    sub rsp, 8
    movsd xmm0, [rbx]               ; x
    movsd xmm1, [r12]               ; точность
    call compute_series
    add rsp, 8

    mov r15, rax                     ; сохраняем количество членов

    ; выравнивание перед printf
    sub rsp, 8
    mov rdi, fmt_table_row
    movsd xmm0, [rbx]               ; x
    movsd xmm1, [r12]               ; точность
    mov rdx, r15                    ; количество членов
    mov rax, 2                       ; два числа с плавающей точкой
    call printf
    add rsp, 8

    pop r14
    pop r12
    pop rbx

    add r12, 8                       ; следующая точность
    dec r14
    jnz .precision_loop

    ; пустая строка между разными x
    mov rdi, newline
    xor rax, rax
    call printf

    pop r13
    pop rbx
    add rbx, 8                       ; следующее x
    dec r13
    jnz .x_loop

    ; завершение программы
    mov rax, 60
    xor rdi, rdi
    syscall