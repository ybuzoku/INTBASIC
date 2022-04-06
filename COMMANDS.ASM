
funTbl:
;Use PASCAL strings to know how long the comparisons need to be
;All function pointers are saved as distances from the head
; of the function table
    db 4, "LET"     ;DONE
    dw oldSchoolAssignemnt - funTbl
    db 4, "NEW"     ;DONE
    dw newProgram - funTbl 

    db 5, "LIST"
    dw listProgram - funTbl 

    db 4, "RUN"
    dw runProgram - funTbl

    db 6, "PRINT"    ;ALMOST DONE
    dw printStatement - funTbl

    db 2, "?"        ;ALMOST DONE
    dw printStatement - funTbl

    db 6, "INPUT"
    dw getInput - funTbl

    db 3, "IF"
    dw handleIf - funTbl

    db 5, "GOTO"
    dw fancyJmp - funTbl

    db 7, "SYSTEM"
    dw returnToDOS - funTbl

    db 4, "FOR"
    dw forLoop - funTbl

    db 4, "CLS"     ;DONE
    dw cls - funTbl

    db 6, "DEBUG"
    dw dbgr - funTbl

    db -1    ;Demarkate the end of the table
oldSchoolAssignemnt:
;
    movzx ecx, byte [rdi]
    add rsi, rcx
    call spaceSkip  ;Goto var assignment as if at start of line
    jmp executeExpression.variableAssignment
newProgram: 
;Simply reset the program pointers
    lea rax, section.programArea.vstart
    mov qword [minMemAddr], rax
    mov qword [lastBlock], rax  ;Start writing at this location
    mov qword [mcbChain], rax   ;Create a mock MCB here
    mov byte [rax + memBlock.bSignature], lastMemBlock
    mov word [rax + memBlock.wBlockSize], 0 ;Dummy block, no size, gets overwritten
    xor eax, eax
    mov byte [strLen], al
    lea rdi, inString
    mov ecx, maxLineLen
    rep stosb
    mov byte [currentLine], 10  ;Default to line 10
    dec rax ;rax = -1
    mov qword [firstLinPtr], rax ;No program in memory
    mov word [firstLinNum], ax
    ret
listProgram:
;Go line by line and echo the program lines, inserting a crlf after each
;First print the line number, then add a space
    mov al, 2
    ret
runProgram:
;Go to each line, one at a time, skip the line number and execute the expr
;First thing it does, takes the first line number and moves it to current line number
    mov al, 3
    ret
printStatement:
;Strings must be "" delimited or a string variable must be used (unsupported rn)
;rdi points to the command length
    movzx ecx, byte [rdi]
    add rsi, rcx
.printStart:
    call spaceSkip  ;move rsi to the start of the expression
    lodsb
    cmp al, 022h    ;22h = ASCII Speechmarks
    je .stringPrint
    ;Here we check if the first char is ASCII, if it is, check if its a string var
    cmp al, "A"
    jb .printExpr
    cmp al, "Z"
    jb .printStringVar
.printExpr:
    dec rsi ;Return to the start of the string
    call handleAlgebraicExpression ;Gets value of a var and/or algebraic operation
    call printdecimalword
    lea rbp, crlf
    call ttyOutString
    ret
.printStringVar:
    ;Check if it is a string var
    call getVarNameLength
    call getVarType
    cmp ebx, strEquate
    jne .printExpr  ;rsi points to the same point as initially
    call findVariable   ;ecx has string length, get block ptr in rbx
    lea rsi, qword [rbx + stringBlock.string]
.stringPrint:
    lodsb
    cmp al, 0
    je .psvexit
    cmp al, ":"
    je .psvexit
    cmp al, 022h    ;Close Speech marks
    je .psvexit
    cmp al, ";"     ;Semicolon means print next section on same line
    je .printStart
    call ttyOutChar
    jmp short .stringPrint
.psvexit:
    dec rsi
    lea rbp, crlf
    call ttyOutString
    ret

getInput:
;Take a string as a prompt
    mov al, 5
    ret
handleIf:
;Evaluate the string after IF is greater than 0, THEN goto line x
;IF exp1 THEN exp2
    mov al, 6
    ret
fancyJmp:
;GOTO, the hell of every dumb high level programmer
    mov al, 7
    ret
returnToDOS:
    mov al, 8
    ret
forLoop:
    mov al, 9
    ret
cls:
    jmp ttyClear
dbgr:
    int 38h
    ;Reconnect CTRL+BREAK handler
    ret
