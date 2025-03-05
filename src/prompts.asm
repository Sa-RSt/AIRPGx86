%ifdef TESTING
    %define DEBUG 1
    global _start
%endif
%include "stdlib_macros.asm"

section .data

prompt_template_elaborate_theme:
    incbin "../prompts/elaborate_theme.txt"
    db 0

prompt_template_initial_description:
    incbin "../prompts/initial_description.txt"
    db 0

prompt_template_prepend:
    incbin "../prompts/prepend.txt"
    db 0

prompt_template_review:
    incbin "../prompts/review.txt"
    db 0

prompt_template_viability:
    incbin "../prompts/viability.txt"
    db 0

prompt_template_request_with_viability:
    incbin "../prompts/request_with_viability.txt"
    db 0

section .text

prompt_replace:  ; rdi = template a usar, r9 = vetor terminado em ponteiro nulo de strings para substituir, rax = (retorno) string processada na heap
    prolog rdi, r9, r14, r13, r8, r10, r15, r12, rcx, rsi, r11
        mov r12, rdi  ; salvar template no r12
        mov rsi, rdi
        call strend
        lea r14, [rdi+1]  ; calcular tamanho total necessário para alocação no r14. começar com o template em si
        ; por conta dos padrões $N de substituição, o tamanho calculado no final vai ser um pouquinho maior
        ; do que o suficiente para armazenar a string inteira, mas isso pode ser desprezado
        sub r14, rsi
        mov r11, r9
        mov rsi, [r9]
        ; estamos considerando que não existem padrões de substituição repetidos dentro do template
        whilenonzero rsi  ; o último elemento do vetor é um ponteiro nulo
            mov rdi, rsi
            call strend
            add r14, rdi  ; r14 = r14 + rdi - rsi
            sub r14, rsi  ; rdi - rsi é o tamanho da string, pois rdi aponta para o \0
            inc r14  ; considerar o \0 no final da string
            add r9, 8
            mov rsi, [r9]
        endwhile
        mov r9, r11
        mov rsi, r14
        call malloc
        mov r15, rax  ; salvar rax (bloco resultado, que será retornado pela função) no r15
        mov r10, rax  ; gravar usando ponteiro r10
        mov r14, r12  ; percorrer template usando r14
        mov r8b, [r14]
        whilenonzero r8b
            if e, r8b, '$'
                sub rsp, 8
                mov rsi, rsp

                for rcx, 1, 8  ; consumir os próximos caracteres até encontrar um que não seja um número.
                    mov r8b, [r14+rcx]
                    cmp r8b, '0'
                    jl .break_loop
                    cmp r8b, '9'
                    jg .break_loop
                    mov [rsi], r8b
                    inc rsi
                endfor
                .break_loop:
                add r14, rcx  ; contabilizar que os caracteres foram consumidos
                dec r14
                mov byte [rsi], 0  ; add \0 para construir a string que o atou precisa
                mov rsi, rsp
                call atou
                ifnonzero r13
                    print_literal "Erro de template: uint inválido: "
                    call println
                    call exit
                endif
                mov rdi, r10
                dec rax  ; números no template começam em um, arrays começam em zero
                mov rsi, [r9+8*rax]
                mov rdi, r10
                call strcpy  ; copiar string passada como parâmetro para a string resultado
                call strend  ; colocar "cursor" no final da string resultado
                mov r10, rdi
                add rsp, 8
            else  ; se o caractere atual não for '$', só copiamos para o 
                mov [r10], r8b
                inc r10
            endif
            inc r14
            mov r8b, [r14]
        endwhile
        mov rax, r15
    epilog

%ifdef TESTING
    ;_start:
        print_literal "Digite o número de textos: "
        scanf r8, 'u', r10
        assert e, r8, 1
        shl r10, 3
        sub rsp, r10
        sub rsp, 8
        mov qword [rsp+r10], 0
        xor rdi, rdi
        for rcx, 0, r10, 8
            call read_line
            mov [rsp+rcx], rax
        endfor
        mov rdi, prompt_template_prepend
        mov r9, rsp
        call prompt_replace
        mov rsi, rax
        call println
        mov rdi, rax
        call free
        for rcx, 0, r10, 8
            mov rdi, [rsp+rcx]
            call free
        endfor
        call exit
%endif
