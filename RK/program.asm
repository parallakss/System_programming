format ELF64 executable

segment readable executable
entry start

start:
    pop rcx
    cmp rcx, 4
    jne error

    pop rsi

    pop rsi
    call atoi
    mov [a], rax

    pop rsi
    call atoi
    mov [b], rax

    pop rsi
    call atoi
    mov [c], rax

    mov r12, 1                  
x_loop:
    cmp r12, [b]
    jg exit

    mov r13, 1                  
y_loop:
    cmp r13, [c]
    jg next_x

    mov rax, r12
    imul rax, rax              
    imul rax, [a]               
    add rax, 1                  

    mov rdx, r13
    imul rdx, rdx            

    cmp rax, rdx
    jne next_y

    mov rdi, r12                
    mov rsi, r13            
    call print_solution

next_y:
    inc r13
    jmp y_loop

next_x:
    inc r12
    jmp x_loop

error:
    mov rsi, usage_msg
    mov rdx, usage_len
    mov rax, 1
    mov rdi, 1
    syscall
    mov rax, 60
    mov rdi, 1
    syscall

exit:
    mov rax, 60
    xor rdi, rdi
    syscall

atoi:
    xor rax, rax
    xor rcx, rcx
atoi_loop:
    mov cl, [rsi]
    test cl, cl
    jz atoi_done
    cmp cl, '0'
    jb atoi_done
    cmp cl, '9'
    ja atoi_done
    sub cl, '0'
    imul rax, 10
    add rax, rcx
    inc rsi
    jmp atoi_loop
atoi_done:
    ret

print_solution:
    push rdi
    push rsi
    
    mov rsi, x_msg
    mov rdx, x_len
    mov rax, 1
    mov rdi, 1
    syscall

    pop rsi
    pop rdi
    push rsi
    mov rax, rdi
    call print_number

    mov rsi, y_msg
    mov rdx, y_len
    mov rax, 1
    mov rdi, 1
    syscall

    pop rax
    call print_number

    mov rsi, newline
    mov rdx, newline_len
    mov rax, 1
    mov rdi, 1
    syscall
    
    ret

print_number:
    push rbx
    mov rbx, 10
    mov rdi, num_buffer + 63
    mov byte [rdi], 0
print_loop:
    dec rdi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    test rax, rax
    jnz print_loop
    
    mov rsi, rdi
    mov rdx, num_buffer + 64
    sub rdx, rdi
    mov rax, 1
    mov rdi, 1
    syscall
    pop rbx
    ret

segment readable writeable
    a dq 0
    b dq 0
    c dq 0

    num_buffer rb 64

    usage_msg db "Usage: ./program a b c", 10
    usage_len = $ - usage_msg

    x_msg db "x="
    x_len = $ - x_msg

    y_msg db ", y="
    y_len = $ - y_msg

    newline db 10
    newline_len = $ - newline