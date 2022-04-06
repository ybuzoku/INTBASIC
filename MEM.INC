
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
intEquate  equ 0
strEquate  equ 1