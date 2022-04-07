getLineInput:
    ;Sets rsi to the inputstring
    xor ah, ah
    mov byte [strLen], ah   ;Zero the char counter
    lea rdi, inString   ;Move to start of line
    mov rsi, rdi
    push rdi
    mov ecx, maxLineLen
    xor al, al    ;Ensure the input line is sanitised
    rep stosb
    pop rdi
.getChar:
    call ttyIn
    cmp al, 0Dh ;Line Feed
    je .gliExit
    cmp al, 08h ;Bspace
    je .glibspace
    cmp byte [strLen], -2   ;If at max length (255 chars), simply beep and wait for either bspace or enter
    je .gliFull 
    test al, al
    je .gliExtendedChar
    jmp short .gliCheckCase
.glibspace:
    test byte [strLen], -1  ;This will only be zero if strLen=0
    jz .getChar
    dec rdi ;Go back by one position in the input line
    dec byte [strLen]
    mov al, 08h
    call ttyOutChar
    mov al, 20h  
    call ttyOutChar
    mov al, 08h
    call ttyOutChar
    jmp short .getChar
.gliCheckCase:
    ;al has char
    call ttyOutChar ;Echo the char as is, but store it uppercase
    cmp al, "a"
    jb .gliccStore
    cmp al, "z"
    ja .gliccStore
    sub al, 20h
.gliccStore:
    stosb   ;Increment the pointer, add char to buffer
    inc byte [strLen]   ;Inc char count
    jmp short .getChar
.gliExtendedChar:
    ;Currently, extended chars do nothing, 
    ; eventually add F1-F10 functionality
    ; and arrow key support
    jmp short .getChar
.gliExit:
    lea rbp, crlf
    call ttyOutString
    mov byte [rdi], 0   ;Null terminate string here
    ret
.gliFull:
    mov al, 07h
    call ttyOutChar
    jmp .getChar

ttyOutChar:
    mov ah, 0Eh
    int 30h
    ret
ttyOutString:
;Print 0 terminated strings
    mov eax, 1304h
    int 30h
    ret
ttyIn:
    xor ah, ah
    int 36h
    ret
ttyClear:
    mov eax, 0500h  ;Set page zero as the default page
    int 30h
    mov ah, 02h
    xor edx, edx    ;Set screen cursor to top right corner
    mov bh, dl      ;Set cursor for page 0
    int 30h
    mov bh, 07h     ;Grey/Black attribs
    mov eax, 0600h  ;Clear whole screen
    int 30h
    ret