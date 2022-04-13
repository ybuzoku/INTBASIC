
;Handles all the specific functions related to control flow such as scanning 
; lines for WEND, RETURN, NEXT
retScan:
;Gets the current line address and starts searching program from current prog line
; for a return
    push rsi
    mov dx, word [currentLine]  ;pre-load dx with the current line number
    call searchForProgramLine   ;Get program block pointer into rbx
    cmp rbx, -1 ;If for some reason line doesnt exist?
    je .error   ;Unknown Error
;Now pack for the first portion/line after the GOSUB
;rsi points just after the GOSUB itself
    push rsi    ;Save the first point after the WHILE itself
    call findOtherExpressionsOnLine     ;Get the first : or ASCII NUL
    movzx eax, word [rbx + progLineBlock.wLineNum]  ;Get the line number
    lea rcx, qword [rbx + progLineBlock.sLine]  ;Load ptr to start of string in rsi
    sub rsi, rcx    ;Compute difference from start of string
    mov ecx, esi    ;Should just be low byte of si so cl
    and ecx, 0FFh   ;Save only bottom byte just in case of garbage
    shl ecx, 2*8    ;Move to the third byte in the dword
    or eax, ecx     ;Add byte three to eax
    mov edx, eax    ;Save in edx
    shl rdx, 5*8    ;Shift three bytes to top of qword
    pop rsi
.initialSearch:
    ;First look for a ASCII NUL or RETURN
    cmp byte [rsi], 0
    je .gotoNextLine
    cmp dword [rsi], "RETU"
    jne .notCandidate
    cmp word [rsi + 4], "RN"
    je .wordFound
.notCandidate:
    inc rsi ;Now search up until the end of the line for a RETURN
    jmp short .initialSearch
.gotoNextLine:
    mov rbx, qword [rbx + progLineBlock.qPtr] ;Get pointer to next program line
    cmp rbx, -1 ;Now, when walking if it gives a value of -1, no NEXT found
    je .noRet
    lea rsi, qword [rbx + progLineBlock.sLine] ;Load pointer to string rsi
    jmp short .initialSearch
.wordFound:
    ;Here, RETURN found! Huzzah! Now pack edx correctly
    ;Add 055AA55h in bytes 4:2
    mov rax, 055AA550000h
    or rdx, rax
    ;Compute checksum now
    xor eax, eax
    mov al, GOSUBsig 
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
    mov dh, al  ;Save in checksum byte
.exit:
    pop rsi
    ret
.noRet:
    lea rbp, noReturn
    mov rdx, -1
    jmp .exit
.error:
    lea rbp, uknowner
    mov rdx, -1
    jmp .exit

wendScan:
; Gets the current line address and starts searching program from the current line
; for a WEND
; Puts the packed specialQword into rdx if a WEND is found
; Returns rdx = -1 if an error occured with rbp pointing to the error string
    push rsi
    mov dx, word [currentLine]  ;pre-load dx with the current line number
    call searchForProgramLine   ;Get program block pointer into rbx
    cmp rbx, -1 ;If for some reason line doesnt exist?
    je .error   ;Unknown Error
;Now pack for the first portion/line after the for loop
;rsi points just after the FOR itself
    push rsi    ;Save the first point after the WHILE itself
    call findOtherExpressionsOnLine     ;Get the first : or ASCII NUL
    movzx eax, word [rbx + progLineBlock.wLineNum]  ;Get the line number
    lea rcx, qword [rbx + progLineBlock.sLine]  ;Load ptr to start of string in rsi
    sub rsi, rcx    ;Compute difference from start of string
    mov ecx, esi    ;Should just be low byte of si so cl
    and ecx, 0FFh   ;Save only bottom byte just in case of garbage
    shl ecx, 2*8    ;Move to the third byte in the dword
    or eax, ecx     ;Add byte three to eax
    mov edx, eax    ;Save in edx
    shl rdx, 5*8    ;Shift three bytes to top of qword
    pop rsi
.initialSearch:
    ;First look for a : or a ASCII NUL to leave the WHILE part of the line
    cmp byte [rsi], 0
    je .gotoNextLine
    cmp dword [rsi], "WEND"
    je .wordFound
    inc rsi ;Now search up until the end of the line for a WEND
    ;"WEND" found here!
    jmp short .initialSearch
.gotoNextLine:
    mov rbx, qword [rbx + progLineBlock.qPtr] ;Get pointer to next program line
    cmp rbx, -1 ;Now, when walking if it gives a value of -1, no NEXT found
    je .noWend
    lea rsi, qword [rbx + progLineBlock.sLine] ;Load pointer to string rsi
    jmp short .initialSearch
.wordFound:
    ;Here, word found! Huzzah! Now pack edx correctly
    ;rsi points to the N in "WEND "
    call findOtherExpressionsOnLine 
    ;make rsi point to next expression on the line or the end of the line
    movzx eax, word [rbx + progLineBlock.wLineNum]  ;Get the line number
    lea rcx, qword [rbx + progLineBlock.sLine]  ;Load ptr to start of string in rsi
    sub rsi, rcx    ;Compute difference from start of string
    mov ecx, esi    ;Should just be low byte of si so cl
    and ecx, 0FFh   ;Save only bottom byte just in case of garbage
    shl ecx, 2*8    ;Move to the third byte in the dword
    or eax, ecx     ;Add byte three to eax
    shl rax, 8*2    ;Shift three bytes to byte 4 of qword
    or rdx, rax     ;Add bytes [4:2] to rdx
    ;Compute checksum now
    xor eax, eax
    mov al, WHILEsig 
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
    mov dh, al  ;Save in checksum byte
.exit:
    pop rsi
    ret
.noWend:
    lea rbp, noWend
    mov rdx, -1
    jmp .exit
.error:
    lea rbp, uknowner
    mov rdx, -1
    jmp .exit
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
    lea rcx, qword [rbx + progLineBlock.sLine]  ;Load ptr to start of string in rsi
    sub rsi, rcx    ;Compute difference from start of string
    mov ecx, esi    ;Should just be low byte of si so cl
    and ecx, 0FFh   ;Save only bottom byte just in case of garbage
    shl ecx, 2*8    ;Move to the third byte in the dword
    or eax, ecx     ;Add byte three to eax
    mov edx, eax    ;Save in edx
    shl rdx, 5*8    ;Shift three bytes to top of qword
    pop rsi
.initialSearch:
    ;First look for a : or a ASCII NUL to leave the FOR part of the line
    cmp byte [rsi], 0
    je .gotoNextLine
    cmp dword [rsi], "NEXT"
    je .wordFound
    inc rsi ;Now search up until the end of the line for a NEXT
    ;"NEXT" found here!
    jmp short .initialSearch
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
    lea rcx, qword [rbx + progLineBlock.sLine]  ;Load ptr to start of string in rsi
    sub rsi, rcx    ;Compute difference from start of string
    mov ecx, esi    ;Should just be low byte of si so cl
    and ecx, 0FFh   ;Save only bottom byte just in case of garbage
    shl ecx, 2*8    ;Move to the third byte in the dword
    or eax, ecx     ;Add byte three to eax
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

gosub:
    call retScan
    cmp rdx, -1
    je .error
    mov ecx, gosubStruct_size/8
    makeSpaceOnStack rcx  ;Make four qwords of space on the stack
    mov rbp, rsp
    add rbp, 8  ;Make rbp point to the base of the new struc
    mov qword [rbp + forStruct.specQword], rdx  ;Move rdx into its place on the stack
    ;rsi points just past the GOSUB
    jmp short goto ;Now behave like GOTO
.error:
    jmp criticalError

return:
;First verify the GOSUB struc is on the stack
    mov rbp, rsp    ;Dont need to save rbp so trash it
    add rbp, 8  ;Make it point to the base of the struc past the return address
    ;Read the qword on stack, verify it is a GOSUBstruc and passes checksum test
    mov rdx, qword [rbp + gosubStruct.specQword]
    cmp dl, GOSUBsig
    jne .noReturn
    ;Now compute checksum to verify its not an accident
    xor al, al
    mov ecx, 8
.checksumTest:
    add al, dl
    ror rdx, 8
    dec ecx
    jnz .checksumTest
    test al, al     ;This should be 0
    jnz .noReturn
 ;Now we are truly in a RETURN
    shr rdx, 5*8    ;Bring return information down to the lower three bytes
    ;Clean the struc from the stack
    mov ecx, gosubStruct_size/8
    cleanSpaceOnStack rcx
    or byte [stateByte], ctrlFlow   ;Set branch bit
    ret
.noReturn:
    lea rbp, noReturn
    jmp criticalError
forLoop:
;This saves the following struc on the stack
;------------Hi stack addr-------------
;stepValue (qword), default 1
;limitValue (qword), to which value do we loop
;ptr to counter variable (qword)
;Special qword:
; Byte 7 = Offset into the line for next instruction
; Bytes[6:5] = Line number of portion after FOR (either FOR line or line after FOR)
; Byte 4 = Offset into the line for next instruction
; Bytes[3:2] = Line number of portion after NEXT (either NEXT line or line after NEXT)
; Byte 1 = Parity check sum for the qword, makes the sum of the bytes in qword 0
; Byte 0 = FOR signature
;------------Low stack addr------------
;rsp -> Return address
    ;First check we have a NEXT following this FOR
    call nextScan
    cmp rdx, -1
    je .critError
    ;Here we make space on the stack.
    mov ecx, forStruct_size/8
    makeSpaceOnStack rcx  ;Make four qwords of space on the stack
    mov rbp, rsp
    add rbp, 8  ;Make rbp point to the base of the new struc
    mov qword [rbp + forStruct.specQword], rdx  ;Move rdx into its place on the stack
    push rsi   ;rsi points to first byte after FOR. The first word should now be a var
    mov eax, " TO " ;First find the TO and STEP values
.flScanTo:
    cmp byte [rsi], 0   ;ASCII null w/o a TO? Syntax Error
    je .syntaxError
    cmp byte [rsi], ":" ;Save for a next statement delimiter
    je .syntaxError
    cmp dword [rsi], eax
    je .flToFound
    inc rsi ;Go forwards by a byte
    jmp short .flScanTo
.flToFound:
    ;rsi points to the preceeding space so add 3 to go to trailing space
    add rsi, 3
    call spaceSkip  ;Go to expression to evaluate
    call handleAlgebraicExpression  ;Get in rax the limit value
    mov qword [rbp + forStruct.limitValue], rax
    ;rsi now points to the next word, this should be step, otherwise ignore the word
    lodsd   ;Get the word in eax
    cmp eax, "STEP"
    jne .defaultStep
    ;Check it is a "STEP "
    lodsb
    cmp al, " "
    jne .defaultStep
    ;rsi points to a "STEP "
    call spaceSkip  ;Go to expression to evaluate
    call handleAlgebraicExpression  ;Get in rax the step value
    mov qword [rbp + forStruct.stepValue], rax
.flVariable:
    pop rsi ;Get back OG rsi position immediately after FOR
    call spaceSkip ;Skip intermediate spaces
    push rsi
    call variableAssignment ;Make the variable assignment, trashes rsi
    pop rsi ;rsi points to the start of the variable again
    call getVarNameLength
    call findVariable   ;Get the variable pointer in rbx
    mov qword [rbp + forStruct.cntrPtr], rbx    ;Save variable pointer
    ;Now check whether we should run the loop at all?
    mov rbx, qword [rbp + forStruct.cntrPtr]
    mov rcx, qword [rbx + varBlock.qValue]  ;Get the variable value
    mov rbx, qword [rbp + forStruct.limitValue]
    ;if rcx >= rbx, branch to after NEXT
    cmp rcx, rbx
    jge .dontRunFor
    mov rdx, qword [rbp + forStruct.specQword]
    shr rdx, 5*8    ;Upper bytes will be cleared, needed for the "branch"
.exit:
    ;Recall edx must have the correct three bytes in it from the special qword
    or byte [stateByte], ctrlFlow   ;Set branch bit
    ret
.defaultStep:
    mov qword [rbp + forStruct.stepValue], 1
    jmp short .flVariable
.dontRunFor:
    ;Move the bytes from the NEXT to edx 
    mov rdx, qword [rbp + forStruct.specQword]
    shr rdx, 2*8    ;Upper bytes will be cleared
    or edx, edx     ;This should zero the upper dword
    ;Need to also reclaim the stack space
    mov ecx, forStruct_size/8
    cleanSpaceOnStack rcx
    jmp short .exit
;Errors
.unknownError:
    lea rbp, uknowner
    jmp short .critError
.syntaxError:
    lea rbp, syntax
.critError:
    ;called with rbp already pointing to error string
    jmp criticalError

next:
    ;Verify that the structure on the stack is a FOR structure
    mov rbp, rsp    ;Dont need to save rbp so trash it
    add rbp, 8  ;Make it point to the base of the struc past the return address
    ;Read the qword on stack, verify it is a FORstruct and passes checksum test
    mov rdx, qword [rbp + forStruct.specQword]
    cmp dl, FORsig
    jne .noForNext
    ;Now compute checksum to verify its not an accident
    xor al, al
    mov ecx, 8
.checksumTest:
    add al, dl
    shr rdx, 8
    dec ecx
    jnz .checksumTest
    test al, al     ;This should be 0
    jnz .noForNext
    ;Now we are truly in a FOR loop
    mov rbx, qword [rbp + forStruct.cntrPtr]    ;Get variable pointer
    mov rax, qword [rbx + varBlock.qValue]      ;Get variable value
    cmp rax, qword [rbp + forStruct.limitValue] ;Compare current var value to limit
    jge .noMoreLooping
    add rax, qword [rbp + forStruct.stepValue]  ;Add the step
    mov qword [rbx + varBlock.qValue], rax      ;Update the variable value
    ;Now go back to line after FOR
    mov rdx, qword [rbp + forStruct.specQword]
    shr rdx, 5*8    ;Move upper three bytes to lower three bytes of edx
.exit:
    ;Recall edx must have the correct three bytes in it from the special qword
    or byte [stateByte], ctrlFlow   ;Set branch bit
    ret
.noMoreLooping:
    ;No need to update the variable, it is already above
    mov rdx, qword [rbp + forStruct.specQword]
    shr rdx, 2*8    ;Move bytes 4:2 to lower three bytes of edx
    or edx, edx     ;Remove upper bits
    ;Need to also reclaim the stack space
    mov ecx, forStruct_size/8
    cleanSpaceOnStack rcx
    jmp short .exit
.noForNext:
    lea rbp, noFor
    jmp criticalError

while:
    ;First check we have a WEND following this WHILE
    call wendScan
    cmp rdx, -1
    je .critError
    ;Here we make space on the stack.
    mov ecx, whileStruct_size/8
    makeSpaceOnStack rcx  ;Make a qword of space on the stack
    mov rbp, rsp
    add rbp, 8  ;Make rbp point to the base of the new struc
    mov qword [rbp + whileStruct.specQword], rdx  ;Move rdx into its place on the stack
    ;rsi should point after the WHILE
    call handleAlgebraicExpression  ;Get result of expression in rax
    mov rdx, qword [rbp + whileStruct.specQword]    ;Get special qword back into rdx
    test rax, rax   ;Zero is FALSE
    jz .conditionFalse
    shr rdx, 5*8    ;Bring the upper three bytes down to eax
.exit:
    or byte [stateByte], ctrlFlow   ;Set branch bit
    ret
.conditionFalse:
    ;If condition is false, jump to the instruction after WEND
    ;Here we reclaim the space from the stack.
    mov ecx, whileStruct_size/8
    cleanSpaceOnStack rcx  ;Clean a qword of space on the stack
    shr rdx, 2*8    ;Bring bytes 4:2 down to bytes 2:0
    or edx, edx     ;Zero the rest of it
    jmp short .exit
.critError:
    ;called with rbp already pointing to error string
    jmp criticalError
wend:
    ;Find the While on the WHILE line and evaluate the expression
    ;if true, branch to the WHILE three bytes in specialQword
    ;if false, branch to WEND three bytes in specialQword and clean stack
    ;First verify we have a While structure on the stack
    mov rbp, rsp    ;Dont need to save rbp so trash it
    add rbp, 8  ;Make it point to the base of the struc past the return address
    mov rdx, qword [rbp + whileStruct.specQword]
    cmp dl, WHILEsig
    jne .noWhile
    ;Now compute checksum to verify its not an accident
    xor al, al
    mov ecx, 8
.checksumTest:
    add al, dl
    ror rdx, 8
    dec ecx
    jnz .checksumTest
    test al, al     ;This should be 0
    jnz .noWhile
    ;Now we are truly in a WHILE loop
    ;Search the While line for the WHILE keyword and evaluate the expression after it
    ;rdx is as normal
    shr rdx, 5*8    ;Get upper three bytes down low
    and edx, 0FFFFh ;Save only dx
    call searchForProgramLine
    cmp rbx, -1
    je .error
    lea rsi, qword [rbx + progLineBlock.sLine] ;Point to start of string
.whileScan:
    cmp byte [rsi], 0   ;Are we at the end of the line
    je .noWhile ;If so, we have gotten to the end of the line without a while
    lea rdi, whileStr   ;Point to the while string in the table, 6 chars long
    mov ecx, 6
.scanning:
    cmpsb
    jne .whileScan
    dec ecx
    jnz .scanning
    ;Here is equal, rsi points past the space in "WHILE "
    dec rsi
    call spaceSkip  ;Skip all spaces
    call handleAlgebraicExpression  ;Get algebraic expression in rax
    mov rdx, qword [rbp + whileStruct.specQword]    ;Get special qword back into rdx
    test rax, rax
    jz .conditionFalse
    shr rdx, 5*8    ;Bring the upper three bytes down to eax
.exit:
    or byte [stateByte], ctrlFlow   ;Set branch bit
    ret
.conditionFalse:
    ;If condition is false, go to the instruction after WEND
    ;Here we reclaim the space from the stack.
    mov ecx, whileStruct_size/8
    cleanSpaceOnStack rcx  ;Clean a qword of space on the stack
    shr rdx, 2*8    ;Bring bytes 4:2 down to bytes 2:0
    or edx, edx     ;Zero the rest of it
    jmp short .exit
.error:
    lea rbp, uknowner
    jmp criticalError
.noWhile:
    lea rbp, noWhile
    jmp criticalError

handleIf:
;Evaluate the string. The IF,THEN/GOTO,ELSE statement must ALL be on one line
;IF exp1 THEN statement ELSE statement
;IF exp1 GOTO linenumber ELSE statement
;rsi points to first char AFTER function name
    call spaceSkip
    call handleAlgebraicExpression
    test rax, rax  ;If this is 0, go to the else
    jz .else
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
