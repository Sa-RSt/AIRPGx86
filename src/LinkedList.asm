%define DEBUG 1
global _start

%ifdef TESTING
    %define DEBUG 1
    global _start
%endif
%include "stdlib_macros.asm"

section .data

    ; Relacionado a struct das listas
    field_index: equ 0
    field_info: equ 64
    field_prox: equ 192

section .bss

    list_address: resb 8
    index_bytes: resb 64
    info_bytes: resb 128

section .text

    _start:
        scanf rbx, 'ss', r8, r9
        multipush r8, r9
        call init_list
        add rsp, 16
        scanf rbx, 'ss', r8, r9
        mov r10, r8
        multipush r15, r8, r9
        call add_to_list
        add rsp, 24
        scanf rbx, 'ss', r8, r9
        multipush r15, r8, r9
        call add_to_list
        add rsp, 24
        mov r14, r15
        jmp yay

    yay:
        multipush r15, r10
        call list_index_search
        add rsp, 16
        multipush r15, r10
        call is_node
        add rsp, 16
        call exit





; Essa função cria uma nova lista e adiciona um primeiro elemento nela. O endereço da nova
; lista vai estar em r15

; São necessárias duas informações na stack : índice do nó / informação do nó

; Após usar essa função execute "add rsp, 16" para liberar 2 registradores de espaço na stack
    init_list:
        prolog rsi, rax, r14, r13
        mov rsi, 200 ; 200 bytes necessários para o nó
        call malloc
        mov r15, rax ; r15 vai conter o endereço da nova lista
        mov r14, [rbp + 24] ; Busca o índice do nó
        mov r13, [rbp + 16] ; Busca a informação do nó
        mov qword [r15 + 192], 0 ; Faz "newnode->prox = NULL"

        mov rax, 0
        init_index_loop: ; Adiciona o index no nó
        mov esi, [r14 + 4 * rax]
        mov dword[r15 + 4 * rax], esi
        inc rax
        cmp rax, 16
        jl init_index_loop

        mov rax, 0
        init_info_loop: ; Adiciona a informação no nó
        mov esi, [r13 + 4 * rax]
        mov dword [r15 + 64 + 4 * rax], esi
        inc rax
        cmp rax, 32
        jl init_info_loop

        epilog ; r15 agora contém o primeiro nó da nova lista





; Essa função assume que a lista posssui pelo menos um elemento. Para criar uma nova lista
; veja a função init_list

; Adicionar algo na lista com essa função leva em consideração que três informações
; foram passadas pra stack nessa ordem : endereço da lista / índice do nó / informação do nó

; Após usar essa função execute "add rsp, 24" para liberar 3 registradores de espaço na stack
    add_to_list:
        prolog rsi, r15, rax, r12, r13, r14
        mov rsi, 200 ; 200 bytes necessários para cada nó
        call malloc
        mov r15, rax ; Guarda o endereço do novo nó para uso posterior
        mov r14, [rbp + 32] ; Busca o endereço da lista
        mov r13, [rbp + 24] ; Busca o índice do nó
        mov r12, [rbp + 16] ; Busca a informação do nó
        mov rsi, 0
        mov qword [r15 + 192], 0 ; Faz "newnode->prox = NULL"

        mov rax, 0
        add_index_loop: ; Adiciona o index no novo nó da lista
        mov esi, [r13 + 4 * rax]
        mov dword [r15 + 4 * rax], esi
        inc rax
        cmp rax, 8
        jl add_index_loop

        mov rax, 0 ; Adiciona a informação no novo nó
        add_info_loop:
        mov esi, [r12 + 4 * rax]
        mov dword [r15 + 64 + 4 * rax], esi
        inc rax
        cmp rax, 16
        jl add_info_loop

        list_end_loop: ; Encontra o último nó da lista atual
        mov r13, [r14 + 192]
        cmp r13, 0 ; Vê se node->prox == NULL
        je add_node ; Se sim, node->prox = newnode
        mov r14, [r14 + 192] ; Se não, node = node->prox
        jmp list_end_loop

        add_node:
        mov qword [r14 + 192], r15
        epilog





; Essa função verifica se um index escolhido é igual ao index de algum item da lista, se sim
; esse nó da lista será guardado em r15, se não, r15 terá o valor -1

; Buscar um elemento na lista leva em consideração que duas informações foram adicionadas à
; stack nessa ordem : Endereço da lista / Índice do elemento a ser encontrado

