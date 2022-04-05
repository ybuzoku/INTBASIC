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
    ;Memory stuff
    lea rax, section.programArea.vstart
    mov qword [minMemAddr], rax
    mov qword [lastBlock], rax  ;Start writing at this location
    xor eax, eax
    dec rax
    mov qword [mcbChain], rax   ;-1
    lea rbp, mainmsg
    call ttyOutString
    call memoryDetection
    lea rbp, bytemsg
    call ttyOutString
    mov byte [strLen], 0
mainLoop:
    lea rsp, stacktop    ;Reinitialize stack pointer
    lea rax, mainLoop
    push rax    ;Save address on stack
    lea rbp, prompt
    call ttyOutString
    call getLineInput
    jmp saveExecuteLine


;For any error, syntax or otherwise, come here
criticalError:
;Called with rbp pointing at error message
    call ttyOutString
    jmp mainLoop    ;Trash input line, restart line input

;-------------------------------:
;---------Misc routines---------:
;-------------------------------:

printdecimalword:
;Takes the qword in rax and prints its decimal representation
    push rax
    lea rdi, digitString   ;Use the default line as a buffer
    ;Sanitise the digit buffer
    push rdi
    push rcx
    push rax
    xor eax, eax
    mov ecx, digitStringLen/8
    rep stosq
    pop rax
    pop rcx
    pop rdi

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
