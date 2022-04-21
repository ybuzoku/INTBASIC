
funTbl:
;Use PASCAL strings to know how long the comparisons need to be
;All function pointers are saved as distances from the head
; of the function table
;BASIC instructions are space terminated
;Interpreter instructions are null terminated
    db 4, "LET"     ;DONE
    dw oldSchoolAssignemnt - funTbl

    db 5, "NEW",0     ;DONE
    dw newProgram - funTbl 

    db 7, "CLEAR",0   ;DONE
    dw newProgram - funTbl 

    db 6, "LIST",0    ;DONE
    dw listProgram - funTbl 

    db 5, "RUN",0     ;DONE
    dw runProgram - funTbl

    db 8, "PRINT$ "    ;Not implemented yet
    dw printStatement - funTbl

    db 7, "PRINT "    ;DONE
    dw printStatement - funTbl

    db 3, "? "        ;DONE, alias Print
    dw printStatement - funTbl

    db 7, "INPUT "
    dw getInput - funTbl

    db 4, "IF "      ;DONE, needs to be tested
    dw handleIf - funTbl

    db 6, "GOTO "    ;DONE
    dw goto - funTbl

    db 7, "GOSUB "
    dw gosub - funTbl

    db 8, "RETURN "
    dw return - funTbl

    db 8, "RETURN",0
    dw return - funTbl

    db 5, "FOR "
    dw forLoop - funTbl

    db 6, "NEXT",0
    dw next - funTbl

    db 6, "NEXT "
    dw next - funTbl

    db 7
whileStr:
    db "WHILE "
    dw while - funTbl

    db 6, "WEND "
    dw wend - funTbl    
    db 6, "WEND",0
    dw wend - funTbl   
thenStr:
    db 6, "THEN "    ;DONE
    dw badCmd - funTbl
elseStr:
    db 6, "ELSE "    ;DONE
    dw badCmd - funTbl

    db 8, "SYSTEM",0  ;DONE
    dw returnToDOS - funTbl

    db 5, "CLS",0     ;DONE
    dw cls - funTbl
    db 5, "CLS "      ;DONE
    dw cls - funTbl

    db 7, "DEBUG",0   ;DONE
    dw dbgr - funTbl

    db 6, "TRON",0    ;DONE
    dw tron - funTbl

    db 7, "TROFF",0   ;DONE
    dw troff - funTbl

    db 5, "END "     ;DONE
    dw endProg - funTbl
    db 5, "END",0     ;DONE
    dw endProg - funTbl

    db 6, "STOP "    ;DONE
    dw endProg - funTbl
    db 6, "STOP",0    ;DONE
    dw endProg - funTbl

    db 8, "ESCAPE "  ;DONE
    dw endProg - funTbl
    db 8, "ESCAPE",0  ;DONE
    dw endProg - funTbl

    db 7, "EPEEK "
    dw memRead - funTbl

    db 7, "EPOKE "
    dw memWrite - funTbl

    db 6, "PEEK "
    dw byteRead - funTbl

    db 6, "POKE "
    dw byteWrite - funTbl

    db 5, "REM "
    dw remark - funTbl
    db 3, "' "
    dw remark - funTbl

    db -1    ;Demarkate the end of the table
;End of Table
badCmd:
    lea rbp, syntax
    call criticalError 
endProg:
    jmp runProgram.endProgramPoint
tron:
    or byte [stateByte], traceBit   ;Set the traceBit
    ret
troff:
    and byte [stateByte], ~traceBit ;Clear the traceBit
    ret
notWrapper:
    xchg bx, bx
    jmp handleAlgebraicExpression.not
memRead:
memWrite:
byteRead:
byteWrite:
    ret
remark:
;Comment code, keep looping until end of line
    lodsb
    test al, al 
    jnz remark
    dec rsi ;When al = 0, rsi points past it, move it back by one
    ret

oldSchoolAssignemnt:
;Assign with a LET directive
;rsi points to first char AFTER function name
    call spaceSkip  ;Goto var assignment as if at start of line
variableAssignment: ;Assignment without a LET directive
    ;Establish if the string is a variable assignment or not
    ;rsi points to start of string
    call getVarNameLength   ;Get the variable name length
    mov rdi, rsi    ;Save ptr to start of string in rdi
    add rsi, rcx    ;Go to end of string
    call spaceSkip  ;Skip spaces after the end of the var name
    lodsb   ;Get the first char after the spaces. This must be a =
    cmp al, "="
    jne .syntaxError
    mov rsi, rdi    ;Return rsi to the start of the string name
    add rsi, rcx    ;Go to end of var name
    dec rsi
    lodsb   ;Get last char into al and inc rsi
    cmp al, "$"
    je .stringAssignment
    call spaceSkip  ;Skip any spaces
    inc rsi         ;Go past the equality sign
    call spaceSkip  ;Skip any spaces
    cmp byte [rsi], 22h ;Open speech mark
    je .typError    ;Integers cant have speechmarks
    call handleAlgebraicExpression  ;Get the result of the expression into rax
    mov rsi, rdi    ;Return the start of the string into rsi
    call setNumericVariable
    ret
.stringAssignment:
;This simply copies the string which is either speech mark, 0 or : terminated
;First allocate a string
;rsi = First char after the end of the variable name
;rdi = start of variable name 
;rcx = char count for var name
    call spaceSkip  ;Skip any spaces
    inc rsi         ;Go past the equality sign
    call spaceSkip  ;Skip any spaces
    cmp byte [rsi], 22h ;Open speechmark check again
    jne .typError    ;Assigning a number to a string is a type error
    ;rsi now points to the start of the string to save
    inc rsi ;Go past the speech mark
    mov rdx, rsi    ;save start of string data in rdx
    mov rsi, rdi
    push rdi
    call setStringVariable
    pop rsi ;Save the start of the assignment in rsi
    ret

.syntaxError:
    lea rbp, syntax ;Syntax error, keyword a bit confused
    jmp criticalError
.typError:
    lea rbp, typeError
    jmp criticalError


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
    xor eax, eax,
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
    ;Runs the machine in indirect mode
    or byte [stateByte], indirectBit    ;Entering indirect mode
    ;rsi must point to the first line
    mov dx, word [firstLinNum]
    mov word [currentLine], dx ;Reset the current line back to the start
    mov rbx, qword [firstLinPtr]
    lea rsi, qword [rbx + progLineBlock.sLine]
    call runLine
.endProgramPoint:
    and byte [stateByte], ~indirectBit  ;Exit indirect mode
    jmp mainLoop    ;Resets the stack if exit mid loop to avoid stkoverflow

printStatement:
;Strings must be "" delimited or a string variable must be used
;rsi points to first char AFTER function name
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
    ;Check if it is a string var or a unary function
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
    je .printStart
    dec rsi ;Go back a step
    jmp short .psvexit
.continue:
    call spaceSkip
    jmp .printStart
getInput:
;Take a string as a prompt
;rdi points just past the end of the command line
;rsi points to first char AFTER function name
;Input prompt strings must be speech mark delimited on both sides!
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
    ;This will sanitise in direct mode meaning input cannot have any more statements
    ; after it.
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
    call handleAlgebraicExpression  ;Get the result of the expression into rax
    mov rsi, rdi    ;Return the start of the string into rsi
    call setNumericVariable
    jmp short .commonExit
.handleString:
    ;IF a string variable, come here
    ;rdi has the start of the variable name

    ;rdx must point to the start of the string
    ;rsi must point to the start of the variable name
    mov rdx, rsi
    mov rsi, rdi    ;Return start of user name in rsi
    call setStringVariable
.commonExit:
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
