keywordParser:
;rsi must point to the start of the portion of the line to execute
    call spaceSkip  ;Skip any leading spaces
    cmp byte [rsi], 0   ;Null terminated line, empty line?
    je .exitEmpty
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
.exit:
    ret 
.exitEmpty:
    mov rbx, -1
    ret
    ;rbx has the function pointer, 
    ;rsi points to the first char after the keyword (e.g. PRINT, INPUT etc)
.notLetVarAssignment:
    lea rbx, variableAssignment
    jmp short .exit  ;Now call the function as if it was found from the table

runLine:
;New lines begin here, rsi point to the start of the program line
    test byte [stateByte], traceBit ;Are we TRON?
    jnz .tron
.stringPortionProcess:
    ;rsi points to string portion to begin processing
    call keywordParser
    ;rbx has the function pointer, if rbx is -1, line was empty
    ;rsi points to the first char after the keyword (e.g. PRINT, INPUT etc)
    cmp rbx, -1 ;If the line is empty, rbx has a -1 so skip the line
    je .gotoNextLine
    test byte [stateByte], breakBit ;Is break set before exec?
    jnz .break
;EXEC   LINE    PORTION
    call rbx        ;Call the function pointer in rbx
    ;rsi should be pointing to the next portion of the line or the end of the line
;EXEC COMPLETE
    test byte [stateByte], breakBit ;Is break set after exec?
    jnz .break
    test byte [stateByte], indirectBit
    jz .exit    ;IF in direct mode, just return to command line
    test byte [stateByte], ctrlFlow ;Ctrl Flow =>ignore other expressions temporarily
    jnz .ctrlFlowHandler

    call findOtherExpressionsOnLine ;See if there are any other expressions
    test al, al ;If al is null, no more expressions on the line
    ;If not null, keep executing expressions on same line
    ;rsi points to first char after :
    jnz .stringPortionProcess ;If a : found, keep processing
.gotoNextLine:
    mov dx, word [currentLine]  ;Get in rbx the ptr to current line
    call searchForProgramLine
    cmp rbx, -1 ;Does the line not exist somehow?
    je .exit
    mov rbx, qword [rbx + progLineBlock.qPtr] ;Walk chain
    cmp rbx, -1 ;Are we at the end of the chain?
    je .exit
    mov dx, word [rbx + progLineBlock.wLineNum] ;Save the new line number
    lea rsi, qword [rbx + progLineBlock.sLine] ;Point rsi to the start of the next line
.gotoNextLineCommon:
    mov word [currentLine], dx
    jmp runLine
.exit:
    ret
.ctrlFlowHandler:
    ;The stack pointer should be pointing now at the block
    ; control flow data block. 
    ;The functions which return with this bit set, also have placed
    ; the next line number in dx, offset into line in byte three of edx
    and byte [stateByte], ~ctrlFlow ;First clear the ctrlflow bit
    call searchForProgramLine   ;Get pointer to line
    cmp rbx, -1 ;Does the line not exist?
    je .gotoNextLineCommon
    lea rsi, qword [rbx + progLineBlock.sLine] ;Point rsi to the start of the next line
    mov eax, edx    ;Isolate the offset into the line
    shr eax, 10h    ;Get byte three into byte 1
    and eax, 0FFh   ;Save only the bottom byte
    add rsi, rax    ;Add the offset into the string to rsi
    jmp short .gotoNextLineCommon
.badLineNumber:
    lea rbp, lineNoXist
    jmp criticalError

.tron:
;Print the line number about to be executed
    test byte [stateByte], indirectBit  ;Tron should only work in indirect mode
    jz .stringPortionProcess
    mov al, "["
    call ttyOutChar
    movzx eax, word [currentLine]
    call printdecimalword
    mov al, "]"
    call ttyOutChar
    jmp .stringPortionProcess
.break:
    lea rbp, breakmsg
    call ttyOutString
    movzx eax, word [currentLine]
    call printdecimalword
    lea rbp, crlf
    call ttyOutString
    ;Preserve only bit 2 of the state byte
    and byte [stateByte], traceBit
    jmp mainLoop    ;Exit processing