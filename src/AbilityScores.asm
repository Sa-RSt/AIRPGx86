%ifndef ABILITY_SCORES
%define ABILITY_SCORES 1

%define DEBUG 1
global _start

%ifdef TESTING
    global _start
    %define DEBUG 1
%endif
%include "stdlib_macros.asm"
%include "LinkedList.asm"
%include "color.asm"

section .data
    ability_desc: equ 64
    ability_value: equ 184

    ability_loop_prompt1: db "Você tem ", 0
    ability_loop_prompt2: db " pontos de habilidade disponíveis", 0xA, 0

    att_str: db "STR", 0 ; Força
    att_con: db "CON", 0 ; Constituição
    att_dex: db "DEX", 0 ; Destreza
    att_wis: db "WIS", 0 ; Sabedoria
    att_int: db "INT", 0 ; Inteligência
    att_cha: db "CHA", 0 ; Carisma
    att_per: db "PER", 0 ; Percepção

    desc_str: db "Força física, como a capacidade de mover objetos pesados e causar mais dano", 0
    desc_con: db "Constituição. Resiliência quanto a danos físicos", 0
    desc_dex: db "Destreza. Agilidade, coordenacao motora, capacidade de executar movimentos finos", 0
    desc_wis: db "Sabedoria. Prudência e capacidade de raciocínio", 0
    desc_int: db "Inteligência. Capacidade de aprender, entender e aplicar conhecimentos pontuais", 0
    desc_cha: db "Carisma. Habilidade de influenciar as pessoas ao seu redor", 0
    desc_per: db "Percepção. Conhecimento de seus arredores, permitindo melhor navegação pelo ambiente", 0
    att_use_help: db "Digite o nome do atributo e quantos pontos você deseja adicionar : ", 0

section .bss

    ByteBlock: resb 128

section .text

    use_ability_points:
        prolog r14, r12, r9
        mov r12, 21
        whilenonzero r12
            printf 'sis', ability_loop_prompt1, r12, ability_loop_prompt2

            push r15
            call print_attributes
            add rsp, 8
            printf 'cs', 0xA, att_use_help

            scanf rbx, 'si', r14, r9
            mov rsi, r14
            call to_upper
            mov r14, rdi
            multipush r15, r14, r9, r12
            call try_add_attributes
            add rsp, 32

        endwhile

        push r15
        call print_attributes
        add rsp, 8

        epilog





; Essa função inicializa a lista que contém os atributos. O endereço desta lista estará em r15
    init_attributes:
        prolog r14, r13, r12, rsi

        mov r14, att_str
        mov rsi, desc_str
        mov rdi, ByteBlock
        call strcpy
        lea r15, [rdi + 120]
        mov r15, 0
        multipush r14, rdi
        call init_list
        add rsp, 16

        mov r13, att_con
        mov rsi, desc_con
        mov rdi, ByteBlock
        call strcpy
        lea r14, [rdi + 120]
        mov r14, 0
        multipush r15, r13, rdi
        call add_to_list
        add rsp, 24

        mov r13, att_dex
        mov rsi, desc_dex
        mov rdi, ByteBlock
        call strcpy
        lea r14, [rdi + 120]
        mov r14, 0
        multipush r15, r13, rdi
        call add_to_list
        add rsp, 24

        mov r13, att_wis
        mov rsi, desc_wis
        mov rdi, ByteBlock
        call strcpy
        lea r14, [rdi + 120]
        mov r14, 0
        multipush r15, r13, rdi
        call add_to_list
        add rsp, 24

        mov r13, att_int
        mov rsi, desc_int
        mov rdi, ByteBlock
        call strcpy
        lea r14, [rdi + 120]
        mov r14, 0
        multipush r15, r13, rdi
        call add_to_list
        add rsp, 24

        mov r13, att_cha
        mov rsi, desc_cha
        mov rdi, ByteBlock
        call strcpy
        lea r14, [rdi + 120]
        mov r14, 0
        multipush r15, r13, rdi
        call add_to_list
        add rsp, 24

        mov r13, att_per
        mov rsi, desc_per
        mov rdi, ByteBlock
        call strcpy
        lea r14, [rdi + 120]
        mov r14, 0
        multipush r15, r13, rdi
        call add_to_list
        add rsp, 24

        epilog

; Recebe como parâmetro o endereço da lista de atributos, depois imprime cada um dos atributos de acordo com a formatação
; Depois de usar, "rode add rsp, 8" para reposicionar o ponteiro
    print_attributes:
        prolog r15, r14, r13, r11, r9, r8
        mov r15, [rbp + 16]
        print_attributes_loop:

        mov r8, r15
        mov r9, att_str
        call strcmp
        ifzero r11
            printf "s", color_red
        endif

        mov r8, r15
        mov r9, att_con
        call strcmp
        ifzero r11
            printf "s", color_yellow
        endif

        mov r8, r15
        mov r9, att_dex
        call strcmp
        ifzero r11
            printf "s", color_green
        endif

        mov r8, r15
        mov r9, att_wis
        call strcmp
        ifzero r11
            printf "s", color_magenta
        endif

        mov r8, r15
        mov r9, att_int
        call strcmp
        ifzero r11
            printf "s", color_brightcyan
        endif

        mov r8, r15
        mov r9, att_cha
        call strcmp
        ifzero r11
            printf "s", color_brightyellow
        endif

        mov r8, r15
        mov r9, att_per
        call strcmp
        ifzero r11
            printf "s", color_brightblue
        endif

        lea r13, [r15 + ability_desc]
        lea r11, [r15 + ability_value]
        mov r14, [r11]
        printf "sissc", r15, " : ", r14, "/16   ", r13, color_reset, 0xA

        mov r15, [r15 + 192]
        cmp r15, 0
        jne print_attributes_loop

        epilog


; Recebe como parâmetros, nessa ordem, O endereço da lista, as duas strings
; escaneadas, e a quantidade de pontos que ainda podem ser gastos

; Depois de usar, rode "add rsp, 32"
    try_add_attributes:
        prolog r15, r14, r13, r9, r8
        mov r15, [rbp + 40]
        mov r14, [rbp + 32]
        mov r13, [rbp + 24]
        mov r12, [rbp + 16]

        cmp r12, r13
        jl add_att_epilogue
        cmp r13, 16
        jg add_att_epilogue
        cmp r13, -16
        jl add_att_epilogue

        search_att_index:
        mov r8, r15
        mov r9, r14
        call strcmp
        cmp r11, 0
        je valid_att_check
        mov r15, [r15 + 192]
        cmp r15, 0
        je add_att_epilogue
        jmp search_att_index

        valid_att_check:
        cmp r13, 0
        jl dec_attribute
        lea r14, [r15 + 184]
        mov r14, [r14]
        mov r8, r14
        add r8, r13
        cmp r8, 16
        jg add_att_epilogue
        sub r12, r13
        add r14, r13
        mov [r15 + 184], r14
        jmp add_att_epilogue

        dec_attribute:
        neg r13
        lea r14, [r15 + 184]
        mov r14, [r14]
        mov r8, r14
        sub r8, r13
        cmp r8, 0
        jl add_att_epilogue
        add r12, r13
        sub r14, r13
        mov [r15 + 184], r14

        add_att_epilogue:
        epilog

%endif
