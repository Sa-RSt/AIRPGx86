%ifndef STDLIB_MACROS
%define STDLIB_MACROS 1

section .text

%macro prolog 0-*
    push rbp
    mov rbp, rsp
    %push stack_frame_block
    %assign stack_frame_i 0
    %rep %0
        push %1
        %xdefine %$stack_frame_block_%[stack_frame_i] %1
        %rotate 1
        %assign stack_frame_i stack_frame_i + 1
    %endrep
    %assign %$stack_frame_max_i stack_frame_i
%endmacro

%macro epilog 0
    %ifnctx stack_frame_block
        %error "expected 'prolog' before 'epilog'"
    %endif
    %assign %$stack_frame_i %$stack_frame_max_i
    %assign %$stack_frame_i %$stack_frame_i - 1
    %rep %$stack_frame_max_i
        pop %$stack_frame_block_%[%$stack_frame_i]
        %assign %$stack_frame_i %$stack_frame_i - 1
    %endrep
    mov rsp, rbp
    pop rbp
    ret
    %pop stack_frame_block
%endmacro

%macro movnop 2
    %ifnidni %1, %2
        mov %1, %2
    %endif
%endmacro

%macro if 3
    %push if
    cmp %2, %3
    j%-1 %$ifnot
%endmacro

%macro ifzero 1
    %push if
    test %1, %1
    jnz %$ifnot
%endmacro

%macro ifnonzero 1
    %push if
    test %1, %1
    jz %$ifnot
%endmacro

%macro else 0
    %ifctx if
        %repl else
        jmp %$ifend
        %$ifnot:
    %else
        %error "expected `if' before `else'"
        %pop if
    %endif
%endmacro

%macro endif 0
    %rep 999999
        %ifdef %$IS_ELIF
            %define CONTINUE_ENDIF_LOOP
        %endif
        %ifctx if
            %$ifnot:
            %pop
        %elifctx else
            %$ifend:
            %pop
        %else
            %error  "expected `if' or `else' before `endif'"
        %endif
        %ifdef CONTINUE_ENDIF_LOOP
            %undef CONTINUE_ENDIF_LOOP
        %else
            %exitrep
        %endif
    %endrep
%endmacro

%macro elif 1-*
    %ifctx if
        %repl else
        jmp %$ifend
        %$ifnot:
        if %{1:-1}
        %xdefine %$IS_ELIF 1
    %else
        %error "expected `if' before `elif'"
        %pop if
    %endif
%endmacro

%macro elifzero 1
    %ifctx if
        %repl else
        jmp %$ifend
        %$ifnot:
        ifzero %1
        %xdefine %$IS_ELIF 1
    %else
        %error "expected `if' before `elif'"
        %pop if
    %endif
%endmacro

%macro elifnonzero 1
    %ifctx if
        %repl else
        jmp %$ifend
        %$ifnot:
        ifnonzero %1
        %xdefine %$IS_ELIF 1
    %else
        %error "expected `if' before `elif'"
        %pop if
    %endif
%endmacro

%macro while 3
    %push while
    %$while_begin:
    cmp %2, %3
    j%-1 %$while_end
%endmacro

%macro whilezero 1
    %push while
    %$while_begin:
    test %1, %1
    jnz %$while_end
%endmacro

%macro whilenonzero 1
    %push while
    %$while_begin:
    test %1, %1
    jz %$while_end
%endmacro

%macro endwhile 0
    %ifctx while
        jmp %$while_begin
        %$while_end:
        %pop
    %else
        %error "expected `while' before `endwhile'"
        %pop while
    %endif
%endmacro

%macro for 3-4 1
    %push for
    %define %$control %1
    %define %$increment %4
    movnop %1, %2
    while l, %1, %3
%endmacro

%macro reverse_for 3-4 -1
    %push for
    %define %$control %1
    %define %$increment %4
    movnop %1, %2
    while ge, %1, %3
%endmacro

%macro endfor 0
    %ifnctx while
        %error "expected 'for' before 'endfor'"
    %endif
    add %$$control, %$$increment
    endwhile
    %ifnctx for
        %error "expected 'for' before 'endfor'"
    %endif
    %pop for
%endmacro

%macro dowhile 3
    %push dowhile
    jmp %%inside
    while %1, %2, %3
    %%inside:
