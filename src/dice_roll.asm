%ifndef DICE_ROLL
%define DICE_ROLL 1

%ifdef TESTING
    %define DEBUG 1
%endif

%include "stdlib_macros.asm"
%include "LinkedList.asm"
%include "color.asm"
%include "AbilityScores.asm"
%include "gera_numero.asm"

section .data

dice_roll_str_Roll: db "Resultado da rolagem ", 0
dice_roll_str_for: db "para ", 0
dice_roll_str_colon: db ": ", 0
dice_roll_str_vantagem: db " (com vantagem)", 0
dice_roll_str_desvantagem: db " (com desvantagem)", 0
dice_roll_str_comma: db ", ", 0
dice_roll_str_Soma: db " (Soma: ", 0
dice_roll_str_close_par: db ")", 10, 0
dice_roll_str_advantage: db "advantage", 0
dice_roll_str_disadvantage: db "disadvantage", 0
dice_roll_str_empty: db 0
dice_roll_spinner: db "-\\|/", 0
dice_roll_str_sucesso: db " (sucesso)", 0
dice_roll_str_falhou: db " (falhou)", 0
section .bss

dice_roll_feedback: resb 65536

section .text

dice_roll_clear_feedback:
    prolog
    mov byte [dice_roll_feedback], 0
    epilog

dice_roll_N_M:  ; r12 = N (número de dados), r13 = M (número de lados)
    prolog rdi, rdx, r11, rdx, r8, r9, rsi, rax

    cmp r12, 1000  ; previnir valores gigantes ou negativos
    jge .return
    cmp r12, 0
    jle .return

    cmp r13, 1
    jle .return  ; previnir dados com números de lados que não fazem sentido
    cmp r13, 256
    jg .return

    mov rdi, dice_roll_feedback
    call strend  ; colocar rdi no final do feedback atual (concatenação)

    mov rsi, dice_roll_str_Roll
    call strcpy
    call strend

    mov rax, r12
    call utoa
    call strend

    mov byte [rdi], 'D'
    inc rdi

    mov rax, r13
    call utoa
    call strend

    mov rsi, dice_roll_str_colon
    call strcpy
    call strend    

    xor r8, r8  ; r8 terá a soma
    mov r9, rdi
    for r11, 0, r12  ; executar r12 vezes
        mov rdi, r13
        call gera_numero
        mov rdi, r9
        add r8, rdx
        mov rax, rdx
        ifnonzero r11
            mov rsi, dice_roll_str_comma
            call strcpy
            call strend
        endif
        call utoa
        call strend
    endfor

    mov rsi, dice_roll_str_Soma
    call strcpy
    call strend

    mov rax, r8
    call utoa
    call strend

    mov rsi, dice_roll_str_close_par
    call strcpy
    call strend

    printf 'ssuuss', color_reset, "Rolando ", color_brightmagenta, r12, "D", r13, color_reset, "...", color_cyan
    call make_spinner
    printf 'susc', "  ", color_bold, r8, color_reset, 10

    .return:
    epilog

dice_roll_for_ability_score:  ; r15 = lista de ability scores, r13 = código, r8 = (string) "", "advantage" ou "disadvantage"
    prolog r15, r9, r11, rdx, rdi, r8, r10, rax
    multipush r15, r13
    call list_index_search
    add rsp, 16
    cmp r15, -1
    je .return  ; o ability score precisa existir para essa função funcionar

    mov r10, 20
    mov r9, [r15+184]  ; ler ability score
    sub r10, r9  ; r10 = 20 - score (threshold para vitória na rolagem)

    mov rdi, dice_roll_feedback
    call strend
    mov rsi, dice_roll_str_Roll
    call strcpy
    call strend

    mov rsi, dice_roll_str_for
    call strcpy
    call strend

    mov rsi, r13
    call strcpy
    call strend

    xor r11, r11
    mov r11b, [r8]
    ifzero r11  ; não é advantage nem disadvantage
        mov rdi, 20
        call gera_numero
        mov rdi, dice_roll_feedback
        call strend
        mov rsi, dice_roll_str_colon
        call strcpy
        call strend
        mov rax, rdx
        call utoa
        call strend
        
        
        if l, rax, r10
            mov rsi, dice_roll_str_falhou
            call strcpy
            call strend
        else
            mov rsi, dice_roll_str_sucesso
            call strcpy
            call strend
        endif

        printf 'sssss', color_reset, "Rolando ", color_brightmagenta, r13, color_reset, "...", color_cyan
        call make_spinner
        printf 'sussc', "  ", color_bold, rax, rsi, color_reset, 10
    else
        mov r9, dice_roll_str_advantage
        call strcmp
        ifzero r11  ; é advantage
            mov rdi, 20
            call gera_numero
            mov rax, rdx
            call gera_numero  ; rolar dois dados
            mov rdi, dice_roll_feedback
            call strend
            mov rsi, dice_roll_str_vantagem
            call strcpy
            call strend
            mov rsi, dice_roll_str_colon
            call strcpy
            call strend
            if l, rax, rdx
                mov rax, rdx
            endif

            if l, rax, r10
                mov rsi, dice_roll_str_falhou
                call strcpy
                call strend
            else
                mov rsi, dice_roll_str_sucesso
                call strcpy
                call strend
            endif

            call utoa
            call strend

            printf 'sssss', color_reset, "Rolando ", color_brightmagenta, r13, " com vantagem", color_reset, "...", color_cyan
            call make_spinner
            printf 'sussc', "  ", color_bold, rax, rsi, color_reset, 10
        else
            mov r9, dice_roll_str_disadvantage
            call strcmp
            test r11, r11
            jnz .return  ; se não for disadvantage aqui, é algo inválido

            mov rdi, 20
            call gera_numero
            mov rax, rdx
            call gera_numero  ; rolar dois dados
            mov rdi, dice_roll_feedback
            call strend
            mov rsi, dice_roll_str_desvantagem
            call strcpy
            call strend
            mov rsi, dice_roll_str_colon
            call strcpy
            call strend
            if g, rax, rdx
                mov rax, rdx
            endif

            if l, rax, r10
                mov rsi, dice_roll_str_falhou
                call strcpy
                call strend
            else
                mov rsi, dice_roll_str_sucesso
                call strcpy
                call strend
            endif

            call utoa
            call strend

            printf 'sssss', color_reset, "Rolando ", color_brightmagenta, r13, " com desvantagem", color_reset, "...", color_cyan
            call make_spinner
            printf 'sussc', "  ", color_bold, rax, rsi, color_reset, 10
        endif
    endif

    .return:
    epilog


