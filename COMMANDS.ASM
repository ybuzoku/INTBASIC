
funTbl:
;Use PASCAL strings to know how long the comparisons need to be
;All function pointers are saved as distances from the head
; of the function table
    db 4, "LET"     ;DONE
    dw oldSchoolAssignemnt - funTbl

    db 4, "NEW"     ;DONE
    dw newProgram - funTbl 

    db 6, "CLEAR"   ;DONE
    dw newProgram - funTbl 

    db 5, "LIST"    ;DONE
    dw listProgram - funTbl 

    db 4, "RUN"     ;DONE
    dw runProgram - funTbl

    db 7, "PRINT$"    ;Not implemented yet
    dw printStatement - funTbl

    db 6, "PRINT"    ;DONE
    dw printStatement - funTbl

    db 2, "?"        ;DONE, alias Print
    dw printStatement - funTbl

    db 6, "INPUT"
    dw getInput - funTbl

    db 3, "IF"      ;DONE, needs to be tested
    dw handleIf - funTbl

    db 5, "GOTO"    ;DONE
    dw fancyJmp - funTbl

    db 7, "SYSTEM"  ;DONE
    dw returnToDOS - funTbl

    db 4, "FOR"
    dw forLoop - funTbl

    db 4, "CLS"     ;DONE
    dw cls - funTbl

    db 6, "DEBUG"   ;DONE
    dw dbgr - funTbl

    db 5, "TRON"    ;DONE
    dw tron - funTbl

    db 6, "TROFF"   ;DONE
    dw troff - funTbl

    db 4, "END"     ;DONE
    dw endProg - funTbl

    db 5, "STOP"    ;DONE
    dw endProg - funTbl

    db 7, "ESCAPE"  ;DONE
    dw endProg - funTbl
thenStr:
    db 5, "THEN"    ;DONE
    dw badCmd - funTbl
elseStr:
    db 5, "ELSE"    ;DONE
    dw badCmd - funTbl

    db 6, "EPEEK"
    dw memRead - funTbl

    db 6, "EPOKE"
    dw memWrite - funTbl

    db 5, "PEEK"
    dw byteRead - funTbl

    db 5, "POKE"
    dw byteWrite - funTbl

    db -1    ;Demarkate the end of the table
;End of Table
badCmd:
    lea rbp, syntax
    call criticalError 
endProg:
    jmp mainLoop
tron:
    or byte [stateByte], traceBit   ;Set the traceBit
    ret
troff:
    and byte [stateByte], ~traceBit ;Clear the traceBit
    ret
memRead:
memWrite:
byteRead:
byteWrite:
    ret

oldSchoolAssignemnt:
;
    movzx ecx, byte [rdi]
    dec ecx
    add rsi, rcx
    call spaceSkip  ;Goto var assignment as if at start of line
    jmp executeExpression.variableAssignment
newProgram: 
;Simply reset the program pointers
    lea rax, section.programArea.vstart
    mov qword [minMemAddr], rax
    mov qword [lastBlock], rax  ;Start writing at this location
    mov qword [mcbChain], rax   ;Create a mock MCB here

    mov rdx, rax
    mov cx, word [rax + memBlock.wBlockSize]
    mov rdi, rax
    xor al, al
    rep stosb   ;Sanitise the old first allocation

    mov byte [rdx + memBlock.bSignature], lastMemBlock
    mov word [rdx + memBlock.wBlockSize], 0 ;Dummy block, no size, gets overwritten
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
    mov rbx, qword [firstLinPtr]    ;Get a pointer to the first program line
.printLines:
    lea rbp, crlf           ;New line
    call ttyOutString
    cmp rbx, -1
    je .exit
    movzx eax, word [rbx + progLineBlock.wLineNum]
    call printdecimalword
    mov al, " "
    call ttyOutChar ;Print a space
    lea rbp, qword [rbx + progLineBlock.sLine]  ;Null terminated string
    call ttyOutString
    mov rbx, qword [rbx + progLineBlock.qPtr]   ;Walk list of program lines
    jmp short .printLines
.exit:
    ret
runProgram:
;Go to each line, one at a time, skip the line number and execute the expr
;First thing it does, resets the stack 
; and takes the first line number and moves it to current line number
    lea rsp, stacktop
    mov rbx, qword [firstLinPtr]    ;Get a pointer to the first program line
