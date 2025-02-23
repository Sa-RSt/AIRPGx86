section .data

    gera_numero_dev_urandom: db "/dev/urandom", 0
    

section .bss
    random_byte resb 1

section .text
    %ifdef TESTING
        global _start
        %define DEBUG 1
    %endif
    %include "stdlib_macros.asm"           ; Inclui o arquivo de macros

%ifdef TESTING
;_start:
    mov rdi, 20         ; Valor de n para a função gera_numero
    call gera_numero
    print_registers rdx
    call exit
%endif

; Devolve um número entre 1 e n. O valor máximo de n é 256.
; Recebe o valor de n em rdi, retorna o numero sorteado em rdx.
gera_numero:
    multipush rax, rbx, rcx, rsi, r14, r15

    ; Casos de erro
    cmp rdi, 256
    jg .erro_maximo
    cmp rdi, 1
    jl .erro_minimo

    mov r15, rdi

    mov rax, 2  ; sys_open
    mov rdi, gera_numero_dev_urandom
    xor rsi, rsi  ; O_RDONLY
    xor rdx, rdx
    syscall
    
    mov r14, rax  ; guarda fd no r14
    
    xor rax, rax  ; sys_read
    mov rdi, r14
    mov rsi, random_byte
    mov rdx, 1
    syscall
    
    mov rax, 3  ; sys_close
    mov rdi, r14
    syscall

    xor rax, rax
    mov al, [random_byte]   ; Move o valor gerado para eax expandindo os zeros
    print_registers rax

    ; Calcula o resto do número sorteado por n
    mov rdx, 0                  ; Parte superior do dividendo (parte inferior está no rax)
    div r15                     ; Divisor

    add rdx, 1                  ; Soma 1 para ficar de 1 a n

    ; printf "uc", rdx, 0x0A

    multipop rax, rbx, rcx, rsi, r14, r15
    ret

    .erro_maximo:
        print_literal "O valor máximo permitido para n é 256", 0x0A
        call exit

    .erro_minimo:
        print_literal "Não é possível sortear para valores menores ou iguais a zero", 0x0A
        call exit
