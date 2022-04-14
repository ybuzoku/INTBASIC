prompt  db "Ok",0Ah,0Dh,0
mainmsg db "SCR INTBASIC/64 v0.1",0Ah,0Dh,0
bytemsg db " Bytes free",0Ah,0Dh,0
crlf    db 0Ah,0Dh,0
errmsg  db "Error",0Ah,0Dh,0
numbers db "0123456789"
;startVarChars db "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ;Valid starting chars for a var name
;numStartVarChars equ $ - startVarChars
varChrs db "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789%$" ;Valid inner chars for var name
numVarChars equ $ - varChrs
;% => Integer variable (8 bytes)
;! => Single-Precision, Unused and ignored
;# => Double-Precision, Unused and ignored
;$ => String variable

;Error Messages
noMem   db "Out of memory",0Ah,0Dh,0
syntax  db "Syntax error",0Ah,0Dh,0
typeError   db "Type mismatch",0Ah,0Dh,0
lineNoXist  db "Undefined line number",0Ah,0Dh,0
breakmsg db "Break in ",0
stkOvflw db "Stack overflow",0Ah,0Dh,0

noWend   db "WHILE without WEND", 0Ah, 0Dh, 0
noWhile  db "WEND without WHILE", 0Ah, 0Dh, 0
noFor    db "NEXT without FOR", 0Ah, 0Dh, 0
noNext   db "FOR without NEXT", 0Ah, 0Dh, 0
noReturn db "RETURN without GOSUB", 0Ah, 0Dh, 0
uknowner db "Unprintable error", 0Ah, 0Dh, 0

divZer   db "Division by zero", 0Ah, 0Dh, 0