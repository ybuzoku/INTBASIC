
funTbl:
;Use PASCAL strings to know how long the comparisons need to be
;All function pointers are saved as distances from the head
; of the function table
    db 4,"NEW"
    dq funTbl - newProgram

    db 5,"LIST"
    dq funTbl - listProgram

    db 4,"RUN"
    db funTbl - runProgram

    db 6,"PRINT"
    dq funTbl - printStatement

    db 6,"INPUT"
    dq funTbl - getInput

    db 3,"IF"
    dq funTbl - handleIf

    db 5,"GOTO"
    dq funTbl - fancyJmp

    db 7,"SYSTEM"
    dq funTbl - returnToDOS

    db -1    ;Demarkate the end of the table

newProgram: 
;Simply reset the program pointers
listProgram:
;Go line by line and echo the program lines, inserting a crlf after each
runProgram:
;Go to each line, one at a time, skip the line number and execute the expr
printStatement:
;String must be "" delimited
getInput:
;Take a string as a prompt
handleIf:
;Evaluate the string after IF is greater than 0, THEN goto line x
fancyJmp:
;GOTO, the hell of every dumb high level programmer
returnToDOS:
    ret