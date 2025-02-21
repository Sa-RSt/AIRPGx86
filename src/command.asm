%ifdef TESTING
%define DEBUG 1
%endif

%include "stdlib_macros.asm"
%include "dice_roll.asm"
%include "status.asm"
%include "inventory.asm"
%include "AbilityScores.asm"
section .data

command_prefix_roll: db "roll", 0
command_prefix_update: db "update", 0
command_prefix_give: db "give", 0
command_prefix_take: db "take", 0
command_str_disadvantage: db "disadvantage", 0
command_str_advantage: db "advantage", 0
command_str_empty: db 0

command_call_lookup_table:
    dq command_prefix_roll, interpret_roll_command
    dq command_prefix_update, interpret_update_command
    dq command_prefix_give, interpret_give_command
    dq command_prefix_take, interpret_take_command
    dq 0


section .bss
command_inventory_address: resq 1
command_status_address: resq 1
command_abilities_address: resq 1
command_theme_address: resq 1

section .text


interpret_commands:  ; rdi = mensagem escrita pelo LLM, rdi = (retorno) mensagem sem os comandos. setar variáveis na seção .bss antes de chamar
    prolog rax, rsi, rdi, r10, r13, r8, r14, r9, r15, r12
    mov r12, rdi  ; preservar rdi no r12
    mov rsi, rdi
    call strend
    sub rdi, rsi
    mov r10, rdi  ; r10 agora tem o tamanho da string do LLM
    mov rdi, rsi

    mov rsi, r10  ; novo tamanho necessariamente é menor ou igual ao tamanho atual
    call malloc
    mov r13, rax  ; r13 terá o endereço da nova string por enquanto
    mov r14, rax  ; r14 terá a posição atual na nova string

    mov r8b, [rdi]
    whilenonzero r8b
        if e, r8b, '['
            inc rdi
            mov r15, rdi
            mov r8b, [r15]
            while ne, r8b, ' '
                inc r15
                mov r8b, [r15]
            endwhile  ; depois desse loop, r15 está no espaço logo após o nome do comando
            mov byte [r15], 0  ; marcar esse espaço como fim da string
            inc r15  ; r15 agora está no começo dos argumentos do comando em si
            mov r11, r15
            mov r8b, [r11]
            while ne, r8b, ']'
                inc r11
                mov r8b, [r11]
            endwhile  ; depois desse loop, r11 está no colchete que fecha o comando
            mov byte [r11], 0  ; marcar o colchete como fim da string também. agora r15 é uma string completa só com os argumentos
            mov r8, rdi
            mov rsi, command_call_lookup_table
            mov rdi, r11
            inc rdi
            mov r9, [rsi]
            whilenonzero r9  ; buscar comando correspondente na tabela de lookup
                call strcmp
                ifzero r11
                    mov r9, [rsi+8]
                    call r9  ; comando encontrado, chamar ele
                endif
                add rsi, 16
                mov r9, [rsi]
            endwhile
        else
            mov [r14], r8b
            inc r14
            inc rdi
        endif
        mov r8b, [rdi]
    endwhile

    mov rdi, r12
    mov rsi, r13
    call strcpy
    mov rdi, r13
    call free

    epilog


interpret_roll_command:  ; r15 = string com os parâmetros do comando
    prolog r8, r9, r11, r12, rsi, rax, r13, r14, rdi
    mov r9, command_str_advantage
    mov r8, r15
    call strstartswith
    ifzero r11  ; rolagem com vantagem
        mov r12, r15
        mov r8b, [r12]
        while ne, r8b, ' '
            inc r12
            mov r8b, [r12]
        endwhile
        mov byte [r12], 0
        lea rsi, [r12+1]
        call atou
        ifzero r13  ; rolar um número com vantagem
            mov r8, r15
            mov r13, rax
            call dice_roll_single_number
            jmp .return
        else  ; rolar um status com vantagem
            mov r13, rsi
            mov r8, r15
            mov r15, [command_abilities_address]
            call dice_roll_for_ability_score
            jmp .return
        endif
    else
        mov r9, command_str_disadvantage
        call strstartswith
        ifzero r11  ; rolagem com desvantagem
            mov r12, r15
            mov r8b, [r12]
            while ne, r8b, ' '
                inc r12
                mov r8b, [r12]
            endwhile
            mov byte [r12], 0
            lea rsi, [r12+1]
            call atou
            ifzero r13  ; rolar um número com desvantagem
                mov r8, r15
                mov r13, rax
                call dice_roll_single_number
                jmp .return
            else  ; rolar um status com desvantagem
                mov r13, rsi
                mov r8, r15
                mov r15, [command_abilities_address]
                call dice_roll_for_ability_score
                jmp .return
            endif
        else  ; rolagem sem vantagem nem desvantagem
            mov r12, r15
            mov r8b, [r12]
            while ne, r8b, ' '
                test r8b, r8b
                jz .is_ability_roll
                inc r12
                mov r8b, [r12]
            endwhile
            mov byte [r12], 0
            mov rsi, r15
            call atou
            test r13, r13
            jz .is_number_roll
            jmp .return
            .is_ability_roll:
            mov r13, r15
            mov r15, [command_abilities_address]
            mov r8, command_str_empty
            call dice_roll_for_ability_score
            jmp .return
            .is_number_roll:
            mov r14, rax
            lea rsi, [r12+1]
            call atou
            ifzero r13
                mov r12, r14
                mov r13, rax
                call dice_roll_N_M
            endif
            jmp .return
        endif
    endif
    .return:
    epilog