.runLines:
    cmp rbx, -1 ;Are we at the end?
    je .exit    ;Yes, return to the prompt
    movzx eax, word [rbx + progLineBlock.wLineNum]
    mov word [currentLine], ax  ;Gone to new line
    lea rsi, qword [rbx + progLineBlock.sLine]  ;Point to the instruction
    call spaceSkip  ;Goto first char
    ;xchg bx, bx
    call mainProcessing
.rl0:
    mov rbx, qword [rbx + progLineBlock.qPtr]   ;Walk list of program lines
    jmp short .runLines
.exit:
    jmp mainLoop

printStatement:
;Strings must be "" delimited or a string variable must be used
;rdi points to the command length
    movzx ecx, byte [rdi]
    dec ecx ;This gives instruction name + 1
    add rsi, rcx
.printStart:
    call spaceSkip  ;move rsi to the start of the expression
    lodsb
    test al, al     ;Is this a null string?
    jz .psvexit

    cmp al, 022h    ;22h = ASCII Speechmarks
    je .stringPrint
    ;Here we check if the first char is ASCII, if it is, check if its a string var
    cmp al, "A"
    jb .printExpr
    cmp al, "Z"
    jb .printStringVar
.printExpr:
    dec rsi ;Return to the start of the string
.printExpr1:    ;Return without dec rsi
    call handleAlgebraicExpression ;Gets value of a var and/or algebraic operation
    call printdecimalword
    call spaceSkip
    jmp short .stringPrint
.printStringVar:
    ;Check if it is a string var
    dec rsi
    call getVarNameLength
    call getVarType
    cmp ebx, strEquate
    jne .printExpr1  ;rsi points to the same point as initially
    call findVariable   ;ecx has string length, get block ptr in rbx
    push rbp
    lea rbp, qword [rbx + stringBlock.string]
    call ttyOutString
    pop rbp
    add rsi, rcx    ;Go past variable
    call spaceSkip
.stringPrint:
    lodsb
    cmp al, 0
    je .psvexit
    cmp al, ":"
    je .psvexitColon
    cmp al, 022h    ;Close Speech marks, check next char
    je .closespeechmarks
    cmp al, ";"     ;Semicolon means print next section on same line
    je .continue
    call ttyOutChar
    jmp short .stringPrint
.openSpeechMark:
    inc rsi ;Go back a char
.psvexitColon:
    dec rsi ;Go back a char
.psvexit:
    lea rbp, crlf
    call ttyOutString
    ret
.closespeechmarks:
    call spaceSkip
    lodsb
    cmp al, ";" ;only exception to exiting if next non space char is a semicolon
    je .stringPrint
    dec rsi ;Go back a step
    jmp short .psvexit
.continue:
    call spaceSkip
    jmp .printStart
getInput:
;Take a string as a prompt
;rdi points just past the end of the command line
;Input prompt strings must be speech mark delimited on both sides!
    movzx ecx, byte [rdi]
    dec ecx
    add rsi, rcx
    call spaceSkip
    ;Now check to see if the user has specified a custom prompt
    lodsb   ;Get first symbol and go past it
    cmp al, 22h ;Speechmark?
    jne .defaultPrompt ;If no speechmark, print default prompt
.customPrompt:
    mov rdi, rsi    ;Save start of string in rdi
.cp0:
    lodsb           ;Now search for end of string speech marks or null terminator
    cmp al, 22h     ;Is al a speech mark?
    je .printCustomPrompt
    test al, al     ;Is al null?
    jnz .cp0        ;No, keep searching for terminator
.error:
    lea rbp, syntax
    jmp criticalError
.printCustomPrompt:
    mov rsi, rdi    ;rsi points to the first char of the string
.pcp0:
    lodsb
    cmp al, 22h     ;Speechmark?
    je .stopPrompt
    call ttyOutChar
    jmp short .pcp0
.stopPrompt:
    call spaceSkip  ;Skip spaces
    lodsb   ;Get first non space char after closing speechmark
    cmp al, ";" ;Semicolon means no default prompt
    je .noDefaultPrompt
    cmp al, "," ;Comma also means no default prompt
    je .noDefaultPrompt
.defaultPrompt:
    dec rsi
    mov al, "?"
    call ttyOutChar
.noDefaultPrompt:
    mov al, " " ;space
    call ttyOutChar
    call spaceSkip  ;Skip spaces after default supressor to get to var name
    call getVarNameLength   ;Get var name length in ecx
    lea rdi, digitString    ;Buffer has 48 chars, string names are max 40
    call strcpy     ;rsi points to var name
    push rdi    ;rdi points to first char of variable
    push rcx
    call getLineInput   ;Get input from the user in inString, null terminated
    pop rcx
    pop rdi 
    mov rsi, rdi    ;Save the start of the var name in rsi
    add rsi, rcx    ;Go to end of var
    dec rsi
    lodsb   ;Are we a string variable?
    lea rsi, inString   ;Move rsi to start of user input
    cmp al, "$"
    je .handleString
