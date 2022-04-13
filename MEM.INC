
progLineBlockType   equ 0   ;Program Line
varBlockType        equ 1   ;Variable block
datBlockType        equ 2   ;Data block (i.e. a string block)

notLastMemBlock equ "t" ;Used for blocks that are not the last block
lastMemBlock    equ "r" ;Used by the last block to indicate end of chain

%macro memBlockM 0 ;Memory block Macro
    .bSignature resb 1      ;Valid Signature
    .wBlockSize resw 1      ;Total block size in bytes
    .bBlockType resb 1      ;Block type, program line, variable or string
%endmacro

struc memBlock
    memBlockM
endstruc

struc progLineBlock
    memBlockM               ;Common memory block header
    .wLineNum   resw 1      ;Line number, up to 65535
    .qPtr       resq 1      ;Pointer to the next line, or -1 if last line
    .sLine      resb maxLineLen  ;Maximum length 255, keep null char but 
    ;                             NOT LINE NUMBER OR PRECEEDING SPACES
endstruc

struc varBlock
    memBlockM               ;Common memory block header
    .qValue     resq 1      ;One value qword
    .sVarName:              ;Up to 40 chars for the var name
endstruc

struc stringBlock
    memBlockM
    .string     resb maxLineLen    ;Strings allocate 256 chars
    .sVarName:              ;Up to 40 chars for the var name
endstruc

;Variable equates
intEquate   equ 0
strEquate   equ 1

;State byte equates
breakBit    equ 1    ;Set means on
traceBit    equ 2    ;Set means TRON, Clear means TROFF
indirectBit equ 4    ;Set means indirect/program mode, Clear means direct/line mode
ctrlFlow    equ 8    ;Set means do not find other expression on current line

;Control Instruction Signatures
WHILEsig    equ 055h
FORsig      equ 05Ah
GOSUBsig    equ 0A5h
;Control stack data structures

struc forStruct
    .specQword  resq 1  ;Special qword (see function description)
    .cntrPtr    resq 1  ;Pointer to counter variable
    .limitValue resq 1  ;At what value, or after, do we stop the loop 
    .stepValue  resq 1  ;By how much do we increase on each iteration
;Special qword:
; Byte 7 = Offset into the line for next instruction after FOR
; Bytes[6:5] = Line number of portion after FOR (either FOR line or line after FOR)
; Byte 4 = Offset into the line for next instruction after NEXT
; Bytes[3:2] = Line number of portion after NEXT (either NEXT line or line after NEXT)
; Byte 1 = Parity check sum for the qword, makes the sum of the bytes in qword 0
; Byte 0 = FOR signature
endstruc

struc whileStruct
    .specQword  resq 1  ;Special qword
;Special qword:
; Byte 7 = Offset into the line for the condition to evaluate
; Bytes[6:5] = Line number of WHILE 
; Byte 4 = Offset in line for either first : after WEND or ASCII NULL (end of line)
; Bytes[3:2] = Line number of WEND
; Byte 1 = Parity check sum for the qword, makes the sum of the bytes in qword 0
; Byte 0 = WHILE signature
endstruc

struc gosubStruct
    .specQword  resq 1  ;Special qword
;Special qword:
; Byte 7 =  Offset in line for either first : after GOSUB or ASCII NULL (end of line)
; Bytes[6:5] = Line number of GOSUB 
; Bytes[4:2] = 055AA55h space filler signature
; Byte 1 = Parity check sum for the qword, makes the sum of the bytes in qword 0
; Byte 0 = GOSUB signature
endstruc

;Stack based macros
%macro makeSpaceOnStack 1
    ;The argument is to specify how much space to make on the stack
    ;It will check to ensure that we dont go past the stack minimum.
    ;If we do, call stack overflow!
    pop rax    ;Get the return address qword into rax
    shl %1, 3  ;Multiply argument register by 8
    sub rsp, %1 ;Clear space on the stack plus one qword for ret addr
    lea rbp, stack
    cmp rsp, rbp
    ja .macroNotOverflow ;If rsp above overflow buffer, its oki
    lea rbp, stkOvflw
    jmp criticalError
.macroNotOverflow:
    ;rsp now points to the start of the cleared space
    ;Put the return address back on the stack
    push rax
%endmacro

%macro cleanSpaceOnStack 1
    ;The argument is to specify how much space to reclaim from the stack
    pop rax
    shl %1, 3   ;Multiply argument register by 8
    add rsp, %1
    push rax
%endmacro