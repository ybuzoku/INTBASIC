executeExpression:
;rsi must point to the start of the portion of the line to execute
    call spaceSkip  ;Skip any leading spaces
    cmp byte [rsi], 0   ;Null terminated line, empty line?
    je .exit
    ;rsi now points to function
    lea rdi, funTbl     ;Point rdi to the function table
.functionFinderLoop:
    movzx ecx, byte [rdi]  ;Get the string length  
    cmp cl, -1  ;-1 is the end of table marker, either Var assignment or error
    je .variableAssignment 
    push rsi    ;Save ptr to start of string on stack 
    push rdi
    inc rdi             ;Goto first char in function name
    repe cmpsb
    pop rdi
    pop rsi     ;Return ptr to start of string pointer from stack
    test cl, cl ;Did all the chars match?
    jz .functionFound
    movzx rax, byte [rdi]    ;Skip unnecessary function pointer
    add rax, 2      ;Add 2 to skip relative pointer
    add rdi, rax
    jmp short .functionFinderLoop
.functionFound:
    ;Function found! Execute!
    ;rsi points to start of expression to evaluate for function
    ;rdi points to table entry
    lea rbx, funTbl         ;Get table address
    movzx rdx, byte [rdi]   ;Get pascal string length
    movzx edx, word [rdi + rdx]    ;Add pascal strlen to table entry and get ptr
    add rbx, rdx    ;Add word offset to table base
    jmp rbx ;Goto function pointer in rbx
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
    call spaceSkip  ;Skip any spaces
    inc rsi         ;Go past the equality sign
    call spaceSkip  ;Skip any spaces
    cmp byte [rsi], 22h ;Open speech mark
    je .stringAssignment
    call handleAlgebraicExpression  ;Get the result of the expression into rax
    mov rsi, rdi    ;Return the start of the string into rsi
    call setNumericVariable
    ret

.exitError:
    lea rbp, syntax ;Syntax error, keyword a bit confused
    jmp criticalError

.stringAssignment:
;This simply copies the string which is either speech mark, 0 or : terminated
;First allocate a string
;rdi = start of string pointer
;rcx = char count for var name
    mov rsi, rdi    ;Return to the start of the string
    
