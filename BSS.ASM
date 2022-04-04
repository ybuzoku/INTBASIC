stack       resq 200h - 8  ;Save 4Kb stack space
stacktop    resq 1

maxVars     equ 26
varTbl      resq maxVars    ;Variables A-Z

maxLineLen  equ 256
inString    resb maxLineLen        ;256 character input string

maxProgLen  equ 1000    ;Max 1000 lines of code
progSize    equ maxLineLen*maxProgLen

progspace   resb progSize

strLen      resb 1  ;Counter for number of chars entered in string
stateByte   resb 1  ;TROFF/TRON etc, unused for now
bssLen: ;Needed to compute the resident portion load location