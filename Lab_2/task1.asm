section .data
    msg db 'eWTAqhRYsHMleIYxtfCbeQoDvnQaKdRkKzJboR', 0

section .text
    global _start

_start:
    ; Находим длину строки
    mov rsi, msg
    xor rcx, rcx
find_end:
    cmp byte [rsi + rcx], 0
    je found_end
    inc rcx
    jmp find_end

found_end:
    test rcx, rcx
    jz exit
    
    ; Вывод в обратном порядке
reverse_print:
    dec rcx
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg + rcx]
    mov rdx, 1
    push rcx
    syscall
    pop rcx
    test rcx, rcx
    jnz reverse_print

    ; Перевод строки
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

exit:
    mov rax, 60
    mov rdi, 0
    syscall

section .data
    newline db 10