
; Source name       : CHARSIN.ASM
; Executable name   : CHARSIN
; Version           : 1.0
; Created date      : 27/8/2024
; Last update       : 27/8/2024
; Author            : Faishal Manzar
; Description       : A character input demo for Linux, using NASM 2.05,
;                     incorporating calls to both fgets() and scanf().(Practice program from jeff Duntemann)
; 
; Build using these commands:
;   nasm -f elf -g -F stabs charsin.asm
;   gcc -m32 charsin.o -o charsin
;
[SECTION .data]         ; Section containing initialised data
    SPrompt db 'Enter string data, followed by Enter: ',0
    IPrompt db 'Enter an integer value, followed by Enter: ',0
    IFormat db '%d',0
    SShow   db 'The string you entered was: %s',10,0
    IShow   db 'The integer value you entered was: %5d',10,0

[SECTION .bss]          ; Section containing uninitialized data
    IntVal  resd 1      ; Reserve an uninitialized double word
    InString resb 128   ; Reserve 128 bytes for string entry buffer

[SECTION .text]   ; Section containing code

extern stdin
extern fgets
extern printf
extern scanf

global main         ; Standard file variable for input

main:
    push ebp        ; Set up stack frame for debugger
    mov ebp,esp
    push ebx        ; Must preserve ebp, ebx, esi, & edi
    push esi
    push edi
    ;;; Everything before this is boilerplate;

    ; First, an example of safely limited string input using fgets:
    push SPrompt    ; Push address of the prompt string
    call printf     ; Display it
    add esp,4       ; Stack cleanup for 1 parm
    
    push dword [stdin] ; Push file handle for standard input
    push 72         ; Accept no more than 72 chars from keybd
    push InString   ; Push address of buffer for entered chars
    call fgets      ; Call fgets
    add esp,12      ; Stack cleanup: 3 parms X 4 bytes = 12
    
    push InString   ; Push address of entered string data buffer
    push SShow      ; Push address of the string display prompt
    call printf     ; Display it
    add esp,8       ; Stack cleanup: 2 parms X 4 bytes = 8

    ; Next, use scanf() to enter numeric data:
    push IPrompt        ; Push address of the integer input prompt
    call printf         ; Display it
    add esp,4           ; Stack cleanup for 1 parm

    push IntVal         ; Push the address of the integer buffer
    push IFormat        ; Push the address of the integer format string
    call scanf          ; Call scanf to enter numeric data
    add esp,8           ; Stack cleanup: 2 parms X 4 bytes = 8
    
    push dword [IntVal] ; Push integer value to display
    push IShow      ; Push base string
    call printf     ; Call printf to convert & display the integer
    add esp,8       ; Stack cleanup: 2 parms X 4 bytes = 8

    ;;; Everything after this is boilerplate;
    pop edi       ; Restore saved registers
    pop esi
    pop ebx
    mov esp,ebp   ; Destroy stack frame before returning
    pop ebp
    ret           ; Return control to Linux




