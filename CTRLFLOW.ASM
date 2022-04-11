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
;rdi points just past the end of the command line
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
    ;Now check if it is a THEN or a GOTO
    ;If it is a THEN, go past the then and let mainProcessing handle it
    ;If it is a GOTO, dont go past the GOTO and let mainProcessing handle it
    ;In both cases JUMP to mainProcessing to avoid stack growth
    ;If no GOTO or THEN, then syntax error
    lodsd   ;Get the whole word
    cmp eax, "THEN"
    je .hi0   ; Go past THEN, to process statement
    cmp eax, "GOTO"
    jne .error
    sub rsi, 4  ;Go back four spaces to process GOTO
.hi0:
    ret
.else:
    mov eax, "ELSE" ;Lucky for us, ELSE fits in eax
    ret
.noElse0:
;If there is no ELSE, simply ret
.noElse:
    ret
.error:
    lea rbx, syntax
    jmp criticalError
