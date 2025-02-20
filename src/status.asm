%ifndef STATUS_INC
%define STATUS_INC 1

%ifdef TESTING
    %define DEBUG 1
%endif
%include "stdlib_macros.asm"
%include "LinkedList.asm"
%include "color.asm"

section .data

status_str_HP: db "HP", 0
status_str_pontos_de_saude: db "Pontos de Saúde", 0
status_str_STAM: db "STAM", 0
status_str_vigor: db "Vigor", 0
status_str_LUCK: db "LUCK", 0
status_str_sorte: db "Sorte", 0
status_str_add: db "add", 0
status_str_subtract: db "subtract", 0
status_str_progbar_start: db " [", 0
status_str_progbar_end: db "]", 0

times 8 dq 0  ; 64 bytes de padding para cópia do index

section .bss

section .text

status_init_list:  ; r15 = (retorno) lista inicializada com os status padrões
    prolog rdi, rsi
    sub rsp, 128  ; bloco de info da lista (128 bytes)
    mov rdi, rsp
    mov rsi, status_str_pontos_de_saude  ; copiar nome human readable para os primeiros bytes
    call strcpy
    mov qword [rdi+120], 100  ; inicializar com 100 HP nos últimos bytes
    mov qword [rdi+112], 100  ; valor máximo
    mov qword [rdi+104], 0  ; valor mínimo
    multipush status_str_HP, rdi
    call init_list
    add rsp, 16

    mov rsi, status_str_vigor  ; fazer a mesma coisa para os dois outros status
    call strcpy
    mov qword [rdi+120], 100
    mov qword [rdi+112], 100  ; valor máximo
    mov qword [rdi+104], 0  ; valor mínimo
    multipush r15, status_str_STAM, rdi
    call add_to_list
    add rsp, 24

    mov rsi, status_str_sorte  ; fazer a mesma coisa para os dois outros status
    call strcpy
    mov qword [rdi+120], 0
    mov qword [rdi+112], 2147483647  ; valor máximo
    mov qword [rdi+104], -2147483648  ; valor mínimo
    multipush r15, status_str_LUCK, rdi
    call add_to_list
    add rsp, 24
    add rsp, 128

    epilog


status_update:  ; r15 = lista de status, r14 = código do status (string HP, STAM ou LUCK), r13 = valor para somar (i64)
    prolog r15, r10, r8, r9
    multipush r15, r14
    call list_index_search  ; buscar pelo índice fornecido
    add rsp, 16
    if ne, r15, -1  ; executar somente se o elemento existir
        mov r10, [r15+184]  ; ler valor atual do status
        mov r9, [r15+176]  ; ler valor máximo
        mov r8, [r15+168]  ; ler valor mínimo
        add r10, r13  ; atualizar
        if g, r10, r9
            mov r10, r9
        elif l, r10, r8
            mov r10, r8
        endif
        mov [r15+184], r10  ; guardar novo valor
    endif
    
    epilog


status_update_command:  ; r15 = lista de status, r14 = código do status (string HP, STAM ou LUCK), rsi = valor para atualizar (string), r8 = "add" ou "subtract" (string)
    prolog r9, r11, rax, r13
    call atou  ; colocar em rax o inteiro correspondente à string de rsi
    mov r13, rax
    
    mov r9, status_str_subtract
    call strcmp
    ifzero r11  ; se operação == "subtract"
        neg r13  ; inverter o sinal do número
    else
        mov r9, status_str_add
        call strcmp
        test r11, r11
        jnz .return  ; se não for subtract nem add, ignorar o comando
    endif

    call status_update
    
    .return:
    epilog


status_values_array:  ; r15 = lista de status, r8 = ponteiro para onde será colocado o vetor de i64s (na ordem da lista)
    prolog r15, r8, rbx
    whilenonzero r15
        mov rbx, [r15 + 184]  ; ler valor do status
        mov [r8], rbx  ; transferir o valor para o vetor
        mov r15, [r15 + 192]  ; próximo elemento da lista
        add r8, 8
    endwhile
    epilog


