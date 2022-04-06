prompt  db "Ok",0Ah,0Dh,0
mainmsg db "SCR 64-BASIC v0.1",0Ah,0Dh,0
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
noMem   db "Out of Memory",0Ah,0Dh,0
syntax  db "Syntax Error",0Ah,0Dh,0
typeError   db "Type mismatch",0Ah,0Dh,0
lineNoXist  db "Undefined line number",0Ah,0Dh,0