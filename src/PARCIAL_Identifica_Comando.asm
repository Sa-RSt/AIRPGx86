section .data
    msg_teste db "123[roll DEX]123[roll PER] [update LUCK add 1]e entao [roll advantage CHA] logo[roll advantage 10] [update STAM subtract 2] por fim [roll CON] bla bla [roll disadvantage PER] e [roll disadvantage 14], montanha do Sul Grande [roll 12 243], um troll [roll disadvantage 45] e caiu [update HP subtract 12] e ganhou [take bolacha doce | 12] dia de sol [roll advantage DEX] e deu algo [give montanha | 12 | Montanha de brinquedo]", 0
    msg_controle_comando db "roll", 10, "update", 10, "take", 10, "give", 10, 0
    msg_controle_atributos db "STR", 10, "CON", 10, "DEX", 10, "WIS", 10, "INT", 10, "CHA", 10, "PER", 10, 0
    msg_controle_vantagem_desvantagem db "advantage", 10, "disadvantage", 10, 0
    msg_controle_estado db "HP", 10, "STAM", 10, "LUCK", 10, 0
    msg_controle_operacao_estado db "add", 10, "subtract", 10, 0
    msg_STR db "STR", 0
    msg_CON db "CON", 0
    msg_DEX db "DEX", 0
    msg_WIS db "WIS", 0
    msg_INT db "INT", 0
    msg_CHA db "CHA", 0
    msg_PER db "PER", 0

section .bss

section .text
    %define DEBUG 1
    %include "stdlib_macros.asm"           ; Inclui o arquivo de macros
    global _start

_start:
    lea rsi, msg_teste
    call executa_comandos
    call exit

