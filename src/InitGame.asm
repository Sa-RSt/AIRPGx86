%ifndef INIT_GAME
%define INIT_GAME 1

%ifdef TESTING
    global _start
    %define DEBUG 1
%endif

%define DEBUG 1
global _start

%include "AbilityScores.asm"
%include "openai.asm"

section .data

    whatname: db "Qual é o seu nome? : ", 0

section .bss

    PlayerName: resb 32

section .text

    _start:
    game_starter:
        call choose_name
        call init_attributes
        call use_ability_points

    


    choose_name:
        prolog r14

        printf "s", whatname
        mov r14, PlayerName
        scanf rbx, "s", r14 
        mov r14, r10
        mov r12, PlayerName
        printf "s", PlayerName

        epilog

%endif
