section .data

section .bss
    random_byte resb 1

section .text
    %ifdef TESTING
        global _start
        %define DEBUG 1
    %endif
    %include "stdlib_macros.asm" 
