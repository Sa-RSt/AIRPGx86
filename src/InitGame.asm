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

section .data

    whatname: db "Qual é o seu nome? : ", 0

section .bss

    PlayerName: resb 32

section .text

    _start:
    game_starter:
        call openai_init_subprocess
        call exposition_dumping
        call choose_name
        call init_attributes
        call use_ability_points
        call status_init_list
        call exit
    


    choose_name:
        prolog rdi, rsi, r14

        printf "s", whatname
        mov rdi, PlayerName
        scanf rbx, "s", r14
        printf "c", 0x0A
        mov rsi, r14
        call strcpy

        epilog



    exposition_dumping:
        prolog

        epilog

%endif
