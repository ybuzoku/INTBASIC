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

printdecimalword:
;Takes the qword in rax and prints its signed decimal representation
    push rax
    push rbx
    lea rdi, digitString   ;Use the default line as a buffer
    ;Sanitise the digit buffer
    push rdi
    push rcx
    push rax

    mov ecx, digitStringLen/8
    rep stosq
    pop rax
    pop rcx
    pop rdi

    push rax    ;Save rax for the sign bit later
    rol rax, 1  ;Test the sign bit
    test al, 1
    ror rax, 1  ;Undo the roll
    jz .noCompliment
    neg rax     ;Get the 2's compliment of rax
;Clear the sign bit, print the number from bits 62:0
.noCompliment:
    shl rax, 1  ;Go past the edge
    shr rax, 1  ;Return zero extended
    add rdi, digitStringLen - 1 ;Go to the end of the buffer
    std ;Reverse string ops
    push rax
    xor al, al  ;Place delimiter
    stosb
    pop rax
    mov rbx, 0Ah  ;Divide by 10
.pdw0:
    xor edx, edx
    div rbx
    add dl, '0'
    cmp dl, '9'
    jbe .pdw1
    add dl, 'A'-'0'-10
.pdw1:
    push rax
    mov al, dl    ;Save remainder byte
    stosb   ;Store the byte and sub one from rdi
    pop rax
    test rax, rax
    jnz .pdw0

    ;Now add a minus sign if sign bit set
    pop rax ;Get the original for the sign bit
    rol rax, 1  ;Bring the sign bit low
    test al, 1
    jz .printString
    mov al, "-"
    stosb   ;Store minus sign and decrement rdi
.printString:
    cld ;Return string ops to normal
    inc rdi ;Skip the extra 0 that was inserted
    mov rbp, rdi    ;Point rbp to the head of the string
    call ttyOutString
    pop rbx
    pop rax
    ret