%endmacro

%macro dowhilezero 1
    %push dowhile
    jmp %%inside
    whilezero %1
    %%inside:
%endmacro

%macro dowhilenonzero 1
    %push dowhile
    jmp %%inside
    whilenonzero %1
    %%inside:
%endmacro

%macro enddowhile 0
    %ifnctx while
        %error "expected 'dowhile' before 'enddowhile'"
    %endif
    endwhile
    %ifnctx dowhile
        %error "expected 'dowhile' before 'enddowhile'"
    %endif
    %pop
%endmacro

%macro multipush 1-*
    %rep %0
        push %1
        %rotate 1
    %endrep
%endmacro

%macro multipop 1-*
    %rep %0
        %rotate -1
        pop %1
    %endrep
%endmacro

%macro syscall_header 0
    multipush rdi, rsi, rdx, r10, r9, r8, r11, rcx
%endmacro

%macro syscall_footer 0
    multipop rdi, rsi, rdx, r10, r9, r8, r11, rcx
%endmacro

%macro print_literal 1-*
    section .data
    %%data:
    db %{1:-1}, 0
    section .text
    push rsi
    mov rsi, %%data
    call print
    pop rsi
%endmacro

%macro print_register 1
    printf 'xuic', %str(%1), " = hex: 0x", %1, ", uint: ", %1, ", int: ", %1, 0x0A
%endmacro

%macro print_registers 1-*
    %if DEBUG != 0
        %rep %0
            print_register %1
            %rotate 1
        %endrep
    %endif
%endmacro

%macro assert 3
    %if DEBUG != 0
        cmp %2, %3
        j%+1 %%okay
        print_literal "assertion failed: ", %str(%1), ", ", %str(%2), ", ", %str(%3), 0x0A
        %ifnnum %2
            print_literal "    "
            print_register %2
        %endif
        %ifnnum %3
            print_literal "    "
            print_register %3
        %endif
        %%okay: 
    %endif
%endmacro


%macro fprintf 3-*
    %xdefine printf_file_descriptor %1
    %xdefine printf_format_spec %2
    %assign printf_format_pos 1
    %rotate 2
    %ifidni printf_file_descriptor, rsi
        %error "The file descriptor must not be in rsi"
    %endif
    %rep %0 - 2
        %ifstr %1
            print_literal %1
        %else
            %substr printf_format_char printf_format_spec printf_format_pos
            %if printf_format_char == 'u'
                multipush rax, rdi, rsi
                sub rsp, 64
                movnop rax, %1
                mov rdi, rsp
                call utoa
                mov rsi, rdi
                mov rdi, printf_file_descriptor
                call fprint
                add rsp, 64
                multipop rax, rdi, rsi
            %elif printf_format_char == 'i'
                multipush rax, rdi, rsi
                sub rsp, 64
                movnop rax, %1
                mov rdi, rsp
                call itoa
                mov rsi, rdi
                movnop rdi, printf_file_descriptor
                call fprint
                add rsp, 64
                multipop rax, rdi, rsi
            %elif printf_format_char == 'x'
                multipush rax, rdi, rsi
                sub rsp, 64
                movnop rax, %1
                mov rdi, rsp
                call utoa_hex
                mov rsi, rdi
                movnop rdi, printf_file_descriptor
                call fprint
                add rsp, 64
                multipop rax, rdi, rsi
            %elif printf_format_char == 's'
                multipush rsi, rdi
                movnop rsi, %1
                movnop rdi, printf_file_descriptor
                call fprint
                multipop rsi, rdi
            %elif printf_format_char == 'c'
                multipush rsi, rdi
                sub rsp, 8
                movnop rdi, printf_file_descriptor
                mov rsi, rsp
                mov byte [rsi], %1
                mov byte [rsi+1], 0x00
                call fprint
                add rsp, 8
                multipop rsi, rdi
            %else
                %error "invalid format specifier" printf_format_spec printf_format_char
            %endif
            %assign printf_format_pos printf_format_pos + 1
        %endif
        %rotate 1
    %endrep
    %undef printf_format_pos
    %undef printf_format_char
    %undef printf_format_spec
    %undef printf_file_descriptor
%endmacro

%macro printf 2-*
    fprintf 1, %{1:-1}
%endmacro

