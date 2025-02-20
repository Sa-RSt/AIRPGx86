%ifdef TESTING
    global _start
    %define DEBUG 1
%endif
%include "stdlib_macros.asm"
%include "LinkedList.asm"
%include "prompts.asm"
%include "openai.asm"
%include "inventory.asm"

section .data
conversation_field_role: equ 0
conversation_field_content: equ 8
conversation_role_user: db "user", 0
conversation_role_system: db "system", 0
conversation_role_assistant: db "assistant", 0

conversation_empty_index: dq 0, 0, 0, 0, 0, 0, 0, 0  ; 64 bytes zerados

section .bss

conversation_context_list_first_element: resq 1
conversation_garbage: resq 32

section .text

%ifdef TESTING
    _start:
        call openai_init_subprocess

        xor rdi, rdi
        call read_line

        mov r8, rax
        call conversation_elaborate_theme

        mov rdi, r8
        call free
        
        printf 'csc', "Tema elaborado:", 10, rax, 10

        sub rsp, 80
        mov r11, rax
        mov qword [rsp], 100 ; 100 HP
        mov qword [rsp+8], 65  ; 65 STAM
        mov qword [rsp+16], -2  ; -2 LUCK
        mov qword [rsp+24], 1  ; 1 STR
        mov qword [rsp+32], 2  ; 2 CON
        mov qword [rsp+40], 3  ; 3 DEX
        mov qword [rsp+48], 4  ; 4 WIS
        mov qword [rsp+56], 5  ; 5 INT
        mov qword [rsp+64], 6  ; 6 CHA
        mov qword [rsp+72], 7  ; 7 PER
        mov r8, rsp
        lea r9, [rsp+24]
        xor r10, r10
        call _conversation_get_prepend
        mov rsi, rax
        call println

        multipush r15, r14, r13, r12
        xor r15, r15
        mov r14, conversation_role_user
        mov r13, _str_inventory_test_10
        mov r12, conversation_role_assistant
        call inventory_command_give
        mov r10, r15
        multipop r15, r14, r13, r12

        call _conversation_get_prepend
        mov rsi, rax
        call println

        call conversation_initial_description
        mov rsi, rax
        call println

        xor rdi, rdi
        call read_line
        mov r12, rax
        call conversation_player_request
        mov rsi, rax
        call println
        add rsp, 80

        call openai_shutdown_subprocess
        call exit
%endif


; r11 = tema elaborado
; r8 = vetor de 3 i64s (HP, STAM e LUCK)
; r9 = vetor de 7 u64s (STR, CON, DEX, WIS, INT, CHA, PER)
; r10 = endereço do inventário
; rax = (retorno) prepend com tudo preenchido
; IMPORTANTE: o valor retornado por essa função fica na heap e é marcado internamente como "lixo",
; podendo ser liberado a qualquer momento por outras funções de conversation.asm. Por isso, NUNCA dê "free" 
; manualmente nessa string e, caso queira usá-la string no futuro, copie-a para um lugar seguro!
_conversation_get_prepend:
    prolog rcx, rdi, r9, r15, rbx
    mov r15, r10
    call inventory_to_prompt_string  ; gerar string do inventário para injetar no prompt
    mov r15, rax ; string guardada no r15 

    sub rsp, 264  ; reservar espaço para converter ints para strings (160 bytes) e para o vetor para prompt_replace (104 = 8*(12 + 1))
    for rcx, 0, 3  ; converter 3 inteiros de r8 e colocar os resultados nos primeiros 48 bytes de rsp
        mov rdi, rsp
        mov rbx, rcx
        shl rbx, 4  ; multiplicar por 16
        add rdi, rbx  ; rdi = rsp + 16*rcx

        mov rax, [r8 + 8*rcx]
        call itoa
    endfor

    for rcx, 0, 7  ; converter 7 inteiros de r9 e colocar os resultados nos próximos 128 bytes de rsp
        mov rdi, rsp
        mov rbx, rcx
        shl rbx, 4  ; multiplicar por 16
        add rdi, rbx  ; rdi = rsp + 16*rcx + 48
        add rdi, 48

        mov rax, [r9 + 8*rcx]
        call utoa
    endfor

    lea r9, [rsp+160]  ; preparar o vetor a partir do byte 160
    mov [r9], r11  ; primeiro, colocar o tema
    for rcx, 0, 10
        mov rdi, rsp  ; depois, colocar todos os inteiros que foram convertidos para strings
        mov rbx, rcx
        shl rbx, 4  ; multiplicar por 16
        add rdi, rbx  ; rdi = rsp + 16*rcx

        mov [r9 + 8*rcx + 8], rdi
    endfor
    mov [r9+88], r15  ; string do inventário
    mov qword [r9+96], 0  ; terminador (ponteiro nulo)

    mov rdi, prompt_template_prepend
    call prompt_replace
    call _conversation_add_garbage  ; marcar o prepend como lixo, pois deve ser gerado novamente toda vez

    add rsp, 264
    epilog


