format ELF64
public _start
extrn printf
extrn scanf
extrn exit

section '.data' writeable
    ; Строки форматов
    input_fmt       db "%lf", 0
    header_fmt      db 10, "%-4s | %-9s | %-5s | %-11s | %-9s", 10, 0
    line_fmt        db "----|-----------|-------|-------------|---------", 10, 0
    row_fmt         db "%-4.2f | %-9.6f | %-5d | %-11.8f | %-9.8f", 10, 0

    ; Заголовки столбцов
    s_x             db "x", 0
    s_eps           db "epsilon", 0
    s_n             db "terms", 0
    s_sum           db "series sum", 0
    s_formula       db "formula", 0

    msg_x           db "Enter x (PI/5 <= x <= PI): ", 0
    msg_eps         db "Enter epsilon: ", 0

    ; Переменные
    x               rq 1
    epsilon         rq 1
    series_res      rq 1
    formula_res     rq 1
    term_count      rq 1
    n               rq 1
    term            rq 1

    ; Константы
    val_3           dq 3.0
    val_4           dq 4.0
    one             dq 1.0

section '.text' executable

_start:
    call main
    xor rdi, rdi
    call exit

main:
    push rbp
    mov rbp, rsp
    
    ; Ввод x
    mov rdi, msg_x
    xor rax, rax
    call printf
    mov rdi, input_fmt
    mov rsi, x
    xor rax, rax
    call scanf

    ; Ввод epsilon
    mov rdi, msg_eps
    xor rax, rax
    call printf
    mov rdi, input_fmt
    mov rsi, epsilon
    xor rax, rax
    call scanf

    ; Вычисление формулы: f(x) = (x^2 - pi^2/3)/4
    finit
    fldpi               ; st0 = pi
    fmul st0, st0       ; st0 = pi^2
    fdiv qword [val_3]  ; st0 = pi^2/3
    fld qword [x]       ; st0 = x, st1 = pi^2/3
    fmul st0, st0       ; st0 = x^2, st1 = pi^2/3
    fsubp st1, st0      ; st0 = x^2 - pi^2/3
    fdiv qword [val_4]  ; st0 = (x^2 - pi^2/3)/4
    fstp qword [formula_res]

    ; Вычисление ряда: sum = (-1)^n * cos(n*x)/n^2, n от 1 до ∞
    call calc_series

    ; Вывод таблицы
    mov rdi, header_fmt
    mov rsi, s_x
    mov rdx, s_eps
    mov rcx, s_n
    mov r8, s_sum
    mov r9, s_formula
    xor rax, rax
    call printf

    mov rdi, line_fmt
    xor rax, rax
    call printf

    mov rdi, row_fmt
    movq xmm0, [x]
    movq xmm1, [epsilon]
    mov rsi, [term_count]
    movq xmm2, [series_res]
    movq xmm3, [formula_res]
    mov rax, 4
    call printf
    
    pop rbp
    ret

calc_series:
    push rbp
    mov rbp, rsp
    
    ; Инициализация
    mov qword [term_count], 0
    mov qword [n], 1
    
    finit
    fldz                ; st0 = сумма = 0
    
.loop:
    ; Вычисляем очередной член ряда
    
    ; Загружаем n
    fild qword [n]      ; st0 = n, st1 = сумма
    
    ; Вычисляем n*x
    fld qword [x]       ; st0 = x, st1 = n, st2 = сумма
    fmulp st1, st0      ; st0 = n*x, st1 = сумма
    
    ; Вычисляем cos(n*x)
    fcos                ; st0 = cos(n*x), st1 = сумма
    
    ; Делим на n^2
    fild qword [n]      ; st0 = n, st1 = cos, st2 = сумма
    fmul st0, st0       ; st0 = n^2, st1 = cos, st2 = сумма
    fdivp st1, st0      ; st0 = cos/n^2, st1 = сумма
    
    ; Умножаем на (-1)^n
    mov rax, [n]
    test rax, 1
    jz .positive
    fchs                ; если n нечетное, меняем знак
    
.positive:
    ; Сохраняем текущий член для проверки точности
    fst qword [term]
    
    ; Добавляем к сумме
    faddp st1, st0      ; st0 = новая сумма
    
    ; Проверяем точность
    fld qword [term]    ; st0 = term, st1 = сумма
    fabs                ; st0 = |term|, st1 = сумма
    fld qword [epsilon] ; st0 = epsilon, st1 = |term|, st2 = сумма
    fcomip st1          ; сравниваем epsilon и |term|
    fstp st0            ; убираем |term|
    
    jae .done           ; если |term| <= epsilon, заканчиваем
    
    ; Подготовка к следующей итерации
    inc qword [n]
    inc qword [term_count]
    jmp .loop
    
.done:
    inc qword [term_count]  ; учитываем последний член
    fstp qword [series_res] ; сохраняем результат
    
    pop rbp
    ret