%macro fscanf 4-*
    %xdefine scanf_file_descriptor %1
    %xdefine scanf_out_count %2
    %xdefine scanf_format_spec %3
    %assign scanf_format_pos 1
    %rotate 3
    %ifidni scanf_file_descriptor, rsi
        %error "The file descriptor must not be in rsi"
    %endif
    %ifidni scanf_out_count, rax
        %error "The output count must not be in rax"
    %endif
    xor scanf_out_count, scanf_out_count
    %rep %0 - 3
        %ifidni %1, rax
            %error %1 " must not be an output register. Please pick another one." 
        %elifidni %1, rsi
            %error %1 " must not be an output register. Please pick another one." 
        %elifidni %1, rdi
            %error %1 " must not be an output register. Please pick another one." 
        %elifidni %1, r13
            %error %1 " must not be an output register. Please pick another one." 
        %endif
        %ifstr %1
            %error "fscanf does not accept literals: " %1
        %else
            %substr scanf_format_char scanf_format_spec scanf_format_pos
            %if scanf_format_char == 'u'
                multipush rdi, rsi, r13
                %ifnidni %1, rax
                    push rax
                %endif
                xor rdi, rdi
                call read_until_whitespace
                mov rsi, rax
                call atou
                ifzero r13
                    inc scanf_out_count
                endif
                %ifnidni %1, rax
                    mov %1, rax
                    pop rax
                %endif
                multipop rdi, rsi, r13
            %elif scanf_format_char == 'i'
                multipush rdi, rsi, r13
                %ifnidni %1, rax
                    push rax
                %endif
                xor rdi, rdi
                call read_until_whitespace
                mov rsi, rax
                call atoi
                ifzero r13
                    inc scanf_out_count
                endif
                %ifnidni %1, rax
                    mov %1, rax
                    pop rax
                %endif
                multipop rdi, rsi, r13
            %elif scanf_format_char == 'x'
                multipush rdi, rsi
                %ifnidni %1, rax
                    push rax
                %endif
                xor rdi, rdi
                call read_until_whitespace
                mov rsi, rax
                call atou_hex
                ifzero r13
                    inc scanf_out_count
                endif
                %ifnidni %1, rax
                    mov %1, rax
                    pop rax
                %endif
                multipop rdi, rsi
            %elif scanf_format_char == 's'
                %ifnidni %1, rax
                    push rax
                %endif
                push rdi
                movnop rdi, scanf_file_descriptor
                call read_until_whitespace
                pop rdi
                %ifnidni %1, rax
                    movnop %1, rax
                    pop rax
                %endif
            %elif scanf_format_char == 'c'
                push rax
                syscall_header
                sub rsp, 8
                xor rax, rax  ; sys_read
                movnop rdi, scanf_file_descriptor
                mov rsi, rsp
                mov rdx, 1
                syscall
                mov byte %1, [rsi]
                add rsp, 8
                syscall_footer
                pop rax
            %else
                %error "invalid format specifier" scanf_format_spec scanf_format_char
            %endif
            %assign scanf_format_pos scanf_format_pos + 1
        %endif
        %rotate 1
    %endrep
    %undef scanf_format_pos
    %undef scanf_format_char
    %undef scanf_format_spec
%endmacro

%macro scanf 3-*
    fscanf 0, %{1:-1}
%endmacro

strcmp: ; r8, r9 = strings a serem analisadas (r11 contém o resultado. 1 se diferente, 0 se igual)
    prolog r10, rax, rbx
    mov r10, 0
    strcmp_loop:
    mov al, [r8 + r10]
    mov bl, [r9 + r10]
    cmp al, $0
    je strcmp_end
    inc r10
    cmp al, bl
    jne strcmp_dif
    jmp strcmp_loop
    strcmp_end:
        cmp r10, 0
        je strcmp_dif
        cmp bl, $0
        jne strcmp_dif
        mov r11, 0
        jmp strcmp_epilog
    strcmp_dif:
        mov r11, 1
        jmp strcmp_epilog
    strcmp_epilog:
        epilog

strend:  ; avança o ponteiro em rdi até que aponte para um NUL (\0)
    prolog rcx
    mov cl, [rdi]
    whilenonzero cl
        inc rdi
        mov cl, [rdi]
    endwhile
    epilog