; (rax, rbx, rdi, rsi, r12, r13, r14)
; Recebe o endereço da mensagem em rsi
executa_comandos:
    call verifica_tamanho   ; Recebe o tamanho em rbx
    

    push rsi
    mov rsi, rbx
    call malloc             ; Tamanho em rsi, retorno em rax
    mov rdi, rax            ; Endereço criado passa a estar com rdi
    pop rsi

    multipush rdi, rsi, rbx
    .busca_comando:
        ; Verifica o caractere de rsi
        mov al, [rsi]
        cmp al, 0
        je .final
        cmp al, '['
        je .prepara_verifica_comando

        ; Avança para o próximo caractere
        mov byte [rdi], al
        inc rsi
        inc rdi

        jmp .busca_comando

        ; Ajusta a posição de rsi para apontar par ao inicio do comando
        .prepara_verifica_comando:
            inc rsi
            jmp .verifica_comando

    .verifica_comando:
        ; Verifica o caractere de dentro do colchete

        push rdi

        lea rdi, msg_controle_comando
        call identifica_comando     ; Retorna inteiro em r12: | -1 = erro | 0 = roll | 1 = update | 2 = take | 3 = give |
        inc rsi                     ; Avança para o caractere após o espaço

        cmp r12, -1
        je .erro_comando
        cmp r12, 0
        je .roll
        cmp r12, 1
        je .update
        cmp r12, 2
        je .take
        cmp r12, 3
        je .give

        .roll:
            print_literal "Roll "
            push rsi                    ; Guarda a posição que começa a verificar

            ; Verifica se é um comando do tipo 1
            ; ------------------------------------------------------------------------
            lea rdi, msg_controle_atributos
            call identifica_comando     ; Retorna inteiro em r12: | -1 = não achou | 0 = STR | 1 = CON | 2 = DEX | 3 = WIS | 4 = INT | 5 = CHA | 6 = PER |

            cmp r12, -1
            je .proximo1
            cmp r12, 0
            je .roll_STR
            cmp r12, 1
            je .roll_CON
            cmp r12, 2
            je .roll_DEX
            cmp r12, 3
            je .roll_WIS
            cmp r12, 4
            je .roll_INT
            cmp r12, 5
            je .roll_CHA
            cmp r12, 6
            je .roll_PER

            .roll_STR:
                print_literal "STR", 0x0A
                jmp .prepara_busca_comando1
            .roll_CON:
                print_literal "CON", 0x0A
                jmp .prepara_busca_comando1
            .roll_DEX:
                print_literal "DEX", 0x0A
                jmp .prepara_busca_comando1
            .roll_WIS:
                print_literal "WIS", 0x0A
                jmp .prepara_busca_comando1
            .roll_INT:
                print_literal "INT", 0x0A
                jmp .prepara_busca_comando1
            .roll_CHA:
                print_literal "CHA", 0x0A
                jmp .prepara_busca_comando1
            .roll_PER:
                print_literal "PER", 0x0A
                jmp .prepara_busca_comando1

            ; FIM TIPO 1

            ; Verifica se é um comando tipo ou 2 e 4 (advantage) ou 3 e 5 (disadvantage)
            ; --------------------------------------------------------------------------
            .proximo1:
            ; Recupera a posição de rsi e guarda de novo
            pop rsi
            push rsi

            lea rdi, msg_controle_vantagem_desvantagem
            call identifica_comando         ; Retorna inteiro em r12: | -1 = não achou | 0 = advantage | 1 = disadvantage |

            cmp r12, -1
            je .proximo2                    ; Verifica se é do formato 6 [roll N M]
            cmp r12, 0
            je .roll_advantage
            cmp r12, 1
            je .roll_disadvantage

            ; Comando do tipo 2 ou 4
            .roll_advantage:
                print_literal "advantage "
                inc rsi                         ; Aponta para o caractere após o espaço
                push rsi
                
                ; Verifica se é do tipo 2
                ; ---------------------------------------------------------------------
                lea rdi, msg_controle_atributos
                call identifica_comando         ; Retorna em r12 o número do atributo (mesmo da linha 80)

                cmp r12, -1
                je .proximo1_1                  ; Verifica se é tipo 4
                cmp r12, 0
                je .roll_advantage_STR
                cmp r12, 1
                je .roll_advantage_CON
                cmp r12, 2
                je .roll_advantage_DEX
                cmp r12, 3
                je .roll_advantage_WIS
                cmp r12, 4
                je .roll_advantage_INT
                cmp r12, 5
                je .roll_advantage_CHA
                cmp r12, 6
                je .roll_advantage_PER

                .roll_advantage_STR:
                    print_literal "STR", 0x0A
                    jmp .prepara_busca_comando2
                .roll_advantage_CON:
                    print_literal "CON", 0x0A
                    jmp .prepara_busca_comando2
                .roll_advantage_DEX:
                    print_literal "DEX", 0x0A
                    jmp .prepara_busca_comando2
                .roll_advantage_WIS:
                    print_literal "WIS", 0x0A
                    jmp .prepara_busca_comando2
                .roll_advantage_INT:
                    print_literal "INT", 0x0A
                    jmp .prepara_busca_comando2
                .roll_advantage_CHA:
                    print_literal "CHA", 0x0A
                    jmp .prepara_busca_comando2
                .roll_advantage_PER:
                    print_literal "PER", 0x0A
                    jmp .prepara_busca_comando2

                ; FIM DO TIPO 2

                .proximo1_1:
                ; Verifica se é do tipo 4
                ; ------------------------------------------------------------------
                ; Recupera e guarda rsi
                pop rsi
                push rsi

                call identifica_numero          ; r12 guarda o número solicitado

                cmp r12, -1 
                je .erro_comando2
                jne .roll_advantage_M

                .roll_advantage_M:
                    printf "ic", r12, 0x0A
                    jmp .prepara_busca_comando2

                ; FIM DO TIPO 4

            ; Comando do tipo 3 ou 5
            .roll_disadvantage:
                print_literal "disadvantage "
                inc rsi                     ; Aponta para o caractere após o espaço
                push rsi
                
                ; Verifica se é do tipo 3
                ; ---------------------------------------------------------------------
                lea rdi, msg_controle_atributos
                call identifica_comando         ; Retorna em r12 o número do atributo (mesmo da linha 80)

                cmp r12, -1
                je .proximo1_2                  ; Verifica se é tipo 5
                cmp r12, 0
                je .roll_disadvantage_STR
                cmp r12, 1
                je .roll_disadvantage_CON
                cmp r12, 2
                je .roll_disadvantage_DEX
                cmp r12, 3
                je .roll_disadvantage_WIS
                cmp r12, 4
                je .roll_disadvantage_INT
                cmp r12, 5
                je .roll_disadvantage_CHA
                cmp r12, 6
                je .roll_disadvantage_PER

                .roll_disadvantage_STR:
                    print_literal "STR", 0x0A
                    jmp .prepara_busca_comando2
                .roll_disadvantage_CON:
                    print_literal "CON", 0x0A
                    jmp .prepara_busca_comando2
                .roll_disadvantage_DEX:
                    print_literal "DEX", 0x0A
                    jmp .prepara_busca_comando2
                .roll_disadvantage_WIS:
                    print_literal "WIS", 0x0A
                    jmp .prepara_busca_comando2
                .roll_disadvantage_INT:
                    print_literal "INT", 0x0A
                    jmp .prepara_busca_comando2
                .roll_disadvantage_CHA:
                    print_literal "CHA", 0x0A
                    jmp .prepara_busca_comando2
                .roll_disadvantage_PER:
                    print_literal "PER", 0x0A
                    jmp .prepara_busca_comando2

                ; FIM DO TIPO 3

                .proximo1_2:
                ; Verifica se é do tipo 5
                ; ------------------------------------------------------------------
                ; Recupera e guarda rsi
                pop rsi
                push rsi

                call identifica_numero          ; r12 guarda o número solicitado

                cmp r12, -1 
                je .erro_comando2
                jne .roll_disadvantage_M

                .roll_disadvantage_M:
                    printf "ic", r12, 0x0A
                    jmp .prepara_busca_comando2

                ; FIM DO TIPO 5

            ; FIM COMANDOS 2, 3, 4 E 5

            ; Verifica se é do tipo 6
            ; ------------------------------------------------------------------
            .proximo2:
                ; Recupera e guarda o valor de rsi
                pop rsi
                push rsi

                call identifica_numero          ; r12 guarda o número

                ; Caso não seja um número
                cmp r12, -1
                je .erro_comando1
                jne .busca_M 

                .busca_M:
                    printf "i", r12, " "
                    mov r13, r12                ; Deixa r13 com o valor de N (número de dados)

                    inc rsi                     ; Faz rsi apontar para o próximo número
                    call identifica_numero      ; r12 recebe o valor
                    
                    cmp r12, -1
                    je .erro_comando1
                    jne .roll_N_M 

                .roll_N_M:
                    printf "ic", r12, 0x0A            ; r12 contém o valor de M
                    jmp .prepara_busca_comando1
                
        ; FIM ROLL --------------------------------------------------------------

        .update:
            print_literal "Update "
            ; Não precisa de push pois verifica todos os possíveis casos de uma vez

            ; Verifica qual status vai mudar
            lea rdi, msg_controle_estado
            call identifica_comando     ; Retorna inteiro em r12: | -1 = erro | 0 = HP | 1 = STAM | 2 = LUCK |
            cmp r12, -1
            je .erro_comando

            mov r13, r12            ; Guarda qual status vai mudar em r13   
            inc rsi                 ; Aponta rsi para o início da operação

            ; Verifica a operação
            lea rdi, msg_controle_operacao_estado
            call identifica_comando     ; Retorna inteiro em r12> | -1 = erro | 0 = add | 1 = subtract |
            cmp r12, -1
            je .erro_comando

            mov r14, r12            ; Guarda a operação em r14
            inc rsi                 ; Aponta para a quantidade

            ; Verifica o valor da mudança
            call identifica_numero      ; Retorna em r12 quanto deve ser a operação

            cmp r13, 0
            je .update_HP
            cmp r13, 1
            je .update_STAM
            cmp r13, 2
            je .update_LUCK

            .update_HP:
                print_literal "HP "

                ; Verifica operação
                cmp r14, 0
                je .update_HP_add
                cmp r14, 1
                je .update_HP_subtract
            
            .update_STAM:
                print_literal "STAM "

                ; Verifica operação
                cmp r14, 0
                je .update_STAM_add
                cmp r14, 1
                je .update_STAM_subtract

            .update_LUCK:
                print_literal "LUCK "

                ; Verifica operação
                cmp r14, 0
                je .update_LUCK_add
                cmp r14, 1
                je .update_LUCK_subtract

            .update_HP_add:
                printf "ic", "add ", r12, 0x0A
                jmp .prepara_busca_comando
            .update_HP_subtract:
                printf "ic", "subtract ", r12, 0x0A
                jmp .prepara_busca_comando
            .update_STAM_add:
                printf "ic", "add ", r12, 0x0A
                jmp .prepara_busca_comando
            .update_STAM_subtract:
                printf "ic", "subtract ", r12, 0x0A
                jmp .prepara_busca_comando
            .update_LUCK_add:
                printf "ic", "add ", r12, 0x0A
                jmp .prepara_busca_comando
            .update_LUCK_subtract:
                printf "ic", "subtract ", r12, 0x0A
                jmp .prepara_busca_comando

        ; FIM UPDATE ---------------------------------------------------------------------------

        .take:
            print_literal "Take "
            call le_string              ; rsi aponta para o inicio da mensagem, rax aponta para o inicio, rbx contém o tamanho
            
            push rsi
            mov rsi, rax
            call escreve_buffer         ; rax aponta para o início do buffer, tamanho em rbx
            pop rsi

            mov r13, rax                 ; Guarda o endereço do item
            mov r14, rbx                ; Guarda o tamamnho do item

            add rsi, 3                  ; Aponta rsi para o inicio do número

            call identifica_numero      ; Retorna o valor em r12
            printf "ic", " ", r12, 0x0A

            cmp r12, -1
            je .erro_comando

            ; RESUMO: r13 - nome do item | r14 - tamanho do nome do item | r12 - Quantidade de itens

            ; Libera memória nome
            push rdi
            mov rdi, r13
            call free
            pop rdi

            jmp .prepara_busca_comando

        ; FIM TAKE ------------------------------------------------------------------------------------

        .give:
            print_literal "Give "
            call le_string              ; rsi aponta para o inicio da mensagem, rax aponta para o inicio, rbx contém o tamanho
            push rsi
            mov rsi, rax
            call escreve_buffer         ; rax aponta para o início do buffer, tamanho em rbx
            pop rsi

            mov r13, rax                ; Guarda o endereço do item
            mov r14, rbx                ; Guarda o tamamnho do item
            add rsi, 3                  ; Aponta rsi para o inicio do número

            call identifica_numero      ; Retorna o valor em r12
            printf "ic", " ", r12, " "

            cmp r12, -1
            je .erro_comando

            add rsi, 3                  ; Aponta rsi para o início da descrição
            call le_string              ; rsi aponta para o inicio da mensagem, rax aponta para o inicio, rbx contém o tamanho
            push rsi
            mov rsi, rax
            call escreve_buffer         ; rax aponta para o início do buffer, tamanho em rbx
            pop rsi

            ; RESUMO: r13 - nome do item | r14 - tamanho do nome do item | r12 - Quantidade de itens | rax - Descrição do item | rbx - Tamanho da descrição do item

            ; Libera memória nome
            push rdi
            mov rdi, r13
            call free
            pop rdi

            ; Libera memória descrição
            push rdi
            mov rdi, rax
            call free
            pop rdi

            jmp .prepara_busca_comando


    ; Encontrou o comando --------------------------------------------
    ; Tem três desses pois dependendo do trecho, se usa mais ou menos push

    .prepara_busca_comando2:
        pop rdi                 ; Descarta o valor guardado de rsi (linha ~142 / ~203)
        jmp .prepara_busca_comando1

    .prepara_busca_comando1:
        pop rdi                 ; Descarta o valor guardado de rsi (linha ~75)
        jmp .prepara_busca_comando

    .prepara_busca_comando:
        pop rdi                 ; Recupera o valor de rdi (linha ~56)
        inc rsi                 ; Próximo do ']'
        jmp .busca_comando

    ; Erros----------------------------

    .erro_comando2:
        pop rdi                 ; Descarta o valor guardado de rsi (linha ~142 / ~203)
        jmp .erro_comando1

    .erro_comando1:
        pop rdi                 ; Descarta o push (linha ~75)
        jmp .erro_comando

    .erro_comando:
        pop rdi                 ; Descarta o push (linha ~56)
        print_literal "Comando inválido", 0x0A
        jmp .final

    ; Finalização -------------------------

    .final:
        multipop rdi, rsi, rbx
        print_literal 0x0A
        call escreve_buffer
        print_literal 0x0A
        push rsi
        mov rsi, rdi
        call escreve_buffer
        print_literal 0x0A
        pop rsi
        call free               ; Libera a memória alocada dinamicantente em rdi
        ret

