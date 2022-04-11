
;Handles all the specific functions related to control flow such as scanning 
; lines for WEND, RETURN, NEXT
retScan:
;Gets the current line address and starts searching program from current prog line
; for a return

wendScan:
nextScan:
; Gets the current line address and starts searching program from the current line
; for a NEXT
; Puts the packed three bytes into the low three bytes of edx if a NEXT is found
    push rsi
    mov dx, word [currentLine]  ;pre-load dx with the current line number
.initialSearch:
    ;First look for a : or a ASCII NUL to leave the FOR part of the line
    cmp byte [rsi], 0
    je .gotoNextLine
    inc rsi ;Now search up until the end of the line for a NEXT
    cmp dword [rsi], "NEXT"
    jne .initialSearch
    cmp byte [rsi + 4], " " ;NEXT must have a space after it
    jne .initialSearch

.gotoNextLine:
    call searchForProgramLine
.exit:
    pop rsi
    ret
.nextFound:
    
;=======================================
;  ACTUAL CONTROL FLOW FUNCTIONS HERE  :
;=======================================
;All below functions return the line number in dx and the offset into the line
; to start reading at in byte three of edx
goto:
;GOTO, works by replacing the address after the return address on the stack
;rsi points to first char AFTER function name
    call spaceSkip  ;Skip all preceeding spaces
    call handleAlgebraicExpression  ;Turn the expression into a number in ax
    movzx edx, ax   ;Line number into dx, start at beginning of line
    or byte [stateByte], ctrlFlow   ;Set branch bit
    ret

forLoop:
;This saves the following struc on the stack
;------------Hi stack addr-------------
;stepValue (qword), default 1
;limitValue (qword), to which value do we loop
;ptr to counter variable (qword)
;Special qword:
; Bytes[7:6] = Line number of portion after FOR (either FOR line or line after FOR)
; Byte 5 = Offset into the line for next instruction
; Bytes[4:3] = Line number of portion after NEXT (either NEXT line or line after NEXT)
; Byte 2 = Offset into the line for next instruction
; Byte 1 = Parity check sum for the qword, makes the sum of the bytes in qword 0
; Byte 0 = FOR signature
;------------Low stack addr------------
;rsp -> Return address
    ;First check we have a NEXT following this FOR

    ;Here we make space on the stack.
    mov ecx, forStruct_size
    makeSpaceOnStack rcx  ;Make four qwords of space on the stack
    mov rbp, rsp
    add rbp, 8  ;Make rbp point to the base of the new struc


    or byte [stateByte], ctrlFlow   ;Set branch bit
    ret

next:
    ;Verify that the structure on the stack is as expected
    mov rbp, rsp    ;Dont need to save rbp so trash it
    add rbp, 8  ;Make it point to the base of the struc past the return address
    or byte [stateByte], ctrlFlow   ;Set branch bit
    ret

gosub:
    or byte [stateByte], ctrlFlow   ;Set branch bit
    ret

return:
    or byte [stateByte], ctrlFlow   ;Set branch bit
    ret

while:
    or byte [stateByte], ctrlFlow   ;Set branch bit
    ret

wend:
    or byte [stateByte], ctrlFlow   ;Set branch bit
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
    or byte [stateByte], ctrlFlow   ;Set branch bit
.noElse:
;If no else, simply return
    ret
.error:
    lea rbx, syntax
    jmp criticalError
