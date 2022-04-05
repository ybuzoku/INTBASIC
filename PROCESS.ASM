saveExecuteLine:
;This function will execute the line if it is an interactive expression
; or store it in the program if it has a line number
    call decimalToHex   ;Check to see if we have a valid line number
    xchg bx, bx
    test ax, ax
    jnz .saveLine
;Here we execute the line
    call executeExpression
    ret
.saveLine:

executeExpression:
;rsi must point to the start of the portion of the line to execute
    call spaceSkip  ;Skip any leading spaces
    cmp byte [rsi], 0   ;Null terminated line, empty line?
    je .exit
    ;rsi now points to function
    lea rdi, funTbl     ;Point rdi to the function table
.functionFinderLoop:
    mov cl, byte [rdi]  ;Get the string length  
    cmp cl, -1  ;-1 is the end of table marker, either Var assignment or error
    je .variableAssignment 
    push rsi    ;Save ptr to start of string on stack 
    movzx ecx, cl
    inc rdi             ;Goto first char in function name
    rep cmpsb
    je .functionFound
    add rdi, 8  ;Skip unnecessary function pointer
    pop rsi     ;Return ptr to start of string pointer from stack
    jmp short .functionFinderLoop
.functionFound:
    ;Function found! Execute!
    ;rsi points to start of expression to evaluate for function
    ;rdi points to function pointer

.exit:
    ret

.variableAssignment:
    ;Establish if the string is a variable assignment or not
    ;rsi points to start of string
    call getVarNameLength   ;Get the variable name length
    mov rdi, rsi    ;Save ptr to start of string in rdi
    add rsi, rcx    ;Go to end of string
    call spaceSkip  ;Skip spaces after the end of the var name
    lodsb   ;Get the first char after the spaces. This must be a =
    cmp al, "="
    jne .exitError
    mov rsi, rdi    ;Return rsi to the start of the string name
    add rsi, rcx    ;Go to end of var name
    dec rsi
    lodsb           ;Get the last char into al
    cmp al, "$"     ;Are we a string variable?
    je .stringAssignment
    call spaceSkip  ;Skip any spaces
    inc rsi         ;Go past the equality sign
    call spaceSkip  ;Skip any spaces
    lodsb           ;Get first symbol after equality into al
    dec rsi         ;Go back to the start of the string
    cmp al, "0" 
    jb .exitError   ;Are we a bona-fide digit?
    cmp al, "9"
    ja .exitError
    call decimalToHex   ;Get the value in rax
    mov rsi, rdi    ;Return the start of the string into rsi
    call setNumericVariable
    ret

.exitError:
    mov rbp, syntax ;Syntax error, keyword a bit confused
    jmp criticalError

.stringAssignment: