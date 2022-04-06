start:
    mov eax, 0C501h
    int 35h         ;Connect the debugger
    call ttyClear   ;Clear the teletype
    ;Memory stuff
    lea rbp, mainmsg
    call ttyOutString
    call memoryDetection
    lea rbp, bytemsg
    call ttyOutString
    call newProgram         ;Use this to reset program pointers
mainLoop:
    cld                 ;Set default string op direction
    lea rsp, stacktop    ;Reinitialize stack pointer
    lea rax, mainLoop
    push rax    ;Save address on stack
    lea rbp, prompt
    call ttyOutString
.ml0:
;This section will execute an input line if it is an interactive expression
; or store it in the program if it has a line number.
;It will keep accepting lines until a line is entered without a line number
    call getLineInput
    call decimalToHex   ;Check to see if we have a valid line number
    ;xchg bx, bx
    test ax, ax
    jnz .saveLine
;Here we execute the line
.ml1:
    call executeExpression
    ;Now see if the line has any more expressions by checking for :
    call findOtherExpressionsOnLine
    test al, al ;If al is null, no more expressions on the line
    jnz .ml1    ;Execute portion
    ret
.saveLine:
    ;ax has the line number
    mov dx, ax
    call searchForProgramLine
    cmp rbx, -1
    jne .commonProc ;If not equal, line must exist, continue
    call spaceSkip  ;Skip all the prceeding spaces
    cmp byte [rsi], 0  ;Is the first non space char the end of the string?
    je .lineDoesntExist
    ;So we have a new line that isn't empty, allocate a new block for this line
    call allocateBlock  ;Return a default block in rbx
    mov byte [rbx + progLineBlock.bBlockType], progLineBlockType
    mov word [rbx + progLineBlock.wLineNum], ax
    mov word [rbx + progLineBlock.wBlockSize], progLineBlock_size
.commonProc:
    ;If the line already exists, simply override the stored string
    ;rbx has a pointer to the block
    call strlen ;Get the string length
    lea rdi, qword [rbx + progLineBlock.sLine]  ;Get address here
    call strcpy ;Copy the program string to the program block
    push rsi
    mov rsi, rbx    ;Move the block into rsi
    call insertProgramLine
    pop rsi
    jmp short .ml0
.lineDoesntExist:
    lea rbp, lineNoXist
;For any error, syntax or otherwise, come here
criticalError:
;Called with rbp pointing at error message
    call ttyOutString
    jmp mainLoop    ;Trash input line, restart line input