interpret_update_command:  ; r15 = string com os parâmetros do comando
    prolog r12, r15, r8, rsi, r13, r14, rdi
    mov r12, r15  ; r15 terá o código
    mov r8b, [r12]
    while ne, r8b, ' '
        inc r12
        mov r8b, [r12]
    endwhile
    mov byte [r12], 0
    inc r12  ; r12 terá a operação

    mov rsi, r12
    mov r8b, [rsi]
    while ne, r8b, ' '
        inc rsi
        mov r8b, [rsi]
    endwhile
    mov byte [rsi], 0  ; rsi terá o número
    inc rsi
    
    mov r8, r12
    mov r14, r15
    mov r15, [command_status_address]
    call status_update_command
    
    epilog

interpret_give_command:  ; r15 = string com os parâmetros do comando
    prolog r15, r12, r8, r9, rsi, r13, r14, rdi
    mov r13, r15
    mov r8b, [r13]
    while ne, r8b, '|'
        inc r13
        mov r8b, [r13]
    endwhile
    mov byte [r13], 0
    inc r13  ; r13 ficará com a string da quantidade

    mov r12, r13
    mov r8b, [r12]
    while ne, r8b, '|'
        inc r12
        mov r8b, [r12]
    endwhile
    mov byte [r12], 0
    inc r12
    mov rsi, r12
    call trim
    mov r12, rsi
    mov byte [r9], 0

    mov rsi, r13
    call trim
    mov r13, rsi
    mov byte [r9], 0

    mov rsi, r15
    call trim
    mov byte [r9], 0
    mov r14, rsi  ; r14 ficará com o nome

    mov r15, [command_inventory_address]
    call inventory_command_give
    mov [command_inventory_address], r15
    epilog

interpret_take_command:  ; r15 = string com os parâmetros do comando
    prolog r15, r12, r8, r9, rsi, r13, r14, rdi
    mov r13, r15
    mov r8b, [r13]
    while ne, r8b, '|'
        inc r13
        mov r8b, [r13]
    endwhile
    mov byte [r13], 0
    inc r13  ; r13 ficará com a string da quantidade
    mov rsi, r15
    call trim
    mov byte [r9], 0
    mov r14, rsi  ; r14 ficará com o nome

    mov rsi, r13
    call trim
    mov r13, rsi
    mov byte [r9], 0

    mov r15, [command_inventory_address]
    call inventory_command_take
    mov [command_inventory_address], r15
    epilog


%ifdef TESTING

section .data
section .bss
_command_test: resq 3
section .text
global _start

;_start:
    mov qword [command_inventory_address], 0
    call status_init_list
    mov [command_status_address], r15
    call init_attributes
    mov [command_abilities_address], r15
    xor rdi, rdi
    call read_line
    mov [command_theme_address], rax
    call read_line
    mov rdi, rax
    call interpret_commands
    mov rsi, rdi
    call println
    mov r15, [command_inventory_address]
    call print_inventory
    mov r15, [command_status_address]
    call print_status
    mov r8, _command_test
    call status_values_array
    mov r8, [r8+16]
    printf 'ic', "Luck ", r8, 10
    mov rsi, dice_roll_feedback
    call println
    call exit

%endif