_conversation_add_garbage:  ; rax = ponteiro para marcar como lixo. uso interno somente
    prolog rcx, r11
    mov rcx, conversation_garbage
    mov r11, [rcx]
    whilenonzero r11  ; buscar um lugar que esteja zerado
        add rcx, 8
        mov r11, [rcx]
    endwhile
    mov [rcx], rax
    epilog


_conversation_clear_garbage:  ; dá free nos ponteiros marcados como lixo. não aceita parâmetros e não retorna valores. uso interno somente
    prolog rcx, rdi
    for rcx, 0, 32
        mov rdi, [conversation_garbage + 8*rcx]
        ifnonzero rdi
            call free
            mov qword [conversation_garbage + 8*rcx], 0
        endif
    endfor
    epilog


; r11 = tema elaborado
; r8 = vetor de 3 i64s (HP, STAM e LUCK)
; r9 = vetor de 7 u64s (STR, CON, DEX, WIS, INT, CHA, PER)
; r10 = endereço do inventário
; rax = (retorno) endereço para a lista encadeada
; IMPORTANTE: o valor retornado por essa função, bem como a string do conteúdo desse valor, fica na 
; heap e é marcado internamente como "lixo", podendo ser liberado a qualquer momento por outras funções
; de conversation.asm. Por isso, NUNCA dê "free" manualmente nesse valor nem na string e, caso queira usá-lo no futuro, copie-o para um lugar seguro!
_conversation_get_context:
    prolog r12, r15, rdi
    mov r12, [conversation_context_list_first_element]
    call _conversation_get_prepend  ; colocar prepend no rax
    sub rsp, 128
    mov rdi, rsp
    mov qword [rdi+conversation_field_role], conversation_role_system
    mov [rdi+conversation_field_content], rax
    multipush conversation_empty_index, rdi  ; passar index (vazio) e info (role + content)
    call init_list
    add rsp, 144  ; 16 a mais para compensar os parâmetros passados pela stack

    mov rax, r15
    mov [rax+field_prox], r12  ; colocar restante da conversa (se existir) após o prepend
    call _conversation_add_garbage  ; marcar elemento da lista do prepend como lixo, pois deve ser gerado novamente toda vez
    epilog

conversation_elaborate_theme:  ; r8 = ponteiro para string com tema digitado pelo usuário, rax = (retorno) tema elaborado
    prolog rdi, r9, rsi
    mov rax, 1
    call openai_write_qword  ; enviar o tamanho do contexto (só uma pergunta)

    mov rdi, prompt_template_elaborate_theme  ; usar prompt de elaborar tema
    sub rsp, 16
    mov r9, rsp
    mov [r9], r8
    mov qword [r9+8], 0  ; vetor terminado em zero com as strings para substituir (só uma nesse caso)
    call prompt_replace  ; substituir placeholders pelo tema fornecido

    mov rsi, conversation_role_user
    call openai_write_string
    mov rsi, rax
    call openai_write_string  ; enviar pergunta à OpenAI com role "user"

    mov rdi, rax
    call free

    call openai_skip_string  ; ler uma string e ignorar ela; deve ser "assistant", mas não importa no final

    call openai_read_string  ; a próxima string lida já é o tema elaborado

    add rsp, 16
    epilog


conversation_context_push:  ; r8 = role string (não será copiado), r9 = conteúdo string (será copiado)
    prolog r15, rdi, rsi, rax

    mov rdi, r9
    call strdup  ; duplicar conteúdo para um novo espaço na heap (apontado por rax)

    sub rsp, 128  ; criar um buffer apontado pelo rdi para colocar as informações para o campo info da lista
    mov rdi, rsp
    mov [rdi+conversation_field_role], r8
    mov [rdi+conversation_field_content], rax

    mov r15, [conversation_context_list_first_element]
    ifzero r15  ; lista não existe -> inicializar
        multipush conversation_empty_index, rdi  ; índice e info
        call init_list
        add rsp, 16
        mov [conversation_context_list_first_element], r15  ; armazenar lista inicializada
    else  ; lista já existe -> adicionar item
        multipush r15, conversation_empty_index, rdi
        call add_to_list
        add rsp, 24
    endif

    add rsp, 128
    epilog


; não aceita argumentos. remove o último item do contexto (sem o prepend) e dá free, se existir
; rdx = (retorno) zero se algum elemento foi removido, não zero se a lista estava vazia
conversation_context_pop:
    prolog r15, r14, r13, rdi
    mov r15, [conversation_context_list_first_element]
    ifzero r15
        mov rdx, 1
    else
        xor rdx, rdx
        xor r13, r13
        mov r14, [r15 + 192]  ; próximo elemento da lista
        whilenonzero r14  ; o elemento é o último da lista quando elemento->prox == NULL. encontrar tal elemento
            mov r13, r15  ; r13 terá o penúltimo elemento
            mov r15, r14
            mov r14, [r15 + 192]  ; próximo elemento da lista
        endwhile
        ifzero r13
            ; se não há um penúltimo elemento, a lista só tem um elemento. desinicializá-la
            mov rdi, [conversation_context_list_first_element]
            call free
            mov qword [conversation_context_list_first_element], 0
        else
            mov rdi, r15
            call free
            mov qword [r13 + 192], 0  ; r13 agora é o último elemento
        endif
    endif
    epilog