; rdi = buffer para escrever a progress bar
; rdi = (retorno) posição do final da progress bar
; rbx = valor (de zero a 100)
; r10 = cor da barra de progresso
_status_make_progress_bar:
    prolog rbx, rcx, rsi, rax
    mov rax, rbx  ; rax = valor cheio
    shr rbx, 1  ; rbx = valor dividido por 2

    mov rsi, color_reset  ; colocar sequência de color reset no buffer
    call strcpy
    call strend

    mov rsi, color_faint
    call strcpy
    call strend

    mov rsi, status_str_progbar_start
    call strcpy
    call strend

    mov rsi, color_reset
    call strcpy
    call strend

    mov rsi, r10  ; colocar cor definida pelo caller
    call strcpy
    call strend

    for rcx, 0, rbx  ; para rcx de zero até o valor
        mov byte [rdi], '#'  ; preencher com '=' para formar a barra de progresso
        inc rdi
    endfor

    mov rcx, 50
    sub rcx, rbx
    mov rbx, rcx  ; rbx = 50 - rbx
    for rcx, 0, rbx  ; para rcx de zero até 50 - valor
        mov byte [rdi], ' '  ; preencher com ' ' para formar o espaço vazio da barra de progresso
        inc rdi
    endfor

    mov rsi, color_reset
    call strcpy
    call strend

    mov rsi, color_faint
    call strcpy
    call strend

    mov rsi, status_str_progbar_end
    call strcpy
    call strend

    mov rsi, color_reset
    call strcpy
    call strend

    mov byte [rdi], ' '
    inc rdi

    mov byte [rdi], ' '
    inc rdi

    mov rsi, r10
    call strcpy
    call strend

    call utoa  ; coloca o valor de rax (o valor cheio) em rdi
    call strend

    mov rsi, color_reset
    call strcpy
    call strend

    mov rsi, color_faint
    call strcpy
    call strend

    mov byte [rdi], ' '
    inc rdi

    mov byte [rdi], '%'
    inc rdi

    mov byte [rdi], 10
    inc rdi

    mov rsi, color_reset
    call strcpy
    call strend

    epilog


print_status:  ; r15 = lista de status
    prolog r8, rdi, r9, rsi, rbx, rcx
    sub rsp, 1024
    mov r8, rsp
    call status_values_array  ; colocar valores dos status no vetor da stack para acesso

    mov rdi, status_str_pontos_de_saude
    mov rsi, status_str_pontos_de_saude
    call strend
    sub rdi, rsi
    mov r9, rdi  ; r9 agora tem o tamanho da string "Pontos de Saúde"

    lea rdi, [rsp+18]  ; formar string para ser impressa a partir do byte 18 (LUCK será ignorado)
    mov rsi, color_by_id_46
    call strcpy  ; copiar cor magenta para o buffer a ser impresso
    call strend  ; colocar rdi no final da string atual, para fins de concatenação

    mov rsi, color_standout
    call strcpy
    call strend

    mov rsi, status_str_pontos_de_saude
    call strcpy
    call strend

    mov byte [rdi], ' '  ; adicionar um espaço
    inc rdi

    mov rbx, [r8]  ; rbx = HP (0 a 100)
    mov r10, color_by_id_46
    call _status_make_progress_bar

    mov r10, rdi  ; preservar rdi
    mov rdi, status_str_vigor
    mov rsi, status_str_vigor
    call strend
    sub rdi, rsi
    sub r9, rdi  ; r9 agora tem a diferença entre os tamanhos das strings dos nomes dos status
    mov rdi, r10  ; restaurar rdi

    mov rsi, color_by_id_220
    call strcpy
    call strend

    mov rsi, color_standout
    call strcpy
    call strend

    mov rsi, status_str_vigor
    call strcpy
    call strend

    for rcx, 0, r9
        mov byte [rdi], ' '  ; colocar espaços para alinhar as barras de progresso com base nos tamanhos das strings
        inc rdi
    endfor

    mov rbx, [r8 + 8]  ; rbx = STAM (0 a 100)
    mov r10, color_by_id_220
    call _status_make_progress_bar

    lea rsi, [rsp+18]
    call print  ; imprimir a string formada

    add rsp, 1024
    epilog


%ifdef TESTING
    section .data

    _str_status_test_25: db "25", 0

    section .text
    _start:
        call status_init_list
        mov r14, status_str_HP
        mov r13, -7
        call status_update

        mov r14, status_str_STAM
        mov r13, -17
        call status_update

        call print_status

        call status_update

        call print_status

        call status_update

        call print_status
        call status_update

        call print_status
        call status_update

        call print_status
        call status_update

        call print_status
        call status_update

        call print_status
        call status_update

        call print_status
        mov r13, 999999
        call status_update
        call print_status

        mov r8, status_str_subtract
        mov rsi, _str_status_test_25
        call status_update_command
        call print_status
        mov r8, status_str_add
        call status_update_command
        call print_status

        call exit
%endif

%endif
