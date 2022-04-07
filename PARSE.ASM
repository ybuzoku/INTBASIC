;Main Parsing Routines go here

spaceSkip:
;Allows us to skip spaces that might have been placed for
; ease of reading by the user without modifying any registers
; except for rsi.
;Input: rsi = Pointer to string
;Output: rsi = First non space character encountered
    cmp byte [rsi], " "
    jne .exit
    inc rsi
    jmp short spaceSkip
.exit:
    ret

getVarNameLength:
;Called pointing to the buffer with the var name in it
;Input: rsi = Start of var name
;Output: ecx = Length of varname
    push rax
    push rsi
    push rdi
    push rbx
    push rdx
    xor edx, edx    ;Clear counter of chars
    lea rbx, varChrs    ;Get the list of valid variable name chars
.search:
    mov rdi, rbx    ;Save pointer in rbx
    lodsb       ;Get the first char into al
    mov ecx, numVarChars
    repne scasb       ;Look for char in the valid chars list
    jne .exit   ;Char not found, drop it
    inc edx     ;Add one to number of chars found
    cmp edx, 40 ;At position for char 40?
    jb .search  ;Whilst below, keep going
.exit:
    mov ecx, edx
    pop rdx
    pop rbx
    pop rdi
    pop rsi
    pop rax
    ret

getVarType:
;Input: rsi = Start of var name
;       rcx = Length of varname
;Output: ebx = 0 => Integer
;        ebx = 1 => String
;        ebx = -1 => Var doesnt exist, caller handles
    push rax
    push rcx
    push rsi
    call findVariable
    cmp rbx, -1
    je .exit
    movzx ebx, byte [rbx + memBlock.bBlockType]
    dec ebx
.exit:
    pop rsi
    pop rcx
    pop rax
    ret

handleAlgebraicExpression:
;Input: rsi = Points to a mathematical expression
;Output: rax = Result of said expression
;Declares a syntax error if weird chars found
;Declares a type error if a string variable found
    ;Handle Logical Connectives here
    ;call .handleThirdLevel
    cmp word [rsi], "NO"
    jne .hae0
    cmp byte [rsi + 2], "T"
;    je .not
.hae0:
    cmp word [rsi], "AN"
    jne .hae1
    cmp byte [rsi + 2], "D"
;    je .and
.hae1:
    cmp word [rsi], "OR"
;    je .or
    cmp word [rsi], "XO"
    jne .hae2
    cmp byte [rsi + 2], "R"
;    je .xor
.hae2:
    cmp word [rsi], "IM"
    jne .relationals
    cmp byte [rsi + 2], "P"
;    je .implicaton
;Level 3, Relational Connectives
;.handleThirdLevel:
;   call .handleSecondLevel
.relationals:
    ;Handle Relational connectives
    cmp byte [rsi], "="
;    je .equivalence
    cmp word [rsi], "<>"
;    je .neq
    cmp word [rsi], "><"
;    je .neq
    cmp byte [rsi], "<"
;    je .less
    cmp byte [rsi], ">"
;    je .greater
    cmp word [rsi], "<="
;    je .leq
    cmp word [rsi], ">="
;    je .geq
;Level 2, Addition and Subtraction
.handleSecondLevel:
    call .handleFirstLevel
.parseAdditiveOperators:    
    cmp byte [rsi], '-'
    je .processMinus
    cmp byte [rsi], '+'
    jne .exit              ;No operators, expression evaluated, exit
    push rax
    call .handleFirstLevelSkip   ;Parse first level
.processAdd:    
    pop rcx
    add rax, rcx           ;Add the two numbers
    jmp short .parseAdditiveOperators  ;Search again for + or -
.processMinus:
    push rax
    call .handleFirstLevelSkip   ;Parse first level
    neg rax              ;Change a - b to a + -b
    jmp short .processAdd

;Level 1, Division and multiplication

.handleFirstLevelSkip:
    inc rsi              ;Skip the op symbol
.handleFirstLevel:
    call .handleZerothLevel      ;Call third level
.parseProductOperators:   
    cmp byte [rsi], '/'
    je .processDiv
    cmp byte [rsi], '*'
    jne .exit           ;Neither multiplication or division, return up a level

    push rax
    call .handleZerothLevelSkip   ;Call zeroth level
    pop rcx
    imul rcx             ; Multiplication
    jmp short .parseProductOperators   ;Search again for * or /

.processDiv:
    push rax
    call .handleZerothLevelSkip   ;Call zeroth level
    pop rcx
    xchg rax, rcx
    xor edx, edx         ;Clear rdx for rdx:rax
    idiv rcx             ;Signed division
    jmp .parseProductOperators         ;Search again for * or /

;Level 0, Brackets, numbers and vars.

.handleZerothLevelSkip:
    inc rsi             ;Skip the op symbol
.handleZerothLevel:
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
    cmp al, "A"       ;Alphabetical first char?
    jae .varOrRNDFound      ;Yes, variable found or rnd function or error
    dec rsi            ;Else back one symbol 
    call decimalToHex  ;to read number into rax
    jmp spaceSkip

.varOrRNDFound:
    cmp al, "Z"  
    ja .error   ;Syntax error if char not between A-Z  
    cmp al, "R"
    jne .varFound
    cmp byte [rsi], "N" ;rsi was advanced by 1, check 
    jne .varFound
    cmp byte [rsi+1], "D"
    jne .varFound
    lodsw               ;Advance rsi by 3
    lodsb
    in al, 40h         ;Read timer counter 0
    movzx rax, al
.exit:
    ret                ;Return
.exponentFound:
   jmp short .varConstCheck
.varFound:    
    dec rsi ;Back a char
    push rcx
    call getVarNameLength
    call getNumericVariable ;Get variable value in rax
    add rsi, rcx    ;Go past the edge of the name
    pop rcx
    jmp spaceSkip

.closeBracket:
    inc rsi
    jmp spaceSkip
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
    cmp rbx, -1 ;Variable doesnt exist? Pretend it is 0
    je .noVar
    cmp byte [rbx + memBlock.bBlockType], varBlockType
    jne .stringFoundError
    mov rax, qword [rbx + varBlock.qValue]
.exit:
    pop rbx
    pop rcx
    pop rsi
    ret
.noVar:
    xor eax, eax
    jmp short .exit
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
    je .makeEditInteger      ;Make one!
    cmp byte [rbx + memBlock.bBlockType], varBlockType
    jne .stringFoundError
    mov qword [rbx + varBlock.qValue], rax  ;Save value
.exit:
    pop rbx
    pop rcx
    pop rsi
    ret
.makeEditInteger:
    call makeEditInteger
    jmp short .exit
.stringFoundError:
    lea rbp, typeError
    jmp criticalError

setStringVariable:
;Sets the string pointed to by rdx
;Input: rsi = Pointer to first char of a variable name
;       rdx = Start of string
;Output: rsi = Pointer to first char of variable name
;Keeps adding characters until a 0, : or " encountered
;Adds a 0 to the end
    push rcx
    call getVarNameLength   ;Gets the length of the var name in cx
    call makeEditString     ;Returns a ptr to the var block in rbx
    pop rcx
    ret

findOtherExpressionsOnLine:
;Input: rsi = start of line portion
;Output: rsi = points to first char after first ":" found
;         al = : if it was found or 00 if not
    lodsb
    cmp al, 0   ;Null hit, RIP procedure
    je .exit
    cmp al, ":" ;Strings can be terminated with a :
    jne findOtherExpressionsOnLine
.exit:
    ret
