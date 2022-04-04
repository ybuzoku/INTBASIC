stack       resq 200h - 8  ;Save 4Kb stack space
stacktop    resq 1

maxLineLen  equ 256
inString    resb maxLineLen        ;256 character input string

strLen      resb 1  ;Counter for number of chars entered in string
stateByte   resb 1  ;TROFF/TRON etc, unused for now
mcbChain    resq 1  ;Pointer to the start of the chain
lastBlock   resq 1  ;Pointer to the last block
firstLinPtr resq 1  ;Pointer to the programs' first line 
firstLinNum resw 1  ;Line number of the first line of the program
maxMemAddr  resq 1  ;Pointer to the byte past which we cannot allocate anything
bssLen: ;Needed to compute the resident portion load location