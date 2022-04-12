
;Handles all the specific functions related to control flow such as scanning 
; lines for WEND, RETURN, NEXT
retScan:
;Gets the current line address and starts searching program from current prog line
; for a return

wendScan:
nextScan:
; Gets the current line address and starts searching program from the current line
; for a NEXT
; Puts the packed specialQword into rdx if a NEXT is found
; Returns rdx = -1 if an error occured with rbp pointing to the error string
    push rsi
    mov dx, word [currentLine]  ;pre-load dx with the current line number
    call searchForProgramLine   ;Get program block pointer into rbx
    cmp rbx, -1 ;If for some reason line doesnt exist?
    je .error   ;Unknown Error
;Now pack for the first portion/line after the for loop
;rsi points just after the FOR itself
    push rsi    ;Save the first point after the FOR itself
    call findOtherExpressionsOnLine     ;Get the first : or ASCII NUL
    movzx eax, word [rbx + progLineBlock.wLineNum]  ;Get the line number
    shl eax, 8  ;Make space for Offset byte
    lea rcx, qword [rbx + progLineBlock.sLine]  ;Load ptr to start of string in rsi
    sub rsi, rcx    ;Compute difference from start of string
    mov ecx, esi    ;Should just be low byte of si so cl
    mov al, cl      ;Save the byte into al
    mov edx, eax    ;Save in edx
    shl rdx, 5*8    ;Shift three bytes to top of qword
    pop rsi
.initialSearch:
    ;First look for a : or a ASCII NUL to leave the FOR part of the line
    cmp byte [rsi], 0
    je .gotoNextLine
    inc rsi ;Now search up until the end of the line for a NEXT
    cmp dword [rsi], "NEXT"
    jne .initialSearch
    cmp byte [rsi + 4], " " ;NEXT must have a space after it
    jne .initialSearch
    ;"NEXT " found here!
    jmp short .wordFound
.gotoNextLine:
    mov rbx, qword [rbx + progLineBlock.qPtr] ;Get pointer to next program line
    cmp rbx, -1 ;Now, when walking if it gives a value of -1, no NEXT found
    je .noNext
    lea rsi, qword [rbx + progLineBlock.sLine] ;Load pointer to string rsi
    jmp short .initialSearch
.wordFound:
    ;Here, word found! Huzzah! Now pack edx correctly
    ;rsi points to the N in "NEXT "
    call findOtherExpressionsOnLine 
    ;make rsi point to next expression on the line or the end of the line
    movzx eax, word [rbx + progLineBlock.wLineNum]  ;Get the line number
    shl eax, 8  ;Make space for Offset byte
    lea rcx, qword [rbx + progLineBlock.sLine]  ;Load ptr to start of string in rsi
    sub rsi, rcx    ;Compute difference from start of string
    mov ecx, esi    ;Should just be low byte of si so cl
    mov al, cl      ;Save the byte into al
    shl rax, 8*2    ;Shift three bytes to byte 4 of qword
    or rdx, rax     ;Add bytes [4:2] to rdx
    ;Compute checksum now
    xor eax, eax
    mov al, FORsig 
    mov dx, ax  ;Zero checksum byte
    xor eax, eax
    mov ecx, 8  ;8 times
.csumLoop:
    ;Spin rdx 8 times adding each byte to al
    add al, dl
    rol rdx, 8  ;Rotate left by 8 bits
    dec ecx
    jnz .csumLoop
    neg al ;Get twos compliment of sum (FFh - al)
    inc al
    mov dh, al  ;Save in checksum byte
.exit:
    pop rsi
    ret
.noNext:
    lea rbp, noNext
    mov rdx, -1
    jmp .exit
.error:
    lea rbp, uknowner
    mov rdx, -1
    jmp .exit
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
    call nextScan
    cmp rdx, -1
    je .critError
    ;Here we make space on the stack.
    mov ecx, forStruct_size
    makeSpaceOnStack rcx  ;Make four qwords of space on the stack
    mov rbp, rsp
    add rbp, 8  ;Make rbp point to the base of the new struc


    or byte [stateByte], ctrlFlow   ;Set branch bit
    ret
.critError:
    jmp criticalError
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
