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

section .bss

    PlayerName: resb 32

section .text

    game_starter:
        call openai_init_subprocess
        printf 's', welcome
        call choose_name
        call init_attributes
        call use_ability_points ; Lista de atributos em r15
        call att_values_array ; Array de atributos em r9
        mov r14, r15 ; Lista de atributos em r14
        call status_init_list ; Lista de status em r15
        call theme_ask ; Tema em r8
        call conversation_elaborate_theme
        mov r11, rax ; Coloca o tema elaborado em r11
        call status_values_array ; Array de status em r8
        mov r10, 0 ; Inventário inicia nulo
        call conversation_initial_description
        printf "s", rax ; Imprime a descrição inicial
        call openai_shutdown_subprocess
        ret
    


    choose_name:
        prolog rdi, rsi, r14

        printf "s", whatname
        mov rdi, PlayerName
        scanf rbx, "s", r14
        printf "c", 0x0A
        mov rsi, r14
        call strcpy

        epilog

    theme_ask:
        prolog
        printf "s", whattheme
        scanf rbx, "s", r8
        epilog

%endif
