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

handleExpression:
;expr:
;    call expr1          ; Call second tier
;f20:    
;    cmp byte [si],'-'   ; Subtraction operator?
;    je f19              ; Yes, jump
;    cmp byte [si],'+'   ; Addition operator?
;    jne f6              ; No, return
;    push ax
;    call expr1_2        ; Call second tier
;f15:    
;    pop cx
;    add ax,cx           ; Addition
;    jmp f20             ; Find more operators

;f19:
;    push ax
;    call expr1_2        ; Call second tier
;    neg ax              ; Negate it (a - b converted to a + -b)
;    jmp f15

        ;
        ; Handle an expression.
        ; Second tier: division & multiplication.
        ;
;expr1_2:
;    inc si              ; Avoid operator
;expr1:
;    call expr2          ; Call third tier
;f21:   
;    cmp byte [si],'/'   ; Division operator?
;    je f23              ; Yes, jump
;    cmp byte [si],'*'   ; Multiplication operator?
;    jne f6              ; No, return

;    push ax
;    call expr2_2        ; Call third tier
;    pop cx
;    imul cx             ; Multiplication
;    jmp f21             ; Find more operators

;f23:
;    push ax
;    call expr2_2        ; Call third tier
;    pop cx
;    xchg ax,cx
;    cwd                 ; Expand AX to DX:AX
;    idiv cx             ; Signed division
;    jmp f21             ; Find more operators

        ;
        ; Handle an expression.
        ; Third tier: parentheses, numbers and vars.
        ;
;expr2_2:
;    inc si              ; Avoid operator
;expr2:
;    call spaces         ; Jump spaces
;    lodsb               ; Read character
;    cmp al,'('          ; Open parenthesis?
;    jne f24
;    call expr           ; Process inner expr.
;    cmp byte [si],')'   ; Closing parenthesis?
;    je spaces_2         ; Yes, avoid spaces
;    jmp error           ; No, jump to error

;f24:    
;    cmp al, 0x40         ; Variable?
;    jnc f25             ; Yes, jump
;    dec si              ; Back one letter...
;    call input_number   ; ...to read number
;    jmp short spaces

;f25:    
;    cmp al,0x72
;    jne f22
;    cmp byte [si],0x6e
;    jne f22
;    lodsw               ; Advance SI by 2
;    in al,0x40          ; Read timer counter 0
;    mov ah,0       
;    ret

;f22:    
;    call get_variable_2 ; Get variable address
;    xchg ax,bx
;    mov ax,[bx]         ; Read
;    ret                 ; Return