strrev: ; rdi = string para inverter
    prolog rdi, r8, r9, rsi
    mov rsi, rdi
    call strend  ; agora rdi aponta para o final da string
    sub rdi, 1
    while l, rsi, rdi
        mov byte cl, [rdi]  ; trocar bytes
        mov byte dl, [rsi]
        mov byte [rdi], dl
        mov byte [rsi], cl
        inc rsi
        dec rdi
    endwhile
    epilog


utoa:  ; rax = inteiro a converter, rdi = ponteiro para buffer onde colocar a string decimal
    prolog rax, rcx, rdi, rdx, rsi
    ifzero rax
        mov byte [rdi], '0'
        mov byte [rdi+1], 0x00
    else
        mov rsi, rdi
        mov rcx, 10
        whilenonzero rax
            xor rdx, rdx
            div rcx  ; rax = rax/10, rdx = rax%10
            add dl, '0'  ; converter resto para caractere ascii representativo
            mov [rdi], dl
            inc rdi
        endwhile
        mov byte [rdi], 0x00
        mov rdi, rsi  ; voltar rdi para o começo da string
        call strrev
    endif
    epilog

itoa:  ; rax = inteiro a converter, rdi = ponteiro para buffer
    if l, rax, 0
        neg rax
        mov byte [rdi], '-'  ; colocar um sinal de menos e depois chamar utoa
        inc rdi
        call utoa
        neg rax
        dec rdi
    else
        call utoa  ; número positivo ou zero, só chamar utoa
    endif
    ret

utoa_hex:  ; rax = inteiro a converter, rdi = ponteiro para buffer onde colocar a string hexadecimal
    prolog rax, rcx, rdi, rdx, rsi
    ifzero rax
        mov byte [rdi], '0'
        mov byte [rdi+1], 0x00
    else
        mov rsi, rdi
        mov rcx, 16
        whilenonzero rax
            mov rdx, rax
            and rdx, 0b1111  ; rdx = rax % 16
            shr rax, 4  ; rax = rax / 16

            add dl, '0'  ; converter resto para caractere ascii representativo
            cmp dl, '9'
            jle .nao_eh_abcdef
            add dl, 7  ; deslocar para a região do ascii que tem as letras maiúsculas
            .nao_eh_abcdef:
            mov [rdi], dl
            inc rdi
        endwhile
        mov byte [rdi], 0x00
        mov rdi, rsi  ; voltar rdi para o começo da string
        call strrev  ; inverter rdi
        .return:
    endif
    epilog

println:  ; rsi = string
    prolog rsi
    call print
    sub rsp, 8
    mov rsi, rsp
    mov byte [rsi], 0x0A  ; \n
    mov byte [rsi+1], 0x00
    call print
    add rsp, 8
    epilog

print:  ; rsi = string
    prolog rdi
    mov rdi, 1  ; stdout
    call fprint
    epilog

fprint:  ; rdi = file descriptor, rsi = string
    prolog rax
    syscall_header
    mov rcx, rdi  ; rcx já é preservado pelo syscall_header
    mov rdi, rsi
    call strend
    sub rdi, rsi  ; calcula tamanho da string
    mov rdx, rdi
    mov rdi, rcx  ; restaura rdi
    mov rax, 1  ; sys_write
    syscall
    syscall_footer
    epilog

strcpy:  ; rdi = destino, rsi = string a copiar (terminada em NUL)
    prolog rsi, rdi, r8
    .loop:
    mov r8b, [rsi]
    whilenonzero r8b
        mov [rdi], r8b
        inc rsi
        inc rdi
        mov r8b, [rsi]
    endwhile
    mov byte [rdi], 0x00
    epilog

memcpy:  ; rdi = destino, rsi = bloco a copiar, r8 = tamanho
    prolog rcx, rdx
    for rcx, 0, r8
        mov dl, [rsi+rcx]
        mov [rdi+rcx], dl
    endfor
    epilog

strncpy:  ; rdi = destino, rsi = bloco a copiar, r8 = tamanho máximo
    prolog rdi, r8, r9
    mov r9, rdi  ; salvar destino no r9
    mov rdi, rsi
    call strend
    sub rdi, rsi  ; rdi tem o tamanho da string
    if le, rdi, r8
        mov rdi, r9
        call strcpy
    else
        mov rdi, r9
        call memcpy
        dec r8
        mov byte [rdi+r8], 0  ; inserir \0 no final
    endif
    epilog


