%ifdef TESTING
    global _start
    %define DEBUG 1
%endif
%include "stdlib_macros.asm"
%include "LinkedList.asm"
%include "color.asm"

section .data
    inventory_field_amount: equ 0
    inventory_field_description: equ 8
    inventory_prompt_empty_string: db "Atualmente, o inventário do jogador está vazio.", 0
    inventory_prompt_currently_contains: db "Atualmente, o inventário do jogador contém:", 0
    inventory_string_list_sep: db 10, " - ", 0
    inventory_string_list_colon: db ": ", 0
    inventory_string_amount_open: db " (amount: ", 0
    inventory_string_amount_close: db ")", 0

section .bss

    inventory_prompt_string: resb 16384

section .text

; rax = nome do item (string que será copiada)
; rcx = quantidade (u64)
; rsi = descrição (string que será copiada)
; r15 = endereço para o primeiro item do inventário (null se estiver vazio)
; r15 = (retorno) endereço para o novo primeiro item do inventário (se estava vazio antes)
; essa função é de uso interno em inventory.asm. use por sua conta e risco!
_inventory_put_item:
    prolog r11, r8
    sub rsp, 128  ; reservar bloco de 128 bytes "info" para colocar na lista
    mov r11, rsp
    mov [r11+inventory_field_amount], rcx

    lea rdi, [r11+inventory_field_description]
    mov r8, 120
    call strncpy  ; copiar descrição para o bloco da lista

    ifzero r15  ; inventário vazio -> inicializá-lo
        multipush rax, r11
        call init_list
        add rsp, 16
    else  ; adicionar item no inventário
        multipush r15, rax, r11
        call add_to_list
        add rsp, 24
    endif
    add rsp, 128
    epilog


; rax = nome do item (string que será copiada)
; rcx = quantidade (i64)
; rsi = descrição (string que será copiada)
; r15 = endereço para o primeiro item do inventário (null se estiver vazio)
; r15 = (retorno) endereço para o novo primeiro item do inventário (se estava vazio antes)
inventory_give_or_take_item:
    prolog r14, r8, r9
    ifzero r15
        if g, rcx, 0
            call _inventory_put_item  ; inventário está vazio -> inicializar com o item fornecido
        endif
    else
        mov r14, r15  ; salvar endereço da lista no r14
        multipush r15, rax
        call list_index_search
        add rsp, 16
        if e, r15, -1
            mov r15, r14  ; restaurar endereço original da lista
            if g, rcx, 0
                call _inventory_put_item  ; item não encontrado -> colocar novo item
            endif
        else
            mov r9, r15  ; guardar item encontrado no r9
            mov r15, r14  ; restaurar endereço original da lista
            mov r8, [r9+64+inventory_field_amount]
            add r8, rcx
            if le, r8, 0
                multipush r14, rax; remover item se nova quantidade for menor ou igual a zero
                call remove_from_list
                add rsp, 16
            else
                mov [r9+64+inventory_field_amount], r8
            endif
        endif
    endif
    epilog


; r15 = endereço para o primeiro item do inventário (null se estiver vazio)
; r15 = (retorno) endereço para o novo primeiro item do inventário (se estava vazio antes)
; r14 = nome do item (string que será copiada)
; r13 = quantidade (string)
; r12 = descrição (string que será copiada)
inventory_command_give:
    prolog rax, rcx, rsi, r13
    mov rsi, r13
    call atou
    test r13, r13
    jnz .return  ; retornar se atou tiver falhado

    mov rcx, rax
    mov rax, r14  ; trocar os registradores para se adequar à convenção da outra função
    mov rsi, r12
    call inventory_give_or_take_item

    .return:
    epilog


; r15 = endereço para o primeiro item do inventário (null se estiver vazio)
; r15 = (retorno) endereço para o novo primeiro item do inventário (se estava vazio antes)
; r14 = nome do item (string que será copiada)
; r13 = quantidade (string)
inventory_command_take:
    prolog rax, rcx, rsi, r13
    mov rsi, r13
    call atou
    test r13, r13
    jnz .return  ; retornar se atou tiver falhado

    mov rcx, rax  ; trocar os registradores para se adequar à convenção da outra função
    neg rcx  ; inverter o sinal da quantidade
    mov rax, r14
    xor rsi, rsi  ; não deve haver tentativa de copiar a descrição; isso indicaria um erro lógico no programa
    call inventory_give_or_take_item

    .return:
    epilog


