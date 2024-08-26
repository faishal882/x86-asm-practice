; Executable name : SHOWCHAR
; Version         : 1.0
; Created date    : 26/8/2024
; Last update     : 26/8/2024
; Author          : Faishal Manzar
; Description     :  The showchar program clears the screen, displays a ruler on line 1, and
;                    below that shows a table containing 224 of the 256 ASCII characters, neatly
;                    displayed in seven lines of 32 characters each(Practice program from jeff Duntemann).
;
; Build using these commands:
;    nasm -f elf -g -F stabs showchar.asm
;    ld -m elf_i386 -s -o showchar showchar.o
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
    nop     ; This no-op keeps gdb happy...

    ; Get the console and text display text buffer ready to go:
    ClearTerminal   ; Send terminal clear string to console
    call ClrVid     ; Init/clear the video buffer
    
    ; Show a 64-character ruler above the table display:
    mov eax,1       ; Start ruler at display position 1,1
    mov ebx,1
    mov ecx,32      ; Make ruler 32 characters wide
    call Ruler      ; Generate the ruler

    ; Now let’s generate the chart itself:
    mov edi,VidBuff         ; Start with buffer address in EDI
    add edi,COLS*CHRTROW    ; Begin table display down CHRTROW lines
    mov ecx,224     ; Show 256 chars minus first 32
    mov al,32       ; Start with char 32; others won’t show

    .DoLn: mov bl,CHRTLEN   ; Each line will consist of 32 chars
    .DoChr: stosb   ; Note that there’s no REP prefix!

    jcxz AllDone    ; When the full set is printed, quit
    inc al          ; Bump the character value in AL up by 1
    dec bl          ; Decrement the line counter by one
    loopnz .DoChr       ; Go back & do another char until BL goes to 0
    add edi,(COLS-CHRTLEN) ; Move EDI to start of next line
    jmp .DoLn       ; Start display of the next line

    ; Having written all that to the buffer, send the buffer to the console:
    AllDone:
        call Show; Refresh the buffer to the console

    Exit:           ; Code for Exit Syscall
        mov eax,1
        mov ebx,0   ; Return a code of zero
        int 80H     ; Make kernel call
