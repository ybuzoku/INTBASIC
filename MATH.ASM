decimalToHex:
    ;Takes ASCII encoded decimal number and 
    ;returns its hex value
    ;Input: rsi = Start of string
    ;       ecx = Number of Digits in digit string (max 255)
    ;Output: rax = Number
    push rbx
    push rdx
    push rdi
    push rbp
    std             ;Reverse string traversal direction
    mov rdi, rsi    ;Save pointer in rdi
    add rsi, rcx    ;Go to end of number string
    xor ebp, ebp    ;Clear rbp, to store value in
    mov ebx, 1      ;Start with ebx = 1
.processDigits:
    lodsb           ;Get the first digit in al
    sub al, 30h     ;Reduce to value
    movzx rax, al   ;Clear upper bits
    xor edx, edx    ;Clear for multiplication
    mul rbx         ;Multiply digit value by rbx
    add rbp, rax    ;Add value, overflows past 64 bit integers ignored
    dec cl          ;Decrement the number of chars left to process
    jz .exit        ;If now zero, exit!
    add rbx, rbx    ;Multiply by 2
    lea rbx, qword [rbx + 4*rbx] ;Multiply by 5
    jmp short .processDigits
.exit:
    cld             ;Return string traversal direction to normal
    pop rbp
    pop rdi
    pop rdx
    pop rbx
    ret
