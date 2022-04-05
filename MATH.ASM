decimalToHex:
    ;Takes ASCII encoded decimal number and 
    ;returns its hex value
    ;Input: rsi = Start of numeric ONLY string
    ;Output: rax = Number
    ;        rsi = First non-numeric char past end of number
    push rbx
    push rcx
    push rdx
    xor ebx, ebx    ;Start with rbx = 0
.processDigits:    
    lodsb           ;Get the first digit in al
    sub al, 30h     ;Reduce to value
    xor edx, edx    ;Clear for multiplication
    cmp al, 10      ;Digit valid? Propagte CF
    movzx rax, al   ;Clear upper bits
    xchg rax, rbx
    jnc .exit       ;Digit was not valid, exit
    mov ecx, 10     ;Multiply result by 10
    mul rcx
    add rbx, rax    ;Add the new digits
    jmp short .processDigits
.exit:
    dec rsi         ;rsi points to first non-digit
    pop rdx
    pop rcx
    pop rbx
    ret