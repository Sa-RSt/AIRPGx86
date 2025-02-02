%ifdef TESTING
    %define DEBUG 1
%endif
%include "stdlib_macros.nasm"

section .data


openai_api_key:
incbin "../.openai-api-key"
db 0

openai_python_script: 
incbin "openai.py"
db 0

openai_str_env_path: db "/usr/bin/env", 0
openai_str_python3: db "python3", 0
openai_str_dashc: db "-c", 0
openai_subprocess_argv: dq openai_str_env_path, openai_str_env_path, openai_str_python3, openai_str_dashc, openai_python_script, 0
openai_zero_qword: dq 0

section .bss

openai_subprocess_pipe_outgoing: resd 2
openai_subprocess_pipe_incoming: resd 2

section .text

openai_init_subprocess:
    prolog rax
    syscall_header
    mov rax, 0x16  ; sys_pipe
    mov rdi, openai_subprocess_pipe_outgoing
    syscall

    mov rax, 0x16  ; sys_pipe
    mov rdi, openai_subprocess_pipe_incoming
    syscall

    mov rax, 0x39  ; sys_fork
    syscall
    if e, rax, -1
        print_literal "FATAL: failed to spawn OpenAI subprocess.", 0x0A
        mov rax, 0x3C  ; sys_exit
        mov rdi, 1
        syscall
    elifzero rax
        mov rax, 0x21  ; sys_dup2
        xor rdi, rdi
        mov edi, [openai_subprocess_pipe_outgoing]
        xor rsi, rsi  ; redirecionar stdin para o pipe
        syscall

        mov rax, 0x21  ; sys_dup2
        xor rdi, rdi
        mov edi, [openai_subprocess_pipe_incoming+4]
        mov rsi, 1  ; redirecionar stdout para o pipe
        syscall

        mov rax, 0x3B  ; sys_execve
        mov rdi, openai_str_env_path
        mov rsi, openai_subprocess_argv
        mov rdx, openai_zero_qword
        syscall
    else
        mov rsi, openai_api_key
        call openai_write_string
        call openai_read_qword
        mov rsi, 0x5555555555555555
        if ne, rax, rsi
            print_registers rax
            print_literal "WARN: OpenAI subprocess didn't respond with correct magic number.", 0x0A
        endif
    endif
    syscall_footer
    epilog


openai_write_string:  ; rsi = string terminada em \0
    prolog rdi, rsi, rax
        xor rdi, rdi
        mov edi, [openai_subprocess_pipe_outgoing+4]
        call fprint

        syscall_header
        mov rax, 0x01  ; sys_write
        xor rdi, rdi
        mov edi, [openai_subprocess_pipe_outgoing+4]
        mov rsi, openai_zero_qword  ; enviar um byte nulo
        mov rdx, 1
        syscall
        syscall_footer
    epilog


openai_read_qword:  ; rax = (retorno) qword lida
    prolog
        syscall_header
        sub rsp, 8
        xor rax, rax  ; sys_read
        xor rdi, rdi
        mov edi, [openai_subprocess_pipe_incoming]
        mov rsi, rsp
        mov rdx, 8
        syscall
        mov rax, [rsp]
        add rsp, 8
        syscall_footer
    epilog


openai_write_qword:  ; rax = qword a gravar
    prolog rax
        syscall_header
        sub rsp, 8
        mov [rsp], rax
        mov rax, 1  ; sys_write
        xor rdi, rdi
        mov edi, [openai_subprocess_pipe_outgoing+4]
        mov rsi, rsp
        mov rdx, 8
        syscall
        add rsp, 8
        syscall_footer
    epilog


openai_read_string:  ; rax = (retorno) ponteiro para a string lida
    prolog r8, rdi
        xor r8, r8
        xor rdi, rdi
        mov edi, [openai_subprocess_pipe_incoming]
        call read_until_byte
    epilog


%ifdef TESTING
global _start

_start:
    call openai_init_subprocess
    scanf r8, 'u', rax
    print_registers r8, rax
    mov r14, rax
    call openai_write_qword

    for rcx, 0, r14
        %rep 2
            xor rdi, rdi
            call read_line
            mov rsi, rax
            call openai_write_string
            mov rdi, rax
            call free
        %endrep
    endfor

    call openai_read_string
    mov rsi, rax
    call println

    call openai_read_string
    mov rsi, rax
    call println

    mov rdi, rax
    call free

    mov rax, -1
    call openai_write_qword

    mov rax, 60  ; sys_exit
    xor rdi, rdi
    syscall
%endif