; r15 = endereço para o primeiro item do inventário (null se estiver vazio)
; rax = (retorno) string para ser colocada no prompt
; IMPORTANTE: a string retornada estará na memória estática do programa, possivelmente
; no modo somente leitura, e será invalidada caso inventory_to_prompt_string seja
; chamada novamente. Se quiser preservar a string retornada, copie-a para outro lugar!
inventory_to_prompt_string:
    prolog rsi, r8, r15
    ifzero r15
        mov rax, inventory_prompt_empty_string  ; inventário está vazio
    else
        mov rdi, inventory_prompt_string
        mov rsi, inventory_prompt_currently_contains
        call strcpy  ; copiar cabeçalho
        call strend  ; colocar rdi no final da string atual (para concatenação de strings)

        whilenonzero r15
            mov rsi, inventory_string_list_sep
            call strcpy
            call strend  ; adicionar uma "decoração de lista" (marcador com traço no início do item)

            mov rsi, r15
            call strcpy
            call strend  ; adicionar o nome do item

            mov rsi, inventory_string_list_colon
            call strcpy
            call strend  ; dois pontos

            lea rsi, [r15+72]
            call strcpy
            call strend  ; descrição do item

            mov rsi, inventory_string_amount_open
            call strcpy
            call strend

            mov rax, [r15+64]
            call utoa  ; concatenar quantidade
            call strend
            
            mov rsi, inventory_string_amount_close
            call strcpy
            call strend

            mov r15, [r15+192]  ; próximo item do inventário
        endwhile
        mov rax, inventory_prompt_string
    endif
    epilog


; r15 = endereço para o primeiro item do inventário (null se estiver vazio)
print_inventory:
    prolog r8, r15
    printf 'ssss', color_bold, color_yellow, "Inventário", color_faint, ":", color_reset
    ifzero r15  ; inventário vazio
        printf 'cssc', 10, color_faint, "    ~ vazio ~", color_reset, 10
    else
        whilenonzero r15
            mov r8, [r15+64]
            printf 'sss', color_faint, inventory_string_list_sep, color_reset
            printf 'sss', color_brightcyan, r15, color_reset
            printf 'ssusss', color_faint, " (", color_green, r8, color_reset, color_faint, ")", color_reset
            mov r15, [r15+192]  ; próximo item do inventário
        endwhile
        print_literal 10  ; quebra de linha
    endif
    epilog


%ifdef TESTING
    section .data
    
    _str_inventory_test_A: db "A", 0
    _str_inventory_test_B: db "B", 0
    _str_inventory_test_C: db "C", 0
    _str_inventory_test_10: db "10", 0
    _str_inventory_test_2: db "2", 0
    _str_inventory_test_desc1: db "testeeeee", 0
    _str_inventory_test_desc2: db "abcdefghiklmnopqrstuvwxyz", 0

    section .text
    _start:  ; código de teste manual
        xor r15, r15
        mov r14, _str_inventory_test_A
        mov r13, _str_inventory_test_10
        call inventory_command_take

        call inventory_to_prompt_string
        printf 'scc', rax, 10, 10
        call print_inventory

        mov r12, _str_inventory_test_desc2
        call inventory_command_give

        call inventory_to_prompt_string
        printf 'scc', rax, 10, 10
        call print_inventory

        mov r13, _str_inventory_test_2
        call inventory_command_take

        call inventory_to_prompt_string
        printf 'scc', rax, 10, 10
        call print_inventory

        mov r14, _str_inventory_test_C
        mov r12, _str_inventory_test_desc1
        call inventory_command_give

        call inventory_to_prompt_string
        printf 'scc', rax, 10, 10
        call print_inventory

        mov r14, _str_inventory_test_B
        mov r13, _str_inventory_test_10
        call inventory_command_give

        call inventory_to_prompt_string
        printf 'scc', rax, 10, 10
        call print_inventory

        mov r14, _str_inventory_test_A
        mov r13, _str_inventory_test_10
        call inventory_command_take

        call inventory_to_prompt_string
        printf 'scc', rax, 10, 10
        call print_inventory

        mov r14, _str_inventory_test_B
        mov r13, _str_inventory_test_10
        call inventory_command_give

        call inventory_to_prompt_string
        printf 'scc', rax, 10, 10
        call print_inventory

        mov r14, _str_inventory_test_A
        call inventory_command_take

        call inventory_to_prompt_string
        printf 'scc', rax, 10, 10
        call print_inventory

        mov r14, _str_inventory_test_B
        call inventory_command_take

        call inventory_to_prompt_string
        printf 'scc', rax, 10, 10
        call print_inventory

        call inventory_command_take

        call inventory_to_prompt_string
        printf 'scc', rax, 10, 10
        call print_inventory

        mov r14, _str_inventory_test_C
        call inventory_command_take

        call inventory_to_prompt_string
        printf 'scc', rax, 10, 10
        call print_inventory

        call exit
%endif

