format ELF64 executable

SYS_OPEN = 2
SYS_CLOSE = 3
SYS_GETDENTS64 = 217
SYS_FSTAT = 5
SYS_FTRUNCATE = 77
SYS_GETRANDOM = 318
SYS_EXIT = 60
SYS_WRITE = 1

O_RDONLY = 0
O_RDWR = 2
O_DIRECTORY = 0x10000

d_reclen = 16
d_type = 18
d_name = 19

st_size = 48

segment readable executable
entry start

start:
    pop rcx                     
    cmp rcx, 2
    jl error_usage

    pop rdi                     
    pop rdi                    
    
    mov [dir_path], rdi

    mov rax, SYS_OPEN
    mov rsi, O_RDONLY + O_DIRECTORY
    mov rdx, 0
    syscall
    
    cmp rax, 0
    jl error_open
    mov [dir_fd], rax

process_directory:
    mov rax, SYS_GETDENTS64
    mov rdi, [dir_fd]
    mov rsi, dir_entries
    mov rdx, dir_entries_size
    syscall
    
    cmp rax, 0
    jle close_directory         
    
    mov r15, rax                
    mov r14, dir_entries        

process_entry:
    cmp r15, 0
    jle process_directory

    movzx r13, byte [r14 + d_type]
    
    cmp r13, 4                  
    je next_entry
    
    cmp r13, 8
    jne next_entry

    lea r12, [r14 + d_name]
    
    mov al, [r12]
    cmp al, '.'
    jne check_random
    mov al, [r12 + 1]
    cmp al, 0
    je next_entry
    cmp al, '.'
    jne check_random
    mov al, [r12 + 2]
    cmp al, 0
    je next_entry

check_random:
    mov rax, SYS_GETRANDOM
    mov rdi, random_buffer
    mov rsi, 4
    mov rdx, 0
    syscall
    
    mov eax, [random_buffer]
    and eax, 1
    cmp eax, 0
    jne next_entry            

    mov rdi, full_path
    mov rsi, [dir_path]
    call strcpy
    
    mov byte [rdi], '/'
    inc rdi
    
    mov rsi, r12
    call strcpy

    mov rax, SYS_OPEN
    mov rdi, full_path
    mov rsi, O_RDWR
    mov rdx, 0
    syscall
    
    cmp rax, 0
    jl next_entry
    mov [file_fd], rax

    mov rax, SYS_FSTAT
    mov rdi, [file_fd]
    mov rsi, stat_buf
    syscall
    
    cmp rax, 0
    jne close_file

    mov rsi, stat_buf + st_size
    mov rax, [rsi]
    mov [original_size], rax
    
    mov rbx, 63
    xor rdx, rdx
    mul rbx
    mov [new_size], rax
    
    mov rax, SYS_FTRUNCATE
    mov rdi, [file_fd]
    mov rsi, [new_size]
    syscall

    mov rsi, processing_msg
    mov rdx, processing_len
    call print_string
    
    mov rsi, r12                
    call print_string_zero
    
    mov rsi, size_msg
    mov rdx, size_msg_len
    call print_string
    
    mov rax, [original_size]
    call print_number
    
    mov rsi, to_msg
    mov rdx, to_msg_len
    call print_string
    
    mov rax, [new_size]
    call print_number
    
    mov rsi, newline
    mov rdx, 1
    call print_string

close_file:
    mov rax, SYS_CLOSE
    mov rdi, [file_fd]
    syscall

next_entry:
    movzx rbx, word [r14 + d_reclen]
    add r14, rbx
    sub r15, rbx
    jmp process_entry

close_directory:
    mov rax, SYS_CLOSE
    mov rdi, [dir_fd]
    syscall
    
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

error_usage:
    mov rsi, usage_msg
    mov rdx, usage_len
    call print_string
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

error_open:
    mov rsi, open_error_msg
    mov rdx, open_error_len
    call print_string
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

strcpy:
    mov al, [rsi]
    mov [rdi], al
    inc rdi
    inc rsi
    test al, al
    jnz strcpy
    dec rdi
    ret

print_string:
    mov rax, SYS_WRITE
    mov rdi, 1
    syscall
    ret

print_string_zero:
    push rsi
    mov rdx, 0
.find_end:
    cmp byte [rsi + rdx], 0
    je .found_end
    inc rdx
    jmp .find_end
.found_end:
    mov rax, SYS_WRITE
    mov rdi, 1
    pop rsi
    syscall
    ret

print_number:
    push rbx
    mov rbx, 10
    mov rdi, num_buffer + 63
    mov byte [rdi], 0
.print_loop:
    dec rdi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    test rax, rax
    jnz .print_loop
    
    mov rsi, rdi
    mov rdx, num_buffer + 64
    sub rdx, rdi
    mov rax, SYS_WRITE
    mov rdi, 1
    syscall
    pop rbx
    ret

segment readable writeable
    dir_fd dq 0
    file_fd dq 0
    dir_path dq 0
    original_size dq 0
    new_size dq 0
    
    dir_entries_size = 8192
    dir_entries rb dir_entries_size
    
    random_buffer rd 1
    stat_buf rb 144             
    
    full_path_size = 4096
    full_path rb full_path_size
    
    num_buffer rb 64
    
    usage_msg db "Usage: ./file_program <directory_path>", 10
    usage_len = $ - usage_msg
    
    open_error_msg db "Error: Cannot open directory", 10
    open_error_len = $ - open_error_msg
    
    processing_msg db "Processing file: "
    processing_len = $ - processing_msg
    
    size_msg db " - size changed from "
    size_msg_len = $ - size_msg
    
    to_msg db " to "
    to_msg_len = $ - to_msg
    
    newline db 10