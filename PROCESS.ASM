mainProcessor:
;rsi must point to the start of the portion of the line to execute
    call spaceSkip  ;Skip any leading spaces
    cmp byte [rsi], 0   ;Null terminated line, empty line?
    je .gotoNextLine
    ;rsi now points to function
    lea rdi, funTbl     ;Point rdi to the function table
.functionFinderLoop:
    movzx ecx, byte [rdi]  ;Get the string length  
    cmp cl, -1  ;-1 is the end of table marker, either Var assignment or error
    je .notLetVarAssignment ;No key word found, consider variable assignment
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
    movzx ecx, word [rdi + rdx] ;Add pascal strlen to table entry and get word offset
    add rbx, rcx    ;Add word offset to table base
    dec rdx         ;Get number of chars in function name
    add rsi, rdx    ;rsi points to first char AFTER function name
.runFunction:
    ;rsi points to string to begin processing
    ;Run bit tests
    test byte [stateByte], breakBit ;Is break set before exec?
    jnz .break
    test byte [stateByte], traceBit ;Are we TRON?
    jnz .tron
.mp0:
;EXEC   LINE    PORTION
    ;Get the address of the next line and push it on stack
    ;This allows a program to modify the return address or even add 
    ; more addresses to the stack
    call rbx        ;Call the function pointer in rbx
    ;Pop it off the stack here
    ;cmp the address to -1, if equal, exit
;EXEC COMPLETE
    test byte [stateByte], breakBit ;Is break set after exec?
    jnz .break

    call findOtherExpressionsOnLine ;See if there are any other expressions
    test al, al ;If al is null, no more expressions on the line
    ;If not null, keep executing expressions on same line
    ;rsi points to first char after :
    jnz mainProcessor 
.exit:
    ret
.notLetVarAssignment:
    lea rbx, variableAssignment
    jmp short .runFunction  ;Now call the function as if it was found from the table
.gotoNextLine:
.tron:
;Print the line number about to be executed
    test byte [stateByte], indirectBit  ;Tron should only work in indirect mode
    jz .mp0
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


%macro addQwordToStack 1    ;One argument, a register
;This macro adds an extra qword to the stack for flow control
; such as FOR, WHILE, GOSUB. It adds the default return address
; for the NEXT, WEND, RETURN keywords
;rsp points to return address for function call
;rax trashed
    push rax  ;Make space for one more qword, push a dummy word
    cmp rsp, stack
    ja ..@stackOK
    lea rbp, stkOvflw
    jmp criticalError
    ;rsp points to the qword pushed by rax
..@stackOK:
    mov rax, qword [rsp + 8]    ;Get call rbx return address
    mov qword [rsp], rax        ;Replace on stack
    mov qword [rsp + 8], %1     ;Now place the new function block ptr as next function
%endmacro
;GOTO simply replaces the qword for the function block
;NEXT, WEND, RETURN look at the address BEFORE the usual address and copy that into
; the next address to be used position on the stack. 
; NEXT and WEND dont do any stack clean up, RETURN does
; The return line for NEXT and WEND deal with clean up