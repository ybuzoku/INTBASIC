    dw 0AA55h 
;First verify I have Enough RAM for my program and then run
    mov eax, 0E801h ;Get low memory count in ax
    int 35h
    cmp ax, 200000h/400h ;Divide 2Mb into 1Kb chunks.
    jb bad
    mov ecx, 0C0000100h ;Read FS MSR
    rdmsr
    mov edi, edx        ;Get the hi dword, and clear the upper bytes
    shl rdi, 20h        ;Shift high
    mov edi, eax        ;Get the low dword in
    mov rax, rdi
    lea rsi, section.resSeg.start
    add rdi, bssLen
    mov ecx, 1000h
    mov rax, rdi    ;Move rax after the BSS area
    rep movsq
    jmp qword rax
bad:
    lea rbp, badmsg
    mov eax, 1304h
    int 30h
    xor ah, ah
    int 36h
    int 38h
badmsg: db "Not Enough Memory. Press any key to enter SYSDEBUG...",0