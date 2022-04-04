
progLineBlockType   equ 0   ;Program Line
varBlockType        equ 1   ;Variable block
datBlockType        equ 2   ;Data block (i.e. a string block)

notLastMemBlock equ "T" ;Used for blocks that are not the last block
lastMemBlock    equ "R" ;Used by the last block to indicate end of chain

%macro memBlockM 0 ;Memory block Macro
    .bSignature resb 1      ;Valid Signature
    .wBlockSize resw 1      ;Total block size in bytes
    .bBlockType resb 1      ;Block type, program line or variable
%endmacro

struc memBlock
    memBlockM
endstruc

struc progLineBlock
    memBlockM               ;Common memory block header
    .wLineNum   resw 1      ;Line number, up to 65535
    .qPtr       resq 1      ;Pointer to the next line, or -1 if last line
    .sLine      resb maxLineLen    ;Maximum length 255, keep null char
endstruc

varTypeNum  equ 0   ;Variable is a number
varTypStr   equ 1   ;Variable is a string

struc varBlock
    memBlockM               ;Common memory block header
    .sVarName   resb 40     ;Up to 40 chars for the var name
    .bVarType   resb 1      ;String or num
    .qValue     resq 1      ;One qword, either value or pointer to string
endstruc

struc stringBlock
    memBlockM
    .string     resb maxLineLen    ;Strings of up to 256 chars, OK
endstruc