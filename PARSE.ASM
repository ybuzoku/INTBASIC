;Main Parsing Routines go here

spaceSkip:
;Allows us to skip spaces that might have been placed for
; ease of reading by the user.
;Input: rsi = Pointer to string
;Output: rsi = First non space character encountered
    cmp byte [rsi], " "
    jne .exit
    inc rsi
    jmp short spaceSkip
.exit:
    ret

getVarNameLength:
;Input: rsi = Start of var name
;Output: ecx = Length of varname
    push rsi
    push rdi
    push rbx
    xor ecx, ecx    ;Clear counter of chars
    lea rbx, varChrs    ;Get the list of valid variable name chars
.search:
    mov rdi, rbx    ;Save pointer in rbx
    lodsb       ;Get the first char into al
    scasb       ;Look for char in the valid chars list
    jne .exit   ;Char not found, drop it
    inc ecx     ;Add one to number of chars found
    cmp ecx, 40 ;At position for char 40?
    jb .search  ;Whilst below, keep going
.exit:
    pop rbx
    pop rdi
    pop rsi
    ret

getVarType:
;Input: rsi = Start of var name
;       rcx = Length of varname
;Output: ebx = 0 => Integer
;        ebx = 1 => String
    push rax
    push rcx
    push rsi
    dec rcx         ;Get second to last char in name
    add rsi, rcx    ;Move rsi to that char
    lodsb   ;Get the char into al
    mov ebx, intEquate
    mov ecx, strEquate
    cmp al, "$"     ;String?
    cmove ebx, ecx  ;Move the string type into ebx
    pop rsi
    pop rcx
    pop rax
    ret

handleAlgebraicExpression:
;Input: rsi = Points to a mathematical expression
;Output: rax = Result of said expression
;Declares a syntax error if weird chars found
;Declares a type error if a string variable found
    call .handleSecondLevel
.parseAdditiveOperators:    
    cmp byte [rsi], '-'
    je .processMinus
    cmp byte [rsi], '+'
    jne .exit              ;No operators, expression evaluated, exit
    push rax
    call .handleSecondLevelSkip   ;Parse second level
.processAdd:    
    pop rcx
    add rax, rcx           ;Add the two numbers
    jmp short .parseAdditiveOperators  ;Search again for + or -
.processMinus:
    push rax
    call .handleSecondLevelSkip   ;Parse second level
    neg rax              ;Change a - b to a + -b
    jmp short .processAdd

;Level 2, Division and multiplication

.handleSecondLevelSkip:
    inc rsi              ;Skip the op symbol
.handleSecondLevel:
    call .handleThirdLevel      ;Call third level
.parseProductOperators:   
    cmp byte [rsi], '/'
    je .processDiv
    cmp byte [rsi], '*'
    jne .exit           ;Neither multiplication or division, return up a level

    push rax
    call .handleThirdLevelSkip   ;Call third level
    pop rcx
    imul rcx             ; Multiplication
    jmp short .parseProductOperators   ;Search again for * or /

.processDiv:
    push rax
    call .handleThirdLevelSkip   ;Call third level
    pop rcx
    xchg rax, rcx
    xor edx, edx         ;Clear rdx for rdx:rax
    idiv rcx             ;Signed division
    jmp .parseProductOperators         ;Search again for * or /

;Level 3, Brackets, numbers and vars.

.handleThirdLevelSkip:
    inc rsi             ;Skip the op symbol
.handleThirdLevel:
    call spaceSkip
    lodsb               ;Read char and adv rsi
    cmp al, '('
    jne .notBracket
    call handleAlgebraicExpression  ;Parse the inner expression
    cmp byte [rsi], ')'   
    je .closeBracket     ;If close bracket, goto skip spaces
    jmp short .error     ;Otherwise, error

.notBracket:    
    cmp al, "^"
    je .exponentFound
.varConstCheck:
    cmp al, 0x40       ;Alphanumeric first char?
    jnc .varOrRNDFound      ;Yes, variable found or rnd function
    dec rsi            ;Else back one symbol 
    call decimalToHex  ;to read number into rax
    jmp spaceSkip

.varOrRNDFound:    
    cmp al, "r"
    jne .varFound
    cmp byte [rsi], "n" ;rsi was advanced by 1, check 
    jne .varFound
    lodsw               ; Advance SI by 2
    in al, 0x40          ; Read timer counter 0
    mov ah,0       
    ret
.exponentFound:
   jmp short .varConstCheck
.varFound:    
    call getNumericVariable ;Get variable value in rax
    ret                 ;Return
.closeBracket:
    inc si
    jmp spaceSkip
.exit:
    ret
.error:
    lea rbp, syntax
    jmp criticalError


getNumericVariable:
;Gets the value stored in a variable into rax 
;Input: rsi = Pointer to first char of a variable name
;Output: rax = Variable Value
;        rsi = Pointer to first char of a variable name
    push rsi
    push rcx
    push rbx
    call getVarNameLength   ;Returns the length of the var name in cx
    call findVariable       ;Returns a pointer to the variable block in rbx
    cmp byte [rbx + memBlock.bBlockType], varBlockType
    jne .stringFoundError
    mov rax, qword [rbx + varBlock.qValue]
    pop rbx
    pop rcx
    pop rsi
    ret
.stringFoundError:
    lea rbp, typeError
    jmp criticalError

setNumericVariable:
;Sets the value stored in a variable
;Input: rsi = Pointer to first char of a variable name
;       rax = Variable value
;Output: rsi = Pointer to first char of variable name
    push rsi
    push rcx
    push rbx
    call getVarNameLength   ;Returns the length of the var name in cx
    call findVariable       ;Returns a pointer to the variable block in rbx
    cmp rbx, -1             ;Variable doesnt exit?
    je makeEditInteger      ;Make one!
    cmp byte [rbx + memBlock.bBlockType], varBlockType
    jne .stringFoundError
    mov qword [rbx + varBlock.qValue], rax  ;Save value
    pop rbx
    pop rcx
    pop rsi
    ret

.stringFoundError:
    lea rbp, typeError
    jmp criticalError