oflowbuff   resq 10        ;10 Qwords of overflow buffer
;rsp should never get here when operating in a program.
;Only acceptable to be used when processing a line
stack       resq 200h - 8 - 10*8  ;Save total 4Kb stack space
stacktop    resq 1

maxLineLen  equ 256
inString    resb maxLineLen         ;256 character input string

;This string is used for printing long numbers and saving
; the variable names for string comparisons
digitStringLen  equ 48
digitString resb digitStringLen     

minMemAddr  resq 1  ;Pointer from where to start allocating memory blocks
maxMemAddr  resq 1  ;Pointer to the byte past which we cannot allocate anything
;==============================================================================
;This is the SDA for each program and must be included in the program area
; once we add the ability to save the program to disk.
;==============================================================================

;void* mcbChain, lastBlock, firstLinPtr = -1 => New program, empty entries

strLen      resb 1  ;Counter for number of chars entered in string
stateByte   resb 1  ;Bit 0 => Break Set, stop processing after end of current line
mcbChain    resq 1  ;Pointer to the start of the chain
lastBlock   resq 1  ;Pointer to the last block
firstLinPtr resq 1  ;Pointer to the programs' first line 
firstLinNum resw 1  ;Line number of the first line of the program
currentLine resw 1  ;Currently being executed line number

bssLen: ;Needed to compute the resident portion load location