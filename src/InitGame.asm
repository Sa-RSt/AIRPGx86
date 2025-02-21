%ifndef INIT_GAME
%define INIT_GAME 1

%ifdef TESTING
    global _start
    %define DEBUG 1
%endif

%define DEBUG 1
global _start

%include "AbilityScores.asm"
%include "status.asm"
%include "openai.asm"
%include "conversation.asm"

section .data

    welcome: db "Bem vindo ao RPGPT! Esse jogo se trata de um RPG normal em que o seu DM é o chatGPT, sem mais delongas, vamos começar o jogo!", 0x0A, 0
    whatname: db "Qual é o seu nome? : ", 0
    whattheme: db "Qual será o tema da sua aventura? : ", 0
    invalidname: db "Nome inválido! O limíte são 32 caracteres!", 0

section .bss

    PlayerName: resb 32
    stat_array: resb 24
    att_array: resb 56

section .text

    _start:
    game_starter:
        printf "xc", rsp, 0x0A
        call openai_init_subprocess
        printf 's', welcome
        call choose_name
        call init_attributes
        call use_ability_points ; Lista de atributos em r15
        mov r9, att_array
        call att_values_array ; Array de atributos em r9
        mov r14, r15 ; Lista de atributos em r14
        call status_init_list ; Lista de status em r15
        call theme_ask ; Tema em r8
        call conversation_elaborate_theme
        mov r11, rax ; Coloca o tema elaborado em r11
        mov r8, stat_array
        call status_values_array ; Array de status em r8
        mov r10, 0 ; Inventário inicia nulo
        call conversation_initial_description
        printf "s", rax ; Imprime a descrição inicial
        call openai_shutdown_subprocess
        printf "s", PlayerName
        call exit
        ret
    


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
        epilog

%endif