; r11 = tema elaborado
; r8 = vetor de 3 i64s (HP, STAM e LUCK)
; r9 = vetor de 7 u64s (STR, CON, DEX, WIS, INT, CHA, PER)
; r10 = endereço do inventário
; rax = (retorno) string com resposta do LLM, ou NULL se o contexto estiver vazio
conversation_context_send_to_openai:
    prolog rsi, r15
    
    xor rax, rax
    mov r15, [conversation_context_list_first_element]
    whilenonzero r15
        inc rax  ; contar quantos elementos existem na lista
        mov r15, [r15+192]  ; próximo elemento da lista
    endwhile

    test rax, rax  ; lista está vazia -> retornar
    jz .return

    add rax, 1  ; +1 pelo prepend
    call openai_write_qword  ; enviar número de elementos para o subprocesso

    call _conversation_get_context  ; contexto inteiro, com o prepend
    mov r15, rax
    whilenonzero r15
        mov rsi, [r15+64]  ; role
        call openai_write_string  ; enviar role para o subprocesso
        mov rsi, [r15+72]  ; content
        call openai_write_string  ; enviar conteúdo para o subprocesso
        mov r15, [r15+192]  ; próximo elemento da lista
    endwhile

    call openai_skip_string  ; lê a role (ignorar)
    call openai_read_string  ; lê o conteúdo e o coloca em rax
    call _conversation_clear_garbage  ; limpa o lixo gerado durante a operação (elemento da lista do prepend e string do prepend)

    .return:
    epilog


; r11 = tema elaborado
; r8 = vetor de 3 i64s (HP, STAM e LUCK)
; r9 = vetor de 7 u64s (STR, CON, DEX, WIS, INT, CHA, PER)
; r10 = endereço do inventário
; rax = (retorno) string com a descrição inicial
conversation_initial_description:
    prolog rdi, r14, r13

    mov r14, r9  ; salvar argumentos temporariamente no r13 e r14
    mov r13, r8

    sub rsp, 8
    mov r9, rsp
    mov qword [r9], 0  ; o template da descrição inicial não aceita parâmetros -> passar vetor vazio
    mov rdi, prompt_template_initial_description
    call prompt_replace  ; agora rax tem o prompt de descrição inicial
    add rsp, 8

    mov r8, conversation_role_user
    mov r9, rax
    mov rdi, rax
    call conversation_context_push  ; colocar prompt da descrição inicial no contexto
    call free  ; liberar memória, já que a string foi copiada pelo conversation_context_push

    mov r9, r14  ; restaurar argumentos para o conversation_context_send_to_openai
    mov r8, r13

    call conversation_context_send_to_openai  ; solicitar descrição inicial ao LLM (será armazenada no rax)
    mov r8, conversation_role_assistant
    mov r9, rax
    call conversation_context_push  ; adicionar descrição inicial ao contexto

    mov r9, r14  ; restaurar argumentos para manter r8 e r9 preservados
    mov r8, r13

    epilog


; r11 = tema elaborado
; r8 = vetor de 3 i64s (HP, STAM e LUCK)
; r9 = vetor de 7 u64s (STR, CON, DEX, WIS, INT, CHA, PER)
; r10 = endereço do inventário
; r12 = pedido do jogador
; rax = (retorno) string com a resposta do LLM que contém pedidos de rolagem de dados
conversation_player_request:
    prolog rdi, r13, r14, r15, rdx
    mov r14, r9
    mov r13, r8  ; preservar argumentos

    sub rsp, 16
    mov r9, rsp
    mov [r9], r12  ; vetor na stack com o pedido do jogador e um ponteiro nulo para indicar o fim do vetor
    mov qword [r9+8], 0
    mov rdi, prompt_template_viability
    call prompt_replace
    add rsp, 16
    
    mov r8, conversation_role_user
    mov r9, rax
    mov rdi, rax
    call conversation_context_push  ; colocar pedido análise de viabilidade no contexto
    call free  ; liberar cópia desnecessária da string

    mov r9, r14  ; restaurar argumentos para o conversation_context_send_to_openai
    mov r8, r13
    call conversation_context_send_to_openai
    mov r15, rax  ; salvar resposta no r15

    sub rsp, 24
    mov r9, rsp
    mov [r9], r12  ; preparar vetor na stack com pedido do jogador e a análise feita pelo LLM
    mov [r9+8], r15
    mov qword [r9+16], 0
    mov rdi, prompt_template_request_with_viability
    call prompt_replace
    add rsp, 24

    mov rdi, r15  ; string já foi copiada, não é mais necessária
    call free

    call conversation_context_pop  ; retirar pedido de análise de viabilidade do contexto

    mov r8, conversation_role_user
    mov r9, rax
    mov rdi, rax
    call conversation_context_push  ; colocar request com viabilidade analisada no contexto
    call free  ; liberar cópia desnecessária da string

    mov r9, r14  ; restaurar argumentos para o conversation_context_send_to_openai
    mov r8, r13
    call conversation_context_send_to_openai

    epilog
