%ifndef INIT_GAME
%define INIT_GAME 1

%define DEBUG 1
global _start

%include "AbilityScores.asm"
%include "status.asm"
%include "openai.asm"
%include "conversation.asm"
%include "command.asm"

section .data

    welcome: db "Bem vindo ao RPGPT! Esse jogo se trata de um RPG normal em que o seu DM é o chatGPT, sem mais delongas, vamos começar o jogo!", 0x0A, 0
    whatname: db "Qual é o seu nome? : ", 0
    whattheme: db "Qual será o tema da sua aventura? : ", 0
    invalidname: db "Nome inválido! O nome deve ter menos que 32 caracteres!", 0

section .bss

    PlayerName: resb 32
    stat_array: resb 24
    att_array: resb 56

section .text

    _start:
    game_starter:
        call openai_init_subprocess
        printf 's', welcome
        call choose_name
        call init_attributes
        call use_ability_points ; Lista de atributos em r15
        mov [command_abilities_address], r15
        mov r9, att_array
        call att_values_array ; Array de atributos em r9
        mov r14, r15 ; Lista de atributos em r14
        call status_init_list ; Lista de status em r15
        mov [command_status_address], r15
        call theme_ask ; Tema em r8
        call conversation_elaborate_theme
        mov r11, rax ; Coloca o tema elaborado em r11
        mov [command_theme_address], r11
        mov r8, stat_array
        call status_values_array ; Array de status em r8
        mov r10, 0 ; Inventário inicia nulo
        call conversation_initial_description
        mov rdi, rax
        mov qword [command_inventory_address], 0
        call interpret_commands
        printf "s", rdi ; Imprime a descrição inicial
        call free
        call interactive_loop
        call openai_shutdown_subprocess
        ret
    

    interactive_loop:
        prolog
        .forever:
        call check_death
        mov r8b, [dice_roll_feedback]
        ifnonzero r8b
            mov r8, conversation_role_user
            mov r9, dice_roll_feedback
            call conversation_context_push
            call dice_roll_clear_feedback
            call update_prepend_params
            call conversation_context_send_to_openai
            mov rdi, rax
            call interpret_commands
            mov rsi, rdi
            call trim_whitespace
            mov [r9], byte 0
            printf 'sssc', color_by_id_192, rsi, color_reset, 10
            jmp .forever
        endif

        print_literal 10
        mov r15, [command_inventory_address]
        call print_inventory

        print_literal 10

        mov r15, [command_status_address]
        call print_status

        print_literal 10
        call check_death
        printf 'ssss', color_reset, color_by_id_64, "[", PlayerName, "]> ", color_by_id_163
        xor rdi, rdi
        call read_line

        printf 's', color_reset
        mov r12, rax
        call update_prepend_params
        call conversation_player_request
        mov rdi, rax
        mov r14, rax
        call strdup
        call interpret_commands
        push rdi
        call check_death

        call update_prepend_params
        mov r12, r14
        call conversation_model_review
        mov rdi, rax
        call interpret_commands
        pop rsi
        call check_death
        call trim_whitespace
        mov [r9], byte 0
        printf 'sssc', color_by_id_192, rsi, color_reset, 10
        jmp .forever
        epilog


    update_prepend_params:
        prolog r15
        mov r8, stat_array
        mov r15, [command_status_address]
        call status_values_array ; Array de status em r8
        mov r11, [command_theme_address]
        mov r9, att_array
        mov r10, [command_inventory_address]
        call check_death
        epilog

    check_death:
        prolog rcx, r15, r8
        mov r8, stat_array
        mov r15, [command_status_address]
        mov rcx, [stat_array]
        ifzero rcx
            printf 'cssc', 0x0A, color_red, "Você morreu! :(", color_reset, 10
            call exit
        endif
        epilog

    choose_name:
        prolog rdi, rsi, r14

        choose_name_loop:
        printf "s", whatname
        mov rdi, 0
        call read_line
        mov rsi, rax
        mov rdi, PlayerName
        call strcpy
        mov rsi, rdi
        call strsiz
        cmp rdi, 32
        jg choose_name_invalid
        jmp choose_name_end

        choose_name_invalid:
        printf "sc", invalidname, 0x0A
        jmp choose_name_loop

        choose_name_end:
        printf "c", 0x0A
        epilog



    theme_ask:
        prolog
        printf "s", whattheme
        mov rdi, 0
        call read_line
        mov r8, rax
        printf "c", 0x0A
        epilog

%endif

