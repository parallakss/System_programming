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
    mov rdx, 2
    syscall

    mov al, [input_buffer]
    mov [char], al
    
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, result_label
    mov rdx, result_label_len
    syscall

    movzx rax, al
    mov rdi, output_buffer
    call int_to_string
    
    mov byte [rdi], 10
    inc rdi
    
    mov rdx, rdi
    sub rdx, output_buffer
    
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, output_buffer
    syscall
    
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

int_to_string:
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
    ret

section '.data' writeable
    prompt_msg db 'Enter character: ', 0
    prompt_len = $ - prompt_msg
    result_label db 'ASCII code: ', 0
    result_label_len = $ - result_label

section '.bss' writeable
    char db ?
    input_buffer rb 2
    output_buffer rb 16