strdup:  ; rdi = string a duplicar, rax = (retorno) ponteiro na heap para string duplicada
    prolog rdi, rsi, r9
    mov rdi, r9
    call strend
    sub rdi, r9  ; agora rdi tem o tamanho da string

    mov rsi, rdi
    call malloc  ; alocar espaço para copiar a string

    mov rdi, rax
    mov rsi, r9
    call strcpy  ; copiar conteúdo para espaço alocado
    epilog


malloc:  ; rsi = tamanho, rax = (retorno) ponteiro para o bloco
    prolog
    syscall_header
    add rsi, 8
    mov rax, 0x09
    xor rdi, rdi
    mov rdx, 3  ; PROT_READ | PROT_WRITE
    mov r10, 0x22  ; MAP_ANONYMOUS | MAP_PRIVATE
    mov r8, -1
    xor r9, r9  ; offset = 0
    syscall
    mov [rax], rsi
    add rax, 8
    syscall_footer
    epilog

free:  ; rdi = ponteiro para o bloco
    prolog rax
    syscall_header
    sub rdi, 8
    mov rax, 0x0b
    mov rsi, [rdi]  ; obter tamanho na base do ponteiro
    xor rdx, rdx
    xor r10, r10
    xor r9, r9
    xor r8, r8
    syscall
    syscall_footer
    epilog

realloc:  ; rsi = novo tamanho, rax = ponteiro para o bloco atual e (retorno) ponteiro para o bloco potencialmente novo
    prolog rcx, rdi, rsi, r8
    mov rcx, [rax-8]
    if g, rsi, rcx
        mov rdi, rax
        call malloc
        mov rsi, rdi
        mov rdi, rax
        mov r8, rcx
        call memcpy
        mov rdi, rsi
        call free
    endif
    epilog

read_line:  ; rax = (retorno) ponteiro para a string lida, rdi = file descriptor
    prolog r8
    mov r8, 0x0A  ; \n
    call read_until_byte
    epilog

read_until_byte:  ; rax = (retorno) ponteiro para a string lida, rdi = file descriptor, r8b = byte de parada
    prolog r15, r14, r13, r12
    syscall_header

    mov r15, 64
    mov r12, 0
    mov rsi, 64
    call malloc
    mov rsi, rax
    mov r13, rax

    dowhile ne, r14b, r8b
        xor rax, rax  ; sys_read
        mov rdx, 1
        syscall
        mov r14b, [rsi]
        inc rsi
        inc r12
        if ge, r12, r15
            mov rax, r13
            shl r15, 1
            mov rsi, r15
            call realloc
            mov rsi, r12
            add rsi, rax
            mov r13, rax
        endif
    enddowhile
    mov byte [rsi-1], 0x00
    mov rax, r13
    syscall_footer
    epilog

read_until_whitespace:  ; rax = (retorno) ponteiro para a string lida, rdi = file descriptor
    prolog r15, r14, r13, r12
    syscall_header

    mov r15, 64
    mov r12, 0
    mov rsi, 64
    call malloc
    mov rsi, rax
    mov r13, rax

    dowhile g, r14b, 0x20
        xor rax, rax  ; sys_read
        mov rdx, 1
        syscall
        mov r14b, [rsi]
        inc rsi
        inc r12
        if ge, r12, r15
            mov rax, r13
            shl r15, 1
            mov rsi, r15
            call realloc
            mov rsi, r12
            add rsi, rax
            mov r13, rax
        endif
    enddowhile
    mov byte [rsi-1], 0x00
    mov rax, r13
    syscall_footer
    epilog

to_upper: ; rsi = string pra ler, rdi = (retorno) string in letra maiúscula
    prolog rax, rsi, rbx
    mov rax, 0

    to_upper_loop:
    mov bl, byte[rsi]

    cmp bl, 0h
    je to_upper_end

    cmp bl, 0x61
    jl to_upper_next
    cmp bl, 0x7A
    jg to_upper_next

    sub bl, 0x20

    to_upper_next:
    mov byte [rdi + rax], bl
    inc rsi
    inc rax
    jmp to_upper_loop

    to_upper_end:
    mov byte [rdi + rax], 0x00
    epilog

