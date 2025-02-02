section .data

section .bss
    random_byte resb 1

section .text
    global _start
    %define DEBUG 1
    %include "stdlib_macros.asm"           ; Inclui o arquivo de macros

_start:
    mov rdi, 20         ; Valor de n para a função gera_numero
    call gera_numero
    call exit

; Devolve um número entre 1 e n. O valor máximo de n é 256.
; Recebe o valor de n em rdi, retorna o numero sorteado em rdx.
gera_numero:
    multipush rax, rbx, rcx, rsi

    ; Casos de erro
    cmp rdi, 256
    jg .erro_maximo
    cmp rdi, 1
    jl .erro_minimo

    ; Balanceia o intervalor de 0 a 255 para ter a mesma chance de se obter um número de 1 a n
    mov rdx, 0                  ; Parte superior do dividendo
    mov rax, 256                ; Parte inferior do dividendo
    div rdi                     ; Divisor (equivalente ao valor de n)
                                
    ; Determina o valor máximo do número aleatório aceito
    mov rsi, 256
    sub rsi, rdx                ; Resto da divisão fica em rdx
    sub rsi, 1                  ; Subtrai 1 pois foi calculado de 1 a 256 e não de 0 a 255

    ; Sorteia o número - Por algum motivo só funciona na arquitetura 32 bits em 64 bits o getrandom falha
    .loop:
        mov eax, 355                ; Código syscall getrandom
        lea ebx, [random_byte]      ; Endereço onde será 
        mov ecx, 1                  ; Ler 1 byte
        mov edx, 0                  ; Sem flags
        int 0x80                    ; Chamada do sistema 32 bits

        movzx eax, byte [random_byte]   ; Move o valor gerado para eax expandindo os zeros
        cmp eax, esi                    ; Compara com o valor máximo
        jg .loop                        ; Se for maior, pega outro número

    ; Calcula o resto do número sorteado por n
    mov rdx, 0                  ; Parte superior do dividendo
    mov eax, eax                ; Parte inferior do dividendo
    div rdi                     ; Divisor

    add rdx, 1                  ; Soma 1 para ficar de 1 a n

    ; printf "uc", rdx, 0x0A

    multipop rax, rbx, rcx, rsi
    ret

    .erro_maximo:
        print_literal "O valor máximo permitido para n é 256", 0x0A
        multipop rax, rbx, rcx, rsi
        call exit

    .erro_minimo:
        print_literal "Não é possível sortear para valores menores ou iguais a zero", 0x0A
        multipop rax, rbx, rcx, rsi
        call exit

exit:
    mov rax, 60                             	    ; Carrega o número da syscall para "exit" (número 60) no registrador rax
    mov rdi, 0                              	    ; Carrega o valor de saída (0) no registrador rdi (0 indica sucesso)
    syscall                                 	    ; Chama a syscall, o que vai terminar o programa