; Verifica o tamanho de uma string (rax, rbx, rsi)
; Entra com endereço do buffer em rsi, volta tamanho em rbx
verifica_tamanho:
    multipush rax, rsi    ; Preserva o valor
    
    mov rbx, 0

    .loop:
        mov al, [rsi]
        cmp al, 0
        je .end

        inc rbx
        inc rsi
        jmp .loop

    .end:
        multipop rax, rsi
        ret

; Escreve o conteúdo apontado por um registrador (rax, rbx, rdi)
; Recebe o endereço por rsi e o tamanho em rbx
escreve_buffer:
    multipush rax, rdx, rdi
    mov rax, 1     ; syscall: sys_write
    mov rdi, 1     ; stdout
    mov rdx, rbx   ; tamanho da string
    syscall
    multipop rax, rdx, rdi
    ret

; Verifica qual comando deve ser executado (rax, rbx, rdi, rsi, r12)
; Recebe o endereço de controle em rdi (não preserva original). Recebe a mensagem a verificar em rsi (não preserva original). Retorna o indice do comando em r12
identifica_comando:
    ; rdi aponta para o buffer de controle
    ; rsi aponta para a mensagem
    multipush rax, rbx
    push rsi
    mov r12, 0                                      ; Usado para definir o comando ao final

    .current_command:
        ; Caso chegue ao valor 10 significa que todos os caracteres são iguais
        ; Sendo preciso apenas verificar se a entrada do usuário chegou ao fim
        cmp byte [rdi], 10
        jnz .continua

        cmp byte [rsi], " "
        jz .found
        cmp byte [rsi], "]"
        jz .found

        .continua:
        ; Caso um caractere seja diferente, verifica o próximo comando
        mov al, [rdi]
        mov bl, [rsi]
        ;printf "ccc", bl, al, 0x0A
        cmp byte al, bl
        jnz .next_command

        ; Caso seja igual, avalia o próximo caractere
        inc rdi
        inc rsi
        jmp .current_command

    .next_command:
        ; Faz rdi apontar para o próximo valor 10
        .loop:
            inc rdi
            cmp byte [rdi], 10
            jnz .loop
        
        ; Faz rdi apontar para o início do próximo comando
        inc rdi

        ; Se for 0, significa que não é nenhum comando válido
        cmp byte [rdi], 0
        jz .not_found

        ; Recupera o valor de rsi e guarda de novo
        pop rsi
        push rsi

        ; Aumenta o indice do retorno
        inc r12
        jmp .current_command

    .found:
        pop rbx                 ; Descarta o valor antigo de rsi
        multipop rax, rbx
        ret

    .not_found:
        pop rbx                 ; Descarta o valor antigo de rsi
        multipop rax, rbx
        mov r12, -1
        ret