; Após usar essa função execute "add rsp, 16" para liberar 2 registradores de espaço na stack
    list_index_search:
        prolog r14, r13, r8, r9, r11
        mov r15, [rbp + 24] ; Guarda o endereço da lista em r15
        mov r14, [rbp + 16] ; Guarda o índice a ser procurado em r14

        index_search_loop: ; Compara cada nó com o índice
        mov r8, r15
        mov r9, r14
        call strcmp ; Efetua a comparação
        cmp r11, 0 ; r11 == 0 se r8 == r9
        je index_search_epilog

        mov r13, [r15 + 192] ; Verifica se existe mais um elemento na lista
        cmp r13, 0
        je index_search_miss ; Se não, a função retorna -1
        mov r15, [r15 + 192]
        jmp index_search_loop ; Se sim, volta para o loop e tenta a comparação novamente

        index_search_miss:
            mov r15, -1

        index_search_epilog:
            epilog





; Essa função remove um item da lista baseado no index, ou seja, efetua uma comparação e se o
; index de um elemento for igual ao index desejado, remove esse elemento. Se o index buscado
; não estiver na lista, nada acontece. A função retorna r15 apontando para o primeiro nó

; Remover um elemento da lista leva em consideração que duas informações fora adicionadas à
; stack nessa ordem : Endereço da lista / índice do elemento a ser removido

; Após usar essa função execute "add rsp, 16" para liberar 2 registradores de espaço na stack
    remove_from_list:
        prolog r14, r13, r11, r9, r8, rdi
        mov r15, [rbp + 24] ; Guarda o endereço da lista
        mov r9, [rbp + 16] ; Guarda o índice do elemento a ser removido
        mov r13, 0 ; Esse valor irá guardar o nó anterior para correção de ponteiros
        push r15 ; Guarda o valor do primeiro nó

        index_remove_loop: ; Busca o nó a ser removido
        mov r8, r15
        call strcmp ; Efetua a comparação
        cmp r11, 0 ; r11 == 0 se r8 == r9
        je remove_proper

        mov r13, r15 ; Antecessor vira o atual
        mov r11, [r15 + 192] ; Verifica se existe mais um elemento na lista
        cmp r11, 0
        je remove_none ; Se não existe mais nada na lista, retorna
        mov r15, [r15 + 192] 
        jmp index_remove_loop ; Se existe, retorna para a comparação

        remove_proper: 
        cmp r13, 0 ; Verifica se o elemento a ser retirado é o primeiro
        je remove_first ; Se for, vai para um caso especial de remoção
        mov r14, [r15 + 192]
        mov [r13 + 192], r14 ; node->ant->prox = node->prox
        mov rdi, r15
        call free ; Free the node
        pop r15 ; Busca o primeiro nó para o retorno
        jmp remove_epilogue

        remove_first:
        pop rdi ; Joga fora o primeiro nó, visto que ele será removido
        mov rdi, r15
        mov r15, [r15 + 192] ; r15 agora aponta pro segundo elemento da lista
        call free ; Free the original first node
        jmp remove_epilogue

        remove_none:
        pop r15

        remove_epilogue:
            epilog




        ; DEBUG FUNCTIONS. POORLY EXPLAINED AND IN ENGLISH. BUT SURE, USE THEM IF YOU DARE.


    ; Gets a pointer to the first element of the list, doesn't return anything. Run add rsp, 8 after.
    ; This doesn't (currently) print the list. It just works to tell you the amount of elements in it.
    printlist:
        prolog r15, r14, r13
        mov r15, [rbp + 16]

        print_list_loop:
        cmp r15, 0
        je print_list_end

        lea r14, [r15 + 64]

        mov r15, [r15 + 192]
        scanf rbx, 'ss', r13
        jmp print_list_loop

        print_list_end:
        epilog


    ; Checks if a node has a given index. Send The address of the node / the index you seek
    ; Run add rsp, 16 after.
    is_node:
        prolog r15, r14, r8, r9
        mov r15, [rbp + 24]
        mov r14, [rbp + 16]

        cmp r15, 0
        je exits

        mov r8, r15
        mov r9, r14
        call strcmp

        cmp r11, 1
        je exits
        scanf rbx, 'ss', r13
   
    ; Yep, it sure does exit
    exits:
        call exit




