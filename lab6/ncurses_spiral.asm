format ELF64
public _start

; ------------------------------------------------------------
; Внешние функции из libncurses
; ------------------------------------------------------------
extrn initscr
extrn endwin
extrn curs_set
extrn clear
extrn refresh
extrn mvaddch
extrn attron
extrn attroff
extrn COLOR_PAIR
extrn init_pair
extrn start_color
extrn timeout
extrn getch
extrn napms
extrn noecho
extrn keypad
extrn stdscr

; ------------------------------------------------------------
; Константы ncurses
; ------------------------------------------------------------
COLOR_BLACK   = 0
COLOR_CYAN    = 6
COLOR_YELLOW  = 3

; ------------------------------------------------------------
; Параметры движения
; ------------------------------------------------------------
START_X       = 40
START_Y       = 12
COLS          = 80
ROWS          = 24
INIT_SPEED    = 100
MIN_SPEED     = 30
MAX_SPEED     = 300
SPEED_STEP    = 20

DIR_RIGHT = 0
DIR_DOWN  = 1
DIR_LEFT  = 2
DIR_UP    = 3

KEY_BACKSLASH = 92      ; '\'
KEY_Q         = 113     ; 'q'

; ------------------------------------------------------------
; Системные вызовы
; ------------------------------------------------------------
SYS_WRITE = 1
SYS_EXIT  = 60
STDERR    = 2

; ------------------------------------------------------------
; Секция кода
; ------------------------------------------------------------
section '.text' executable

_start:
    push rbp
    mov  rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; Инициализация ncurses
    call initscr
    test rax, rax
    jz   error_init

    ; Получаем stdscr
    mov  rax, [stdscr]
    mov  [stdscr_ptr], rax

    ; Включаем цвет
    call start_color

    ; Инициализация цветовых пар
    mov  rdi, 1
    mov  rsi, COLOR_CYAN
    mov  rdx, COLOR_BLACK
    call init_pair

    mov  rdi, 2
    mov  rsi, COLOR_YELLOW
    mov  rdx, COLOR_BLACK
    call init_pair

    ; Скрываем курсор
    mov  rdi, 0
    call curs_set

    ; Отключаем эхо
    call noecho

    ; Включаем keypad
    mov  rdi, [stdscr_ptr]
    mov  rsi, 1
    call keypad

    ; Неблокирующий ввод
    mov  rdi, 0
    call timeout

    ; Очищаем экран
    call clear

    ; Инициализация переменных
    mov  qword [pos_x], START_X
    mov  qword [pos_y], START_Y
    mov  qword [speed], INIT_SPEED
    mov  qword [color], 1

    mov  qword [step_size], 1
    mov  qword [step_cnt], 0
    mov  qword [direction], DIR_RIGHT
    mov  qword [total_steps], 0

    jmp  main_loop

; ------------------------------------------------------------
; Главный цикл
; ------------------------------------------------------------
main_loop:
    ; Устанавливаем цвет
    mov  rdi, [color]
    call COLOR_PAIR
    mov  rdi, rax
    call attron

    ; Рисуем символ
    mov  rdi, [pos_y]
    mov  rsi, [pos_x]
    mov  rdx, '#'
    call mvaddch

    ; Сбрасываем цвет
    mov  rdi, [color]
    call COLOR_PAIR
    mov  rdi, rax
    call attroff

    ; Обновляем экран
    call refresh

    ; Задержка
    mov  rdi, [speed]
    call napms

    ; Проверка клавиш
    call getch
    
    ; Проверяем 'q' для выхода
    cmp  eax, KEY_Q
    je   exit_program
    
    ; Проверяем '\' для изменения скорости
    cmp  eax, KEY_BACKSLASH
    je   change_speed

    call move_spiral
    jmp  main_loop

; ------------------------------------------------------------
; Движение по спирали
; ------------------------------------------------------------
move_spiral:
    push rbp
    mov  rbp, rsp

    mov  rax, [direction]
    cmp  rax, DIR_RIGHT
    je   .right
    cmp  rax, DIR_DOWN
    je   .down
    cmp  rax, DIR_LEFT
    je   .left
    dec  qword [pos_y]
    jmp  .check_bounds
.right:
    inc  qword [pos_x]
    jmp  .check_bounds
.down:
    inc  qword [pos_y]
    jmp  .check_bounds
.left:
    dec  qword [pos_x]

.check_bounds:
    cmp  qword [pos_x], 0
    jl   .wrap
    cmp  qword [pos_x], COLS-1
    jg   .wrap
    cmp  qword [pos_y], 0
    jl   .wrap
    cmp  qword [pos_y], ROWS-1
    jg   .wrap
    jmp  .check_step

.wrap:
    call switch_color
    mov  qword [pos_x], START_X
    mov  qword [pos_y], START_Y
    mov  qword [step_size], 1
    mov  qword [step_cnt], 0
    mov  qword [direction], DIR_RIGHT
    pop  rbp
    ret

.check_step:
    inc  qword [step_cnt]
    mov  rax, [step_cnt]
    cmp  rax, [step_size]
    jl   .done

    mov  qword [step_cnt], 0
    mov  rax, [direction]
    inc  rax
    and  rax, 3
    mov  [direction], rax

    inc  qword [total_steps]
    mov  rax, [total_steps]
    and  rax, 1
    jnz  .done
    inc  qword [step_size]

.done:
    pop  rbp
    ret

; ------------------------------------------------------------
; Переключение цвета
; ------------------------------------------------------------
switch_color:
    cmp  qword [color], 1
    je   .set_yellow
    mov  qword [color], 1
    ret
.set_yellow:
    mov  qword [color], 2
    ret

; ------------------------------------------------------------
; Изменение скорости
; ------------------------------------------------------------
change_speed:
    sub  qword [speed], SPEED_STEP
    cmp  qword [speed], MIN_SPEED
    jge  .check_max
    mov  qword [speed], MAX_SPEED
.check_max:
    cmp  qword [speed], MAX_SPEED
    jle  .done
    mov  qword [speed], MAX_SPEED
.done:
    jmp  main_loop

; ------------------------------------------------------------
; Обработчик ошибок
; ------------------------------------------------------------
error_init:
    mov  rax, SYS_WRITE
    mov  rdi, STDERR
    mov  rsi, err_msg
    mov  rdx, err_msg_len
    syscall
    jmp  exit_program

; ------------------------------------------------------------
; Выход из программы
; ------------------------------------------------------------
exit_program:
    call endwin
    mov  rax, SYS_EXIT
    xor  rdi, rdi
    syscall

; ------------------------------------------------------------
; Секция данных
; ------------------------------------------------------------
section '.data' writeable

err_msg      db 'Error: cannot initialize ncurses', 10
err_msg_len  = $ - err_msg

; ------------------------------------------------------------
; Секция BSS
; ------------------------------------------------------------
section '.bss' writeable

stdscr_ptr  dq ?
pos_x       dq ?
pos_y       dq ?
speed       dq ?
color       dq ?
step_size   dq ?
step_cnt    dq ?
direction   dq ?
total_steps dq ?