.handleNumeric:
    xchg bx, bx
    call handleAlgebraicExpression  ;Get the result of the expression into rax
    mov rsi, rdi    ;Return the start of the string into rsi
    call setNumericVariable
    ret
.handleString:
    ;IF a string variable, come here
    ;rdi has the start of the variable name

    ;rdx must point to the start of the string
    ;rsi must point to the start of the variable name
    mov rdx, rsi
    mov rsi, rdi    ;Return start of user name in rsi
    call setStringVariable
    ret
handleIf:
;Evaluate the string. The IF,THEN/GOTO,ELSE statement must ALL be on one line
;IF exp1 THEN statement ELSE statement
;IF exp1 GOTO linenumber ELSE statement
    movzx ecx, byte [rdi]
    dec ecx
    add rsi, rcx

    call spaceSkip
    call handleAlgebraicExpression
    test rax, rax  ;If this is 0, go to the else
    jnz .else
    call spaceSkip
    ;Now check if it is a THEN or a GOTO
    ;If it is a THEN, go past the then and let mainProcessing handle it
    ;If it is a GOTO, dont go past the GOTO and let mainProcessing handle it
    ;In both cases JUMP to mainProcessing to avoid stack growth
    ;If no GOTO or THEN, then syntax error
    lodsd   ;Get the whole word
    cmp eax, "THEN"
    je .mp0   ; Go past THEN, to process statement
    cmp eax, "GOTO"
    jne .error
    sub rsi, 4  ;Go back four spaces to process GOTO
.mp0:
    lea rax, mainProcessing
    push rax
    ret 3*8 ;Align stack as expected
.else:
    mov eax, "ELSE" ;Lucky for us, ELSE fits in eax
.e0:
    inc rsi
    cmp byte [rsi], 0   ;End of command line?
    jz .noElse
    cmp byte [rsi], ":" ;End of command line portion?
    jz .noElse0
    cmp dword [rsi], eax
    jne .e0
;If we are else, first move rsi past the else
    add rsi, 4  ;We are past the else now
    call spaceSkip
    ret 3*8 ;Align stack as expected
.noElse0:
;If there is no ELSE, simply ret
    dec rsi ;Ensure it is caught by the main findOtherExpressionsOnLine command
.noElse:
    ret
.error:
    lea rbx, syntax
    jmp criticalError

fancyJmp:
;GOTO
;rdi points just past the end of the command line
    movzx ecx, byte [rdi]
    dec ecx
    add rsi, rcx
    call spaceSkip  ;Skip all preceeding spaces
    call handleAlgebraicExpression  ;Turn the expression into a number in ax
    movzx edx, ax   ;Line number into dx
    call searchForProgramLine   ;Get pointer to line in rbx
    cmp rbx, -1
    je .unknownLineNumber

    lea rdx, runProgram.runLines    ;New line pointer in rbx
    push rdx    ;Run lines return address
    ;xchg bx, bx 
    ret 3*8     ;pop three qwords off of the stack (old return addresses)
.unknownLineNumber:
    lea rbp, lineNoXist
    call ttyOutString
    jmp mainLoop
forLoop:
    mov al, 9
    ret
;==========================================================:
;==========================================================:
;==========================================================:
;          Functions Related to Program Management         :
;==========================================================:
;==========================================================:
;==========================================================:
returnToDOS:
    mov al, 07h
    call ttyOutChar
    jmp start   ;Reset the interpreter
cls:
    jmp ttyClear
dbgr:
    ;Hook int 40h to main prog EP to allow returning 
;First call to get default BIOS segement selector and attribute word
    mov bl, 40h
    mov eax, 0F007h ;Get the descriptor
    int 35h
    mov esi, eax    ;Move segment selector info to esi
    mov ecx, 40h    ;Interrupt number
;dx preserves the attribute word
    lea rbx, .farReturn  ;Pointer passed in
    mov eax, 0F008h ;Set descriptor
    int 35h
    int 38h ;Call debugger
.farReturn:
    ;Reconnect CTRL+BREAK handler
    mov rsp, stacktop   ;Immediately reset stack
    lea rdi, ctrlBreakHandler
    mov al, 3Bh
    call setHandler
    
    lea rbp, crlf
    call ttyOutString
    jmp mainLoop
