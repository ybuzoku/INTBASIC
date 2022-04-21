allocateBlock:
;Allocates a program memory block, the caller then fixes the specifics
;Output: rbx = Pointer to generic memory block, or -1 if memory full
;       Caller needs to fill in, block size, block type and specifics
    push rdx
.ab0:
    mov rbx, qword [lastBlock]    ;Get the last block in the chain
    cmp rbx, -1 ;First allocation?
    je .firstAllocation
    mov byte [rbx + memBlock.bSignature], notLastMemBlock ;Make it not be the last
    movzx rdx, word [rbx + memBlock.wBlockSize] ;Goto end of block
    add rbx, rdx    ;Move rbx over the previous last block
    mov rdx, qword [maxMemAddr]
    cmp rbx, rdx ;rbx above maxmemory? 
    ja .memoryFull
    mov qword [lastBlock], rbx  ;New last block
    mov byte [rbx + memBlock.bSignature], lastMemBlock
.exit:
    pop rdx
    ret
.memoryFull:
    mov rbx, -1
    jmp short .exit
.firstAllocation:
;Deal with first allocation
    lea rbx, section.programArea.vstart   ;Get this as the head of the chain
    mov qword [lastBlock], rbx
    mov qword [mcbChain], rbx
    mov byte [rbx + memBlock.bSignature], lastMemBlock
    mov word [rbx + memBlock.wBlockSize], 0 ;Dummy block
    jmp short .exit

findVariable:
;Input: rsi = Source string for variable name
;       ecx = Length of variable name (max 40)
;Output: rbx = ptr to varBlock/strBlock OR -1 if doesnt exist
    push rax
    push rcx
    push rdx
    push rsi
    push rdi
    mov rbx, qword [mcbChain]   ;Start of the chain
    cmp rbx, -1 ;Chain empty?
    je .exit
.search:
    cmp byte [rbx + memBlock.bBlockType], varBlockType
    je .varFound    ;We found a numerical variable
    cmp byte [rbx + memBlock.bBlockType], datBlockType
    je .datFound    ;We found a string variable
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
    push rcx
    push rsi
    repe cmpsb  ;Compare one byte at a time
    pop rsi
    pop rcx
    jne .invalid
    clc
    jmp short .exit
.datFound:
    lea rdi, qword [rbx + stringBlock.sVarName] ;point rdi to the name string
    push rcx
    push rsi
    repe cmpsb  ;Compare one byte at a time
    pop rsi
    pop rcx
    jne .invalid
    clc
    jmp short .exit
.varNotFound:
    mov rbx, -1
.exit:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rax
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
    cmp rbx, -1
    je .lineFound
.search:
    cmp word [rbx + progLineBlock.wLineNum], dx ;Equal line numbers?
    je .lineFound
    mov rbx, qword [rbx + progLineBlock.qPtr]   ;Walk chain
    cmp rbx, -1
    jne .search ;Not -1? Keep searching
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
    cmp cx, dx  ;If cx is below dx, then our entry is first
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

makeEditInteger:
;Will make a variable if it is new name, or edit the value if it already exists
;Input: rsi = Var name
;       (e)cx = Length of varname, max 40 chars
;       rax = Value
    call findVariable   ;rbx returned with var block or -1
    cmp rbx, -1
    je .newVar
    mov qword [rbx + varBlock.qValue], rax
    ret
.newVar:
    call allocateBlock
    cmp rbx, -1
    je .error
    mov qword [rbx + varBlock.qValue], rax  ;Save value
    mov word [rbx + varBlock.wBlockSize], cx    ;Save length of name
    add word [rbx + varBlock.wBlockSize], varBlock_size ;Add full block size
    mov byte [rbx + varBlock.bBlockType], varBlockType  ;Block type
    push rdi
    lea rdi, qword [rbx + varBlock.sVarName]
    call strcpy ;Copy the string name into block buffer
    pop rdi
    ret
.error:
    lea rbp, noMem
    jmp criticalError
makeEditString:
;Will make a string if it is new name, or replace the string. Strings are null termin
;Input: rsi = Var name
;       ecx = Length of varname, max 40 chars
;       rdx = Ptr to string itself
    push rdi
    push rsi
    push rax
    push rbx
    call findVariable   ;rbx returned with string block or -1
    cmp rbx, -1
    jne .strcopy
    call allocateBlock
    cmp rbx, -1
    je .error
    mov word [rbx + stringBlock.wBlockSize], cx    ;Save length of name
    add word [rbx + stringBlock.wBlockSize], stringBlock_size ;Add full block size
    mov byte [rbx + stringBlock.bBlockType], datBlockType  ;Block type
    lea rdi, qword [rbx + stringBlock.sVarName]
    call strcpy ;Copy the string name into block buffer
.strcopy:
    lea rdi, qword [rbx + stringBlock.string]   ;point to string space
    mov rsi, rdx    ;Point rsi to the string itself
    call terminatedstrcpy
    xor al, al
    stosb   ;Store the null delimiter
    pop rbx
    pop rax
    pop rsi
    pop rdi
    ret
.error:
    lea rbp, noMem
    jmp criticalError
;------------------------------------------------:
;  The below are misc memory related functions   :
;------------------------------------------------:
terminatedstrcpy:
;rdi = Destination String
;rsi = Source String
;Copy a terminated string
    push rax
.copy:
    lodsb   ;Get char in al and inc rsi
    cmp al, 0
    je .exit
    cmp al, ":"
    je .exit
    cmp al, 22h ;Speechmark
    je .exit
    stosb   ;Save char from al and inc rdi
    jmp short .copy 
.exit:
    pop rax
    ret
strcpy:
;rdi = Destination string
;rsi = Source string
;rcx = Number of Chars to copy
    push rdi
    push rsi
    push rcx
    rep movsb
    pop rcx
    pop rsi
    pop rdi
    ret
strlen:
;Input: rsi = String start
;Output: rsi = String start
;        ecx = String length, inclusive of NULL char
    push rax
    push rsi
    xor ecx, ecx    ;Clear counter
.search:
    lodsb
    inc ecx
    test al, al ;Is this a null char?
    jnz .search ;Null not found
.exit:
    pop rsi
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

