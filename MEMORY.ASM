allocateBlock:
;Allocates a program memory block, the caller then fixes the specifics
;Output: rbx = Pointer to generic memory block, or -1 if memory full
;       Caller needs to fill in, block size, block type and specifics
    mov rbx, qword [lastBlock]    ;Get the last block in the chain
    mov byte [rbx + memBlock.bSignature], notLastMemBlock ;Make it not be the last
    movzx rdx, word [rbx + memBlock.wBlockSize] ;Goto end of block
    add rbx, rdx    ;Move rbx over the previous last block
    cmp qword [maxMemAddr], rbx ;rbx above maxmemory? 
    ja .memoryFull
    mov qword [lastBlock], rbx  ;New last block
    mov byte [rbx + memBlock.bSignature], lastMemBlock
    ret
.memoryFull:
    mov rbx, -1
    ret

findVariable:
;Input: rsi = Source string for variable name
;       ecx = Length of variable name (max 40)
;Output: rsi = ptr to varBlock OR -1 if doesnt exist
    push rbx
    push rcx
    push rdx
    push rdi
    mov rbx, qword [mcbChain]   ;Start of the chain
.search:
    cmp byte [rbx + memBlock.bBlockType], varBlockType
    je .varFound    ;We found a variable
.invalid:
    ;Are we at the end of the chain?
    cmp byte [rbx + memBlock.bSignature], lastMemBlock
    je .varNotFound ;At the end of the chain and var not found? Error!
    movzx rdx, word [rbx + memBlock.wBlockSize]
    add rbx, rdx    ;Goto next block
    jmp short .search
.varFound:
    ;Compare to see the var is our var
    lea rdi, qword [rbx + varBlock.sVarName] ;point rdi to the name string
    repe cmpsb  ;Compare one byte at a time
    jne .invalid
    mov rsi, rbx    ;Move varblock into rsi
    jmp short .exit
.varNotFound:
    mov rsi, -1
.exit:
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret

findFirstLine:
;Output: rbx = Pointer to the first program block
;         dx = Number of the first line
    mov rbx, qword [firstLinPtr]
    mov dx, word [firstLinNum]
    ret

;FIRST SEARCH FOR A LINE NUMBER BEFORE INSERTING IT INTO THE CHAIN
;IF THE LINE NUMBER IS FOUND, REPLACE THE COMMAND STRING

searchForProgramLine:
;Walk the program chain looking to see if a line number exists. If it does,
; return a pointer to the block in rbx. If it doesn't, return -1 in rbx
;Input: dx = Line number
;Output: rbx = Pointer to program block 
    mov rbx, qword [firstLinPtr]
.search:
    cmp word [rbx + progLineBlock.wLineNum], dx ;Equal line numbers?
    je .lineFound
    mov rbx, qword [rbx + progLineBlock.qPtr]   ;Walk chain
    inc rbx ;At the end? If yes, this would be 0 now
    jnz .search ;Not zero? Keep searching
    dec rbx ;Make it -1 again
.lineFound:
    ret

insertProgramLine:
;Walk the program chain looking for the biggest number less than our
; line number. Once we have reached the end of the chain, insert the block there, or
; if there is no block, then we are the last in the chain
;Input: rsi = New Program Block to be added
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    call findFirstLine  ;Get start of program in rbx and line number in dx
;First check if we should be the first line
    mov cx, word [rsi + progLineBlock.wLineNum] ;Save line number in cx
    cmp rbx, -1 ;Empty program marker
    je .first
    cmp dx, cx  ;If cx is below dx, then our entry is first
    jb .first    
;Use ax as the best line number and rdi as the pointer to that block
    mov ax, -1  ;Marker to indicate no insertion
.walk:
    cmp qword [rbx + progLineBlock.qPtr], -1    ;We are at the end
    je .sort
    mov rbx, qword [rbx + progLineBlock.qPtr] ;Walk chain in rbx
    cmp cx, word [rbx + progLineBlock.wLineNum]
    ja .walk    ;If line number is above my line number, keep walking
.candidate:
    ;If the new line number is below the old line number, reject
    cmp ax, word [rbx + progLineBlock.wLineNum]
    jb .walk
    mov rdi, rbx
    mov ax, word [rbx + progLineBlock.wLineNum]
    jmp short .walk
.sort:
    inc ax  ;If no candidates, exit
    jz .skipLink
    ;rdi points to the previous line to link to
    mov rdx, qword [rdi + progLineBlock.qPtr]
    mov qword [rdi + progLineBlock.qPtr], rsi   ;Insert self here
    mov qword [rsi + progLineBlock.qPtr], rdx   ;Link new block to next line
    jmp short .exit
.skipLink:
    mov qword [rbx + progLineBlock.qPtr], rsi   ;Link rsi to last element in list
    mov qword [rsi + progLineBlock.qPtr], -1    ;End of chain marker
    jmp short .exit
.first:
    mov qword [firstLinPtr], rsi
    mov word [firstLinNum], cx
    mov qword [rsi + progLineBlock.qPtr], rbx   ;Put the old first line as second line
.exit:
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

memoryDetection:
    mov eax, 0E820h
    int 35h     ;rax = ptr to start, rsi = ptr to data table, each entry 24 bytes
    jmp short .fsa1
.findStartAddr:
    add rsi, 24 ;Goto next entry
.fsa1:
    test cx, cx
    jz .worstCase
    dec cx
    mov rbx, qword [rsi]    ;Get the address entry into rbx
    cmp rbx, rax    
    jne .findStartAddr
    mov rax, qword [rsi + 8] ;Get the number of bytes saved into rax

    lea rdx, section.programArea.vstart
    sub rdx, rbx    ;Get the size of the interpreter and internal data area
    sub rax, rdx    ;Remove the number of bytes reserved to the interpreter
    call printdecimalword
    add rbx, rax    ;Add number of bytes to start address
    mov qword [maxMemAddr], rbx ;Save this address
.exit:
    ret
.worstCase:
;Assume 2Mb MAX memory, rax has base address
    mov rbx, 200000h    ;2Mb value
    sub rbx, rax
    mov rax, rbx    ;Get value in rax
    call printdecimalword
    mov qword [maxMemAddr], 200000h
    ret

