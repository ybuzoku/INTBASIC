allocateBlock:
;Allocates a program memory block, the caller then fixes the specifics
;Output: rbx = Pointer to generic memory block, or -1 if memory full
;       Caller needs to fill in, block size, block type and specifics
    mov rbx, qword [lastBlock]    ;Get the last block in the chain
    mov byte [rbx + memBlock.bSignature], notLastMemBlock ;Make it not be the last
    movzx rdx, word [rbx + memBlock.wBlockSize] ;Goto end of block
    add rbx, rdx    ;Move rbx over the previous last block
    cmp rbx, qword [maxMemAddr]
    ja .memoryFull  ;Above? fail
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
;Walk the memory block chain looking for the biggest number less than our
; line number. Once we have reached the end of the chain, insert the block there, or
; if there is no block, then
;Input: rsi = New Program Block to be added
    call findFirstLine  ;Get start of program in rbx and line number in dx
;First check if we should be the first line now?
    cmp dx, word [rsi + progLineBlock.wLineNum]
    jng .notFirst    ;If sign change, 
.notFirst:
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

