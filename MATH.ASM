decimalToHex:
    ;Takes ASCII encoded decimal number and 
    ;returns its hex value
    ;Input: rsi = Start of string
    ;       ecx = Number of Digits in digit string (max 255)
    ;Output: rax = Number
    push rbx
    push rcx
    push rdx
    xor ebx, ebx    ;Start with rbx = 0
.processDigits:    
    lodsb           ;Get the first digit in al
    sub al, 30h     ;Reduce to value
    cmp al, 10      ;Digit valid?
    movzx rax, al   ;Clear upper bits
    xor edx, edx    ;Clear for multiplication
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