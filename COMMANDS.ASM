cleanProgram:
    lea rdi, progspace  ;Point to program area
    mov ecx, progSize/8
    xor eax, eax
    rep stosq         ;Clear program area
    ret
funTbl:
    db 4,"NEW"
    dq cleanProgram
    
    db 5,"LIST"

    db 4,"RUN"

    db 6,"PRINT"

    db 6,"INPUT"

    db 3,"IF"

    db 5,"GOTO"

    db 7,"SYSTEM"

    db 1