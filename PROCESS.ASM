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

mainProcessing:
    ;rsi points to string to begin processing
    test byte [stateByte], breakBit ;Is break set before exec?
    jnz .break
    test byte [stateByte], traceBit ;Are we TRON?
    jnz .tron
.mp0:
    push rbx
    call executeExpression
    pop rbx
    test byte [stateByte], breakBit ;Is break set after exec?
    jnz .break
    ;Now see if the line has any more expressions by checking for :
    call findOtherExpressionsOnLine
    test al, al ;If al is null, no more expressions on the line
    jnz mainProcessing    ;Execute portion again
    ret ;Return to caller
.tron:
;Print the line number about to be executed
    mov al, "["
    call ttyOutChar
    movzx eax, word [currentLine]
    call printdecimalword
    mov al, "]"
    call ttyOutChar
    jmp short .mp0
.break:
    lea rbp, breakmsg
    call ttyOutString
    movzx eax, word [currentLine]
    call printdecimalword
    lea rbp, crlf
    call ttyOutString
    jmp mainLoop    ;Exit processing


