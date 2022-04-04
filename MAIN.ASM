start:
    mov eax, 0C501h
    int 35h
    mov eax, 0500h  ;Set page zero as the default page
    int 30h
    mov ah, 02h
    xor edx, edx    ;Set screen cursor to top right corner
    mov bh, dl      ;Set cursor for page 0
    int 30h
    mov bh, 07h     ;Grey/Black attribs
    mov eax, 0600h  ;Clear whole screen
    int 30h
    cld
    lea rax, section.programArea.vstart
    mov qword [mcbChain], rax
    mov qword [lastBlock], rax
    lea rbp, mainmsg
    mov eax, 1304h
    int 30h
    call memoryDetection
    lea rbp, bytemsg
    mov eax, 1304h
    int 30h
    mov byte [strLen], 0
mainLoop:
    lea rsp, stacktop    ;Reinitialize stack pointer
    lea rax, mainLoop
    push rax
    lea rbp, prompt
    call ttyOutString
    call getLineInput
    call saveExecuteLine
    ret
saveExecuteLine:
;This function will execute the line if it is an interactive expression
; or store it in the program if it has a line number
    ret
getLineInput:
    xor ah, ah
    mov byte [strLen], ah   ;Zero the char counter
    lea rdi, inString   ;Move to start of line
    push rdi
    mov ecx, maxLineLen
    mov al, 0Dh    ;Ensure the input line is sanitised
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
    ;Currently, extended chars do nothing, eventually add F1-F10 functionality
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

;For any error, syntax or otherwise, come here
criticalError:
    lea rbp, errmsg
    call ttyOutString
    jmp mainLoop    ;Trash input line, restart line input

;-------------------------------:
;---------Misc routines---------:
;-------------------------------:
ttyOutChar:
    mov ah, 0Eh
    int 30h
    ret
ttyOutString:
    mov eax, 1304h
    int 30h
    ret
ttyIn:
    xor ah, ah
    int 36h
    ret

printdecimalword:
;Takes the qword in rax and prints its decimal representation
    push rax
    lea rdi, inString   ;Use the default line as a buffer
    add rdi, maxLineLen - 1 ;Go to the end of the buffer
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
    stosb   ;Store the byte and add one to rdi
    pop rax
    test rax, rax
    jnz .pdw0
    cld ;Return string ops to normal
    inc rdi ;Skip the extra 0 that was inserted
    mov rbp, rdi    ;Point rbp to the head of the string
    call ttyOutString
    pop rax
    ret
