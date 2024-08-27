; Source name     : EATCLIB.ASM
; Executable name : EATCLIB
; Version         : 1.0 
; Created         : 26/8/2023
; Last update     : 26/8/2024
; Author          : Faishal Manzar
; Description     : Demonstrates calls made into glibc, using NASM 2.05
;                   to send a short text string to stdout with puts().(Practice program from jeff Duntemann)
; Build using these commands:
;   nasm -f elf -g -F stabs eatclib.asm
;   gcc eatclib.o -o boiler
;
[SECTION .data]   ; Section containing initialized data
  EatMsg: db "Eat at Joe’s!",0

[SECTION .bss]    ; Section containing uninitialized data

[SECTION .text]   ; Section containing code
  
extern puts       ; Simple “put string“ routine from glibc

global main       ; Required so linker can find entry point

main:
  push ebp        ; Set up stack frame for debugger
  mov ebp,esp
  push ebx        ; Must preserve ebp, ebx, esi, & edi
  push esi
  push edi

;;; Everything before this is boilerplate; use it for all ordinary apps!
  push EatMsg
  call puts
  add esp,4

;;; Everything after this is boilerplate; use it for all ordinary apps!
  pop edi       ; Restore saved registers
  pop esi
  pop ebx
  mov esp,ebp   ; Destroy stack frame before returning
  pop ebp
  ret           ; Return control to Linux