dice_roll_single_number:  ; r13 = número (u64), r8 = (string) "", "advantage" ou "disadvantage"
    prolog r9, r11, rdx, rdi, r8, r10, rax
    
    cmp r13, 1
    jle .return  ; previnir dados com números de lados que não fazem sentido
    cmp r13, 256
    jg .return

    mov rdi, dice_roll_feedback
    call strend
    mov rsi, dice_roll_str_Roll
    call strcpy
    call strend

    mov byte [rdi], 'D'
    inc rdi

    mov rsi, r13
    call utoa
    call strend

    xor r11, r11
    mov r11b, [r8]
    ifzero r11  ; não é advantage nem disadvantage
        mov rdi, r13
        call gera_numero
        mov rdi, dice_roll_feedback
        call strend
        mov rsi, dice_roll_str_colon
        call strcpy
        call strend
        mov rax, rdx
        call utoa
        call strend

        printf 'ssuss', color_reset, "Rolando ", color_brightmagenta, "D", r13, color_reset, "...", color_cyan
        call make_spinner
        printf 'susc', "  ", color_bold, rax, color_reset, 10
    else
        mov r9, dice_roll_str_advantage
        call strcmp
        ifzero r11  ; é advantage
            mov rdi, r13
            call gera_numero
            mov rax, rdx
            call gera_numero  ; rolar dois dados
            mov rdi, dice_roll_feedback
            call strend
            mov rsi, dice_roll_str_vantagem
            call strcpy
            call strend
            mov rsi, dice_roll_str_colon
            call strcpy
            call strend
            if l, rax, rdx
                mov rax, rdx
            endif
            call utoa
            call strend

            printf 'ssuss', color_reset, "Rolando ", color_brightmagenta, "D", r13, " com vantagem", color_reset, "...", color_cyan
            call make_spinner
            printf 'susc', "  ", color_bold, rax, color_reset, 10
        else
            mov r9, dice_roll_str_disadvantage
            call strcmp
            test r11, r11
            jnz .return  ; se não for disadvantage aqui, é algo inválido

            mov rdi, r13
            call gera_numero
            mov rax, rdx
            call gera_numero  ; rolar dois dados
            mov rdi, dice_roll_feedback
            call strend
            mov rsi, dice_roll_str_desvantagem
            call strcpy
            call strend
            mov rsi, dice_roll_str_colon
            call strcpy
            call strend
            if g, rax, rdx
                mov rax, rdx
            endif
            call utoa
            call strend

            printf 'ssuss', color_reset, "Rolando ", color_brightmagenta, "D", r13, " com desvantagem", color_reset, "...", color_cyan
            call make_spinner
            printf 'susc', "  ", color_bold, rax, color_reset, 10
        endif
    endif

    .return:
    epilog


make_spinner:
    prolog rdi, rdx, r8, r9, rsi, r10

    mov rdi, 30
    call gera_numero
    add rdx, 10

    mov r9, dice_roll_spinner

    sub rsp, 8
    mov rsi, rsp
    mov byte [rsi+1], 8  ; backspace
    mov byte [rsi+2], 0

    for rdi, 0, rdx
        mov r8b, [r9]
        ifzero r8b
            mov r9, dice_roll_spinner
            mov r8b, [dice_roll_spinner]
        else
            inc r9
        endif
        mov [rsi], r8b
        call print
        mov r10, 100
        call delay
    endfor

    add rsp, 8

    epilog


%ifdef TESTING
    section .data

    section .text

    global _start

    _start:
        call init_attributes
        call use_ability_points
        mov r13, att_dex
        mov r8, dice_roll_str_empty
        call dice_roll_for_ability_score
        mov r8, dice_roll_str_advantage
        call dice_roll_for_ability_score
        mov r8, dice_roll_str_disadvantage
        call dice_roll_for_ability_score

        mov r12, 9
        mov r13, 2
        call dice_roll_N_M

        mov r13, 8
        call dice_roll_single_number
        mov r8, dice_roll_str_advantage
        call dice_roll_single_number
        mov r8, dice_roll_str_empty
        call dice_roll_single_number

        call exit
%endif


%endif
