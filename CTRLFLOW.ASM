;Handles all the specific functions related to control flow such as scanning 
; lines for WEND, RETURN, NEXT

retScan:
    
wendScan:
nextScan:
;=======================================
;  ACTUAL CONTROL FLOW FUNCTIONS HERE  :
;=======================================
goto:
;GOTO, works by replacing the address after the return address on the stack
;rsi points to first char AFTER function name
    call spaceSkip  ;Skip all preceeding spaces
    call handleAlgebraicExpression  ;Turn the expression into a number in ax
    movzx edx, ax   ;Line number into dx, start at beginning of line
    or byte [stateByte], ctrlFlow   ;Set branch bit
    ret

forLoop:
    ret
next:
    ret
gosub:
    ret
return:
    ret
while:
    ret
wend:
    ret


handleIf:
;Evaluate the string. The IF,THEN/GOTO,ELSE statement must ALL be on one line
;IF exp1 THEN statement ELSE statement
;IF exp1 GOTO linenumber ELSE statement
;rsi points to first char AFTER function name
    call spaceSkip
    call handleAlgebraicExpression
;THIS WORKS ON CONTRALOGIC. If the algebraic expression evaluates to 0,
; it is currently taken to be true (as that is a condition I can test for
; easily). Once Proper logical operators are introduced, then I will have to
; switch it so that test rax, rax -> jz .else
    test rax, rax  ;If this is NOT 0, go to the else
    jnz .else   ;CONTRALOGIC, TO BE SWITCHED IN LATER VERSIONS TO JZ 
    call spaceSkip
    lodsd   ;Get the whole word, must be either "THEN " or "GOTO "
    cmp eax, "THEN"
    je .hi0   ; Go past THEN, to process statement
    cmp eax, "GOTO"
    jne .error
    cmp byte [rsi], " " ;is the next char a space?
    jne .error
    jmp goto
.candidatethen:
    cmp byte [rsi], " " ;is the next char a space?
    je .hi0
    jmp short .error
.else:
    ;Search for the ELSE, it has to be preceeded with a space and have a space after
    cmp byte [rsi], 0 ;Are we at end of line?
    je .noElse
    cmp byte [rsi], ":" ;Are we at end line segment?
    je .noElse
    inc rsi
    cmp dword [rsi], " ELS"
    jne .else
    add rsi, 4  ;Skip those four chars, we have a candidate
    cmp word [rsi], "E "
    jne .else   ;If not equal failed to match pattern
    add rsi, 2  ;Else its the ELSE we are looking for, move rsi to first space past it
.hi0:
;Now we do the branchy stuff, branch to the same line just further down
    or byte [stateByte], ctrlFlow   ;Set branch bit
    mov dx, word [currentLine]
    call searchForProgramLine
    cmp rbx, -1 ;Does the line not exist somehow?
    je .error
    mov rax, rsi    ;Save pointer in rax
    lea rcx, qword [rbx + progLineBlock.sLine] ;Get the difference in chars
    sub rax, rcx
    and al, -1  ;Save only bottom byte as the difference should be less than 255
    shl eax, 10h ;Shift to byte 3
    or edx, eax ;Save the offset into byte 3
.noElse:
;If no else, simply return
    ret
.error:
    lea rbx, syntax
    jmp criticalError
