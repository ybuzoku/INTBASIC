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
;Declares a stack overflow if less than 20 stack words available
    push rax
    lea rax, stack
    add rax, 10*8   ;Be extra careful
    cmp rsp, rax
    ;if rsp is below rax, fail
    jb .stack
    pop rax
.handleFourthLevel:
    call .handleThirdLevel
.parseLogicals:
    cmp dword [rsi], "AND "
    je .and
    cmp word [rsi], "OR"
    je .or
    cmp dword [rsi], "XOR "
    je .xor
    cmp dword [rsi], "EQV "
    je .eqv
    cmp dword [rsi], "IMP "
    je .imp
    cmp dword [rsi], "ROL "
    je .leftRoll
    cmp dword [rsi], "ROR "
    je .rightRoll
    cmp dword [rsi], "SHL "
    je .leftShift
    cmp dword [rsi], "SHR "
    jne .exit
.rightShift:
;Shift count is truncated to between 1 and 255 for shift and Roll
    push rax
    call .handleThirdLevelSkip
    pop rcx
    xchg rax, rcx   ;Move count into rcx, and shift target to rax
    shr rax, cl
    jmp .parseLogicals

.leftShift:
    push rax
    call .handleThirdLevelSkip
    pop rcx
    xchg rax, rcx   ;Move count into rcx, and shift target to rax
    shl rax, cl
    jmp .parseLogicals

.rightRoll:
    push rax
    call .handleThirdLevelSkip
    pop rcx
    xchg rax, rcx   ;Move count into rcx, and shift target to rax
    ror rax, cl
    jmp .parseLogicals

.leftRoll:
    push rax
    call .handleThirdLevelSkip
    pop rcx
    xchg rax, rcx   ;Move count into rcx, and shift target to rax
    rol rax, cl
    jmp .parseLogicals

.imp:
    ;A => B == ¬A OR B
    push rax
    call .handleThirdLevelSkip
    pop rcx ;rcx has A
    not rcx
    or rax, rcx
    jmp .parseLogicals

.not:
    call .handleThirdLevelSkip  ;Get result in rax
    not rax ;Save 1's compliment in rax
    jmp .parseLogicals
.and:
    push rax
    call .handleThirdLevelSkip
    pop rcx
    and rax, rcx
    jmp .parseLogicals
.or:
    dec rsi ;handle third level skips skips one too many for or
    push rax
    call .handleThirdLevelSkip
    pop rcx
    or rax, rcx
    jmp .parseLogicals
.xor:
    push rax
    call .handleThirdLevelSkip
    pop rcx
    xor rax, rcx
    jmp .parseLogicals
.eqv:
;Not XOR, ie only if the two bits are equal do we set it
    push rax
    call .handleThirdLevelSkip
    pop rcx
    xor rax, rcx
    not rax
    jmp .parseLogicals

;Level 3, Relational Connectives
.handleThirdLevelSkip:
    add rsi, 3  ;Go past the end of the word
.handleThirdLevel:
   call .handleSecondLevel
.parseRelationals:
    ;Handle Relational connectives
    cmp byte [rsi], "="
    je .processEq
    cmp word [rsi], "<>"
    je .processNeq
    cmp word [rsi], "><"
    je .processNeq
    cmp byte [rsi], "<"
    je .processLess
    cmp byte [rsi], ">"
    jne .exit
.processGreater:
    cmp byte [rsi + 1], "=" ;Is this a GEQ
    je .processGeq
    push rax
    call .handleSecondLevelSkip
    pop rcx ;lhs, rax has rhs of >

    push rbx
    xor ebx, ebx
    cmp rcx, rax
    mov rax, -1 ;Default to true
    cmovle rax, rbx  ;Move the false value if less than
    pop rbx
    jmp .parseRelationals
.processLess:
    cmp byte [rsi + 1], "=" ;Is this a LEQ
    je .processLeq
    push rax
    call .handleSecondLevelSkip
    pop rcx ;lhs, rax has rhs of <

    push rbx
    xor ebx, ebx
    cmp rcx, rax
    mov rax, -1 ;Default to true
    cmovge rax, rbx  ;Move the false value if greater than or equal to
    pop rbx
    jmp .parseRelationals

.processGeq:
;Symbol has two chars so skip second char
    inc rsi ;Skip first symbol
    push rax
    call .handleSecondLevelSkip
    pop rcx ;lhs, rax has rhs of >=

    push rbx
    xor ebx, ebx
    cmp rcx, rax
    mov rax, -1 ;Default to true
    cmovl rax, rbx  ;Move the false value if less than
    pop rbx
    jmp .parseRelationals

