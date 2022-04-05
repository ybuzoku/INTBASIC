
funTbl:
;Use PASCAL strings to know how long the comparisons need to be
;All function pointers are saved as distances from the head
; of the function table
    db 4,"NEW"
    dw newProgram - funTbl 

    db 5,"LIST"
    dw listProgram - funTbl 

    db 4,"RUN"
    dw runProgram - funTbl

    db 6,"PRINT"
    dw printStatement - funTbl

    db 6,"INPUT"
    dw getInput - funTbl

    db 3,"IF"
    dw handleIf - funTbl

    db 5,"GOTO"
    dw fancyJmp - funTbl

    db 7,"SYSTEM"
    dw returnToDOS - funTbl

    db 4,"FOR"
    dw forLoop - funTbl

    db 4, "CLS"
    dw cls - funTbl

    db -1    ;Demarkate the end of the table

newProgram: 
;Simply reset the program pointers
    lea rax, section.programArea.vstart
    mov qword [minMemAddr], rax
    mov qword [lastBlock], rax  ;Start writing at this location
    mov qword [mcbChain], rax   ;Create a mock MCB here
    mov byte [rax + memBlock.bSignature], lastMemBlock
    mov word [rax + memBlock.wBlockSize], 0 ;Dummy block, no size, gets overwritten
    xor eax, eax
    mov byte [strLen], al
    lea rdi, inString
    mov ecx, maxLineLen
    rep stosb
    mov byte [currentLine], 10  ;Default to line 10
    mov qword [firstLinPtr], -1 ;No program in memory
    ret
listProgram:
;Go line by line and echo the program lines, inserting a crlf after each
    mov al, 2
    ret
runProgram:
;Go to each line, one at a time, skip the line number and execute the expr
;First thing it does, takes the first line number and moves it to current line number
    mov al, 3
    ret
printStatement:
;String must be "" delimited
    mov al, 4
    ret
getInput:
;Take a string as a prompt
    mov al, 5
    ret
handleIf:
;Evaluate the string after IF is greater than 0, THEN goto line x
;IF exp1 THEN exp2
    mov al, 6
    ret
fancyJmp:
;GOTO, the hell of every dumb high level programmer
    mov al, 7
    ret
returnToDOS:
    mov al, 8
    ret
forLoop:
    mov al, 9
    ret
cls:
    jmp ttyClear
