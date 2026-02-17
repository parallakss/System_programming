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
START_X       = 0        ; Левый верхний угол
START_Y       = 0
COLS          = 80
ROWS          = 24
INIT_SPEED    = 1
MIN_SPEED     = 1        ; Минимальная задержка 1мс (очень быстро)
MAX_SPEED     = 200
SPEED_STEP    = 30        ; Шаг изменения скорости

DIR_DOWN      = 0
DIR_UP        = 1
DIR_RIGHT     = 2

KEY_BACKSLASH = 92      ; '\'
KEY_Q         = 113     ; 'q'
KEY_Q_UPPER   = 81      ; 'Q'

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
    mov  qword [color], 1          ; Начинаем с CYAN

    mov  qword [direction], DIR_DOWN
    mov  qword [top_row], 0
    mov  qword [bottom_row], ROWS-1
    mov  qword [current_col], 0
    mov  qword [running], 1        ; Флаг работы программы

    jmp  main_loop

; ------------------------------------------------------------
; Главный цикл
; ------------------------------------------------------------
main_loop:
    ; Проверяем флаг работы программы
    cmp  qword [running], 0
    je   exit_program

    ; Устанавливаем цвет
    mov  rdi, [color]
    call COLOR_PAIR
    mov  rdi, rax
    call attron

    ; Рисуем символ в текущей позиции
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
    
    ; Проверяем 'q' или 'Q' для выхода
    cmp  eax, KEY_Q
    je   .exit_command
    cmp  eax, KEY_Q_UPPER
    je   .exit_command
    
    ; Проверяем '\' для изменения скорости
    cmp  eax, KEY_BACKSLASH
    je   change_speed

    call move_snake
    jmp  main_loop

.exit_command:
    mov  qword [running], 0
    jmp  main_loop

; ------------------------------------------------------------
; Движение змейкой по колонкам
; ------------------------------------------------------------
move_snake:
    push rbp
    mov  rbp, rsp

    mov  rax, [direction]
    cmp  rax, DIR_DOWN
    je   .move_down
    cmp  rax, DIR_UP
    je   .move_up
    cmp  rax, DIR_RIGHT
    je   .move_right
    jmp  .done

.move_down:
    ; Движение вниз
    mov  rax, [pos_y]
    cmp  rax, [bottom_row]
    jge  .bottom_reached
    inc  qword [pos_y]
    jmp  .done
    
.bottom_reached:
    ; Достигли нижней границы - двигаемся вправо
    mov  qword [direction], DIR_RIGHT
    jmp  .done

.move_up:
    ; Движение вверх
    mov  rax, [pos_y]
    cmp  rax, [top_row]
    jle  .top_reached
    dec  qword [pos_y]
    jmp  .done
    
.top_reached:
    ; Достигли верхней границы - двигаемся вправо
    mov  qword [direction], DIR_RIGHT
    jmp  .done

.move_right:
    ; Движение вправо на 1 символ
    inc  qword [pos_x]
    inc  qword [current_col]
    
    ; Проверяем, не достигли ли правой границы экрана
    mov  rax, [pos_x]
    cmp  rax, COLS
    jge  .finished
    
    ; Определяем направление вертикального движения
    ; Если текущая колонка нечетная - двигаемся вверх
    ; Если четная - двигаемся вниз
    mov  rax, [current_col]
    and  rax, 1
    cmp  rax, 0
    je   .even_col
    
    ; Нечетная колонка - двигаемся вверх
    mov  qword [direction], DIR_UP
    jmp  .check_color_change
    
.even_col:
    ; Четная колонка - двигаемся вниз
    mov  qword [direction], DIR_DOWN

.check_color_change:
    ; Меняем цвет при переходе на новую колонку
    call switch_color
    jmp  .done

.finished:
    ; Достигли правой границы - завершаем программу
    mov  qword [running], 0

.done:
    pop  rbp
    ret

; ------------------------------------------------------------
; Переключение цвета (CYAN <-> YELLOW)
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
    push rbp
    mov  rbp, rsp
    
    ; Увеличиваем скорость (уменьшаем задержку)
    sub  qword [speed], SPEED_STEP
    
    ; Проверяем минимальную скорость
    cmp  qword [speed], MIN_SPEED
    jge  .check_max
    
    ; Достигли минимума - сбрасываем на максимум
    mov  qword [speed], MAX_SPEED
    jmp  .done
    
.check_max:
    cmp  qword [speed], MAX_SPEED
    jle  .done
    mov  qword [speed], MAX_SPEED
    
.done:
    pop  rbp
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

stdscr_ptr    dq ?
pos_x         dq ?
pos_y         dq ?
speed         dq ?
color         dq ?

; Границы движения
top_row       dq ?
bottom_row    dq ?
direction     dq ?
current_col   dq ?
running       dq ?