.processLeq:
;Symbol has two chars so skip second char
    inc rsi
    push rax
    call .handleSecondLevelSkip
    pop rcx ;lhs, rax has rhs of <=

    push rbx
    xor ebx, ebx
    cmp rcx, rax
    mov rax, -1 ;Default to true
    cmovg rax, rbx  ;Move the false value if greater than
    pop rbx
    jmp .parseRelationals

.processEq:
    push rax
    call .handleSecondLevelSkip
    pop rcx ;lhs, rax has rhs of =

    push rbx 
    xor ebx, ebx
    cmp rcx, rax
    mov rax, -1
    cmovne rax, rbx ;Only set rax to 0 if not equal
    pop rbx
    jmp .parseRelationals

.processNeq:
;Symbol has two chars so skip second char
    inc rsi
    push rax
    call .handleSecondLevelSkip
    pop rcx ;lhs, rax has rhs of <>

    push rbx 
    xor ebx, ebx
    cmp rcx, rax
    mov rax, -1 ;Assume true, not equal
    cmove rax, rbx ;Only set rax to 0 if equal
    pop rbx
    jmp .parseRelationals

;Level 2, Addition and Subtraction
.handleSecondLevelSkip:
    inc rsi
.handleSecondLevel:
    call .handleFirstLevel
.parseAdditiveOperators:    
    cmp byte [rsi], "-"
    je .processMinus
    cmp byte [rsi], "+"
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

;Level 1, Exponent, Division and multiplication

.handleFirstLevelSkip:
    inc rsi              ;Skip the op symbol
.handleFirstLevel:
    call .handleZerothLevel      ;Call third level
.parseProductOperators:
    cmp byte [rsi], "^"
    je .exponentFound
    cmp byte [rsi], "/"
    je .processDiv
    cmp byte [rsi], "*"
    je .processMult
    cmp dword [rsi], "MOD "
    jne .exit     ;Neither exp, multiplication, division or MOD, return up a level

    add rsi, 3  ;Skip the MOD part
    push rax
    call .handleZerothLevelSkip   ;Call zeroth level
    pop rcx
    test rax, rax        ;Dividend is returned in rax
    jz .divByZero
    xchg rax, rcx
    xor edx, edx         ;Clear rdx for rdx:rax
    idiv rcx             ;Signed division
    mov rax, rdx         ;Save remainder in rax
    jmp .parseProductOperators         ;Search again for * or /
    
.processMult:
    push rax
    call .handleZerothLevelSkip   ;Call zeroth level
    pop rcx
    imul rcx             ; Multiplication
    jmp short .parseProductOperators   ;Search again for * or /

.processDiv:
    push rax
    call .handleZerothLevelSkip   ;Call zeroth level
    pop rcx
    test rax, rax        ;Dividend is returned in rax
    jz .divByZero
    xchg rax, rcx
    xor edx, edx         ;Clear rdx for rdx:rax
    idiv rcx             ;Signed division
    jmp .parseProductOperators         ;Search again for * or /
.divByZero:
    ;If a division by zero occurs, print the message and return
    ; result as signed 64 bit MAX or MIN + 1 depending on if the 
    ; number being divided is positive or negative
    push rbp
    lea rbp, divZer
    call ttyOutString   ;Print the message
    mov eax, 1 ;Get 1 in ebp and clear upper bits
    ror rax, 1 ;Put the bit in bit 63
    not rax    ;Set all other bits and clear sign bit
    pop rbp
    jmp .parseProductOperators

.exponentFound:
    ;rax has the number to exponentiate
    push rax
    call .handleZerothLevelSkip  ;Parse the inner expression
    pop rcx
    xchg rcx, rax
    ;rax has the number to exponentiate, rcx has the number of times to loop imul
    push rbx
    mov rbx, rax    ;Save a copy of rax in rbx
    dec rcx
.imulLoop:
    xor edx, edx
    imul rbx
    dec rcx
    jnz .imulLoop
    pop rbx
    jmp .parseProductOperators


;Level 0, Brackets, numbers and vars.

.handleZerothLevelSkip:
    inc rsi             ;Skip the op symbol
.handleZerothLevel:
    call spaceSkip
    lodsb               ;Read char and adv rsi
    cmp al, '('
    jne .varConstCheck
    call handleAlgebraicExpression  ;Parse the inner expression
    cmp byte [rsi], ')'   
    je .closeBracket     ;If close bracket, goto skip spaces
    jmp .error     ;Otherwise, error
  
.varConstCheck:
    cmp al, "A"       ;Alphabetical first char?
    jae .varOrRNDFound      ;Yes, variable found or rnd function or error
    dec rsi            ;Else back one symbol 
    call decimalToHex  ;to read number into rax
    jmp spaceSkip

.varOrRNDFound:
    dec rsi
;Evaluate UNARY operators here in reverse stack order of importance
    cmp dword [rsi], "NOT "
    je .not
    inc rsi
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
.stack:
    lea rbp, stkOvflw
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