; Identifica o número em um endereço apontado (rcx, rsi, r12)
; rsi aponta para o endereço (não preserva original)    . Retorna o número em r12. Em caso de erro retorna -1
identifica_numero:
    multipush rcx
    mov r12, 0
    
    .loop:
        mov cl, byte[rsi]
        inc rsi

        ; Caso chegou ao fim
        cmp cl, " "
        je .fim
        cmp cl, "]"
        je .fim

        ; Verifica caso não seja um número
        cmp cl, '0'
        jl .erro
        cmp cl, '9'
        jg .erro
        
        sub cl, '0'                             ; Traduz o valor para um número inteiro
        imul r12, 10                            ; Multiplica o resultado parcial por 10
        add r12, rcx                             ; Soma o valor de cl para r12
        jmp .loop                               ; Repete até encontrar um byte inválido

    .erro:
        multipop rcx
        mov r12, -1
        ret

    .fim:
        dec rsi         ; Aponta para a o caractere de parada " " ou "]"
        multipop rcx
        ret

; Lê uma string até encontrar '|' ou ']' (rax, rbx, rcx, rsi)
; rsi aponta para a string (não preserva original). Retorna em um buffer alocado dinamicamente em rax e o tamanho em rbx
le_string:
    multipush rcx
    ; Verifica o tamanho da string até "|" ou "]"
    mov rbx, 0
    push rsi
    .loop_tamanho:
        mov cl, byte [rsi]
        cmp cl, "|"
        je .continua
        cmp cl, ']'
        je .continua_colchete
        cmp cl, 0
        je .continua_colchete

        inc rbx
        inc rsi
        jmp .loop_tamanho
    
    .continua_colchete:
        inc rbx                 ; Aumenta um byte para guardar o valor 0
        jmp .continua

    .continua:
        mov rsi, rbx
        call malloc             ; Tamanho em rsi, retorna o buffer em rax
        pop rsi                 ; Recupera a posição original de rsi

        push rax                ; Guarda a posição orginal de rax
        push rbx                ; Guarda o tamanho em rbx

    .loop_escrita:
        ; Verifica se chegou ao final
        cmp rbx, 1
        je .fim

        mov cl, byte [rsi]
        mov byte [rax], cl

        inc rsi
        inc rax
        dec rbx

        jmp .loop_escrita
    
    .fim:
        inc rax
        mov byte[rax], 0        ; Adiciona o terminador 0 ao final

        pop rbx                 ; Recupera o tamanho
        pop rax                 ; Recupera a posição inicial
        multipop rcx            ; Recupera o valor de rbx e rcx
        ret