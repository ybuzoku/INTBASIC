start:
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
    call cleanProgram
    lea rbp, mainmsg
    mov eax, 1304h
    int 30h
    mov eax, 0E801h
    int 35h
    and eax, 0FFFFh
    shl rax, 0Ah    ;Convert Kb to bytes
    call printdecimalword
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
    lea rdi, inString
    mov rbx, rdi
    mov cl, byte [strLen]   ;Get number of chars in string
    mov al, 20h ;Skip preceeding spaces
    repe scasb  ;IF the first char in the string is a question mark => Interactive
    mov al, byte [rdi - 1]  ;Get the first non-space char into al
    mov rdi, rbx    ;Return rdi to start of line
    cmp al, "?"
    jne .store
    ;Attempt to execute line as is
    jmp criticalError
.store:
    ;Now look for line number, if it exists, place it at position, else error
    mov ecx, 3  ;Line numbers can be between 0 and 999
    ret
executeLine:
    ret
getLineInput:
    xor ah, ah
    mov byte [strLen], ah   ;Zero the char counter
    lea rdi, inString   ;Move to start of line
.getChar:
    call ttyIn
    cmp al, 0Dh ;Line Feed
    je .gliExit
    cmp al, 08h ;Bspace
    je .glibspace
    cmp byte [strLen], -1   ;If at max length, simply beep and wait for either bspace or enter
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
    xor rcx, rcx
    xor ebp, ebp    ;Use bp as #of digits counter
    mov rbx, 0Ah  ;Divide by 10
.pdw0:
    inc ebp
    shl rcx, 8    ;Space for next nybble
    xor edx, edx
    div rbx
    add dl, '0'
    cmp dl, '9'
    jbe .pdw1
    add dl, 'A'-'0'-10
.pdw1:
    mov cl, dl    ;Save remainder byte
    test rax, rax
    jnz .pdw0
.pdw2:
    mov al, cl    ;Get most sig digit into al
    shr rcx, 8    ;Get next digit down
    call ttyOutChar
    dec ebp
    jnz .pdw2
    ret