to_lower: ; rsi = string pra ler, rdi = (retorno) string in letra minúscula
    prolog rax, rsi, rbx
    mov rax, 0

    to_lower_loop:
    mov bl, byte[rsi]

    cmp bl, 0h
    je to_lower_end

    cmp bl, 0x41
    jl to_lower_next
    cmp bl, 0x5A
    jg to_lower_next

    add bl, 0x20

    to_lower_next:
    mov byte [rdi + rax], bl
    inc rsi
    inc rax
    jmp to_lower_loop

    to_lower_end:
    mov byte [rdi + rax], 0x00
    epilog

strsiz: ; rsi = string para ler, rdi = (retorno) tamanho da string terminada em 0
    prolog rsi, rax
    mov rdi, 0

    strsiz_loop:
    mov al, byte [rsi + rdi]
    cmp al, 0h
    je strsiz_end
    inc rdi
    jmp strsiz_loop

    strsiz_end:
    epilog

atou:  ; rax = (retorno) número lido, r13 = (retorno) zero se o número for válido, rsi = string para ler
    prolog rdx, r9, rdi, rsi, r8, r14
    xor r14, r14
    xor r13, r13
    mov r9, 10
    mov rax, 1

    mov rdi, rsi
    call strend

    if ne, rdi, rsi
        sub rdi, 1
        reverse_for rdi, rdi, rsi
            xor rdx, rdx
            mov dl, [rdi]
            cmp dl, '0'
            jl .error
            cmp dl, '9'
            jg .error
            sub dl, '0'
            mov r8, rax
            mul rdx
            jo .error
            add r14, rax
            jo .error
            mov rax, r8
            mul r9
            jo .error
        endfor
        mov rax, r14
        jmp .success
    endif
    .error:
    mov r13, 1
    .success:
    mov rax, r14
    epilog

atoi:  ; rax = (retorno) número lido, r13 = (retorno) zero se o número for válido, rsi = string para ler
    prolog r10
    xor r13, r13
    xor r10, r10
    mov r10b, [rsi]
    if e, r10b, '-'
        inc rsi
        call atou
        dec rsi
        neg rax
    elifnonzero r10b
        call atou
    else
        mov r13, 1
    endif
    if g, rax, 0
        mov r13, 1
    endif
    epilog

atou_hex:  ; rax = (retorno) número lido, r13 = (retorno) zero se o número for válido, rsi = string para ler
    prolog rdx, rdi, rsi, rcx
    xor rcx, rcx
    xor r13, r13
    xor rax, rax

    mov rdi, rsi
    call strend

    if ne, rdi, rsi
        sub rdi, 1
        reverse_for rdi, rdi, rsi
            xor rdx, rdx
            mov dl, [rdi]
            if l, dl, '0'
                jmp .error
            elif le, dl, '9'
                sub dl, '0'
            elif le, dl, 'Z'
                if ge, dl, 'A'
                    sub dl, 55
                else
                    jmp .error
                endif
            elif le, dl, 'z'
                if ge, dl, 'a'
                    sub dl, 87
                else
                    jmp .error
                endif
            endif
            shl rdx, cl
            jo .error
            add rax, rdx
            jo .error
            add cl, 4
            jo .error
        endfor
        jmp .success
    endif
    .error:
    mov r13, 1
    .success:
    epilog


delay:  ; r10 = número mínimo de milissegundos para suspender execução
    prolog rax, r10
    syscall_header
    sub rsp, 16  ; criar timespec
    mov rax, r10
    xor rdx, rdx
    mov r10, 1000
    div r10
    mov [rsp], rax  ; segundos inteiros
    mov rax, rdx
    xor rdx, rdx
    mov r10, 1000000
    mul r10
    mov [rsp+8], rax  ; nanossegundos

    mov rax, 0x23  ; sys_nanosleep
    mov rdi, rsp
    xor rsi, rsi
    syscall
    add rsp, 16
    syscall_footer
    epilog


exit:
    mov rax, 60                             	    ; Carrega o número da syscall para "exit" (número 60) no registrador rax
    mov rdi, 0                              	    ; Carrega o valor de saída (0) no registrador rdi (0 indica sucesso)
    syscall                                 	    ; Chama a syscall, o que vai terminar o programa

%endif
