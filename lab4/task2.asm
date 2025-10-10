format ELF64

; Системные вызовы
SYS_READ = 0
SYS_WRITE = 1
SYS_EXIT = 60

section '.text' executable
public _start

_start:
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, prompt_msg
    mov rdx, prompt_len
    syscall

    mov rax, SYS_READ
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 32
    syscall

    mov rdi, input_buffer
    xor rax, rax
    xor rcx, rcx
convert_loop:
    mov cl, [rdi]
    cmp cl, 10            
    je done_convert
    cmp cl, 0              
    je done_convert
    sub cl, '0'
    imul rax, 10
    add rax, rcx
    inc rdi
    jmp convert_loop
done_convert:

    mov [n], rax

    call compute_sum

    call print_result

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

compute_sum:

    xor r12, r12
    
    mov r8, 1
    mov r9, 1             

sum_loop:
    mov rax, r8
    imul rax, rax          

    imul rax, r9           

    add r12, rax

    neg r9
    
    inc r8
    cmp r8, [n]
    jle sum_loop
    
    mov [result], r12
    ret

print_result:
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, result_label
    mov rdx, result_label_len
    syscall

    mov rax, [result]
    mov rdi, number_buffer
    call int_to_string
    
    mov byte [rdi], 10
    inc rdi
    
    mov rdx, rdi
    sub rdx, number_buffer

    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, number_buffer
    syscall
    
    ret

int_to_string:
    test rax, rax
    jnz .convert
    
    mov byte [rdi], '0'
    inc rdi
    ret
    
.convert:
    
    cmp rax, 0
    jge .positive
    
    mov byte [rdi], '-'
    inc rdi
    neg rax
    
.positive:
    push rbx
    mov rbx, 10
    xor rcx, rcx
    
.push_loop:
    xor rdx, rdx
    div rbx
    push rdx
    inc rcx
    test rax, rax
    jnz .push_loop
    
.pop_loop:
    pop rax
    add al, '0'
    mov [rdi], al
    inc rdi
    loop .pop_loop
    
    pop rbx
    ret

section '.data' writeable
    prompt_msg db 'Enter n: ', 0
    prompt_len = $ - prompt_msg
    result_label db 'Result: ', 0
    result_label_len = $ - result_label

section '.bss' writeable
    n dq ?
    result dq ?
    input_buffer rb 32
    number_buffer rb 32