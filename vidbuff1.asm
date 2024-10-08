; Executable name : VIDBUFF1
; Version         : 1.0
; Created date    : 26/8/2024
; Last update     : 26/8/2024
; Author          : Faishal Manzar
; Description     : A simple program in assembly for Linux, using NASM 2.05,
;                   demonstrating string instruction operation by “faking“ full-screen
;                   memory-mapped text I/O (Practice program from jeff Duntemann).
;
; Build using these commands:
;    nasm -f elf -g -F stabs vidbuff1.asm
;    ld -m elf_i386 -s -o vidbuff1 vidbuff1.o
;

SECTION .data           ; Section containing initialised data
    EOL       equ 10    ; Linux end-of-line character
    FILLCHAR  equ 32    ; ASCII space character
    HBARCHR   equ 196   ; Use dash char if this won’t display
    STRTROW   equ 2     ; Row where the graph begins

    ; The dataset is just a table of byte-length numbers:
    Dataset db  9,71,17,52,55,18,29,36,18,68,77,63,58,44,0

    Message db "Data current as of 26/8/2024"
    MSGLEN equ $-Message

    ; This escape sequence will clear the console terminal and place the
    ; text cursor to the origin (1,1) on virtually all Linux consoles:
    ClrHome db 27,"[2J",27,"[01;01H"
    CLRLEN equ $-ClrHome  ; Length of term clear string

SECTION .bss                ; Section containing uninitialized data
    COLS    equ 81          ; Line length + 1 char for EOL
    ROWS    equ 25          ; Number of lines in display
    VidBuff resb COLS*ROWS  ; Buffer size adapts to ROWS & COLS

SECTION .text               ; Section containing code

global _start               ; Linker needs this to find the entry point!


; This macro clears the Linux console terminal and sets the cursor position
; to 1,1, using a single predefined escape sequence.
%macro ClearTerminal 0
    pushad                  ; Save all registers
    mov eax,4               ; Specify sys_write call
    mov ebx,1               ; Specify File Descriptor 1: Standard Output
    mov ecx,ClrHome         ; Pass offset of the error message
    mov edx,CLRLEN          ; Pass the length of the message
    int 80H                 ; Make kernel call
    popad                   ; Restore all registers
%endmacro


;-------------------------------------------------------------------------
; Show          : Display a text buffer to the Linux console
; UPDATED       : 26/8/2024
; IN            : Nothing
; RETURNS       : Nothing
; MODIFIES      : Nothing
; CALLS         : Linux sys_write
; DESCRIPTION   : Sends the buffer VidBuff to the Linux console via sys_write.
;               The number of bytes sent to the console is calculated by
;               multiplying the COLS equate by the ROWS equate.
;
Show:
    pushad              ; Save all registers
    mov eax,4           ; Specify sys_write call
    mov ebx,1           ; Specify File Descriptor 1: Standard Output
    mov ecx,VidBuff     ; Pass offset of the buffer
    mov edx,COLS*ROWS   ; Pass the length of the buffer
    int 80H             ; Make kernel call
    popad               ; Restore all registers
    ret


;-------------------------------------------------------------------------
; ClrVid        : Clears a text buffer to spaces and replaces all EOLs
; UPDATED       : 26/8/2024
; IN            : Nothing
; RETURNS       : Nothing
; MODIFIES      : VidBuff, DF
; CALLS         : Nothing
; DESCRIPTION   : Fills the buffer VidBuff with a predefined character
;                 (FILLCHR) and then places an EOL character at the end
;                 of every line, where a line ends every COLS bytes in
;                 VidBuff
;
ClrVid: 
    push eax        ; Save caller’s registers
    push ecx
    push edi
    cld             ; Clear DF; we’re counting up-memory
    mov al,FILLCHAR  ; Put the buffer filler char in AL
    mov edi,VidBuff ; Point destination index at buffer
    mov ecx,COLS*ROWS; Put count of chars stored into ECX
    rep stosb        ; Blast chars at the buffer    
    ; Buffer is cleared; now we need to re-insert the EOL char after each line:
    mov edi,VidBuff  ; Point destination at buffer again
    dec edi          ; Start EOL position count at VidBuff char 0
    mov ecx,ROWS     ; Put number of rows in count register
PtEOL: 
    add edi,COLS        ; Add column count to EDI
    mov byte [edi],EOL  ; Store EOL char at end of row
    loop PtEOL          ; Loop back if still more lines
    pop edi             ; Restore caller’s registers
    pop ecx
    pop eax
    ret


;-------------------------------------------------------------------------
; WrtLn         : Writes a string to a text buffer at a 1-based X,Y position
; UPDATED       : 26/8/2024
; IN            : The address of the string is passed in ESI
;                 The 1-based X position (row #) is passed in EBX
;                 The 1-based Y position (column #) is passed in EAX
;                 The length of the string in chars is passed in ECX
; RETURNS       : Nothing
; MODIFIES      : VidBuff, EDI, DF
; CALLS         : Nothing
; DESCRIPTION   : Uses REP MOVSB to copy a string from the address in ESI
;                to an X,Y location in the text buffer VidBuff.
;
WrtLn: 
    push eax        ; Save registers we change
    push ebx
    push ecx
    push edi
    cld             ; Clear DF for up-memory write
    mov edi,VidBuff ; Load destination index with buffer address
    dec eax         ; Adjust Y value down by 1 for address calculation
    dec ebx         ; Adjust X value down by 1 for address calculation
    mov ah,COLS     ; Move screen width to AH
    mul ah          ; Do 8-bit multiply AL*AH to AX
    add edi,eax     ; Add Y offset into vidbuff to EDI
    add edi,ebx     ; Add X offset into vidbuf to EDI
    rep movsb       ; Blast the string into the buffer
    pop edi         ; Restore registers we changed
    pop ecx
    pop ebx
    pop eax
    ret


;-------------------------------------------------------------------------
; WrtHB       : Generates a horizontal line bar at X,Y in text buffer
; UPDATED     : 26/8/2024
; IN          : The 1-based X position (row #) is passed in EBX
;               The 1-based Y position (column #) is passed in EAX
;               The length of the bar in chars is passed in ECX
; RETURNS     : Nothing
; MODIFIES    : VidBuff, DF
; CALLS       : Nothing
; DESCRIPTION : Writes a horizontal bar to the video buffer VidBuff,
;               at the 1-based X,Y values passed in EBX,EAX. The bar is
;               “made of“ the character in the equate HBARCHR. The
;               default is character 196; if your terminal won’t display
;               that (you need the IBM 850 character set) change the
;               value in HBARCHR to ASCII dash or something else supported
;               in your terminal.
;
WrtHB: 
    push eax        ; Save registers we change
    push ebx
    push ecx
    push edi
    cld             ; Clear DF for up-memory write
    mov edi,VidBuff ; Put buffer address in destination register
    dec eax         ; Adjust Y value down by 1 for address calculation
    dec ebx         ; Adjust X value down by 1 for address calculation
    mov ah,COLS     ; Move screen width to AH
    mul ah          ; Do 8-bit multiply AL*AH to AX
    add edi,eax     ; Add Y offset into vidbuff to EDI
    add edi,ebx     ; Add X offset into vidbuf to EDI
    mov al,HBARCHR  ; Put the char to use for the bar in AL
    rep stosb       ; Blast the bar char into the buffer
    pop edi         ; Restore registers we changed
    pop ecx
    pop ebx
    pop eax
    ret


;-------------------------------------------------------------------------
; Ruler         : Generates a "1234567890"-style ruler at X,Y in text buffer
; UPDATED       : 26/8/2024
; IN            : The 1-based X position (row #) is passed in EBX
;                 The 1-based Y position (column #) is passed in EAX
;                 The length of the ruler in chars is passed in ECX
; RETURNS       : Nothing
; MODIFIES      : VidBuff
; CALLS         : Nothing
; DESCRIPTION   : Writes a ruler to the video buffer VidBuff, at the 1-based
;                 X,Y position passed in EBX,EAX. The ruler consists of a
;                 repeating sequence of the digits 1 through 0. The ruler
;                 will wrap to subsequent lines and overwrite whatever EOL
;                 characters fall within its length, if it will noy fit
;                 entirely on the line where it begins. Note that the Show
;                 procedure must be called after Ruler to display the ruler
;                 on the console.
;
Ruler: 
    push eax    ; Save the registers
    push ebx
    push ecx
    push edi
    mov edi,VidBuff ; Load video address to EDI
    dec eax         ; Adjust Y value down by 1 for address calculation
    dec ebx         ; Adjust X value down by 1 for address calculation
    mov ah,COLS     ; Move screen width to AH
    mul ah          ; Do 8-bit multiply AL*AH to AX
    add edi,eax     ; Add Y offset into vidbuff to EDI
    add edi,ebx     ; Add X offset into vidbuf to EDI
    ; EDI now contains the memory address in the buffer where the ruler
    ; is to begin. Now we display the ruler, starting at that position:
    mov al,'1'; Start ruler with digit '1’
DoChar: 
    stosb           ; Note that there’s no REP prefix!
    add al,'1'      ; Bump the character value in AL up by 1
    aaa             ; Adjust AX to make this a BCD addition
    add al,'0'      ; Make sure we have binary 3 in AL’s high nybble
    loop DoChar     ; Go back & do another char until ECX goes to 0
    pop edi         ; Restore the registers we changed
    pop ecx
    pop ebx
    pop eax
    ret


;-------------------------------------------------------------------------
; MAIN PROGRAM:

_start:
    nop         ; This no-op keeps gdb happy...

    ; Get the console and text display text buffer ready to go:
    ClearTerminal   ; Send terminal clear string to console
    call ClrVid     ; Init/clear the video buffer

    ; Next we display the top ruler:
    mov eax,1       ; Load Y position to AL
    mov ebx,1       ; Load X position to BL
    mov ecx,COLS-1  ; Load ruler length to ECX
    call Ruler      ; Write the ruler to the buffer

    ; Here we loop through the dataset and graph the data:
    mov esi,Dataset ; Put the address of the dataset in ESI
    mov ebx,1
    ; Start all bars at left margin (X=1)
    mov ebp,0       ; Dataset element index starts at 0

    .blast: 
        mov eax,ebp     ; Add dataset number to element index
        add eax,STRTROW ; Bias row value by row # of first bar
        mov cl,byte [esi+ebp] ; Put dataset value in low byte of ECX
        cmp ecx,0       ; See if we pulled a 0 from the dataset
        je .rule2       ; If we pulled a 0 from the dataset, we’re done
        call WrtHB      ; Graph the data as a horizontal bar
        inc ebp         ; Increment the dataset element index
        jmp .blast      ; Go back and do another bar

    ; Display the bottom ruler:
    .rule2: 
        mov eax,ebp     ; Use the dataset counter to set the ruler row
        add eax,STRTROW ; Bias down by the row # of the first bar
        mov ebx,1       ; Load X position to BL
        mov ecx,COLS-1 ; Load ruler length to ECX
        call Ruler  ; Write the ruler to the buffer

        ; Thow up an informative message centered on the last line
        mov esi,Message ; Load the address of the message to ESI
        mov ecx,MSGLEN ; and its length to ECX
        mov ebx,COLS        ; and the screen width to EBX
        sub ebx,ecx     ; Calc diff of message length and screen width
        shr ebx,1           ; Divide difference by 2 for X value
        mov eax,24      ; Set message row to Line 24
        call WrtLn      ; Display the centered message

        ; Having written all that to the buffer, send the buffer to the console:
        call Show   ; Refresh the buffer to the console

    Exit:       ; Code for Exit Syscall
        mov eax,1
        mov ebx,0   ; Return a code of zero
        int 80H     ; Make kernel call





