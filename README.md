# SCR INTBASIC/64

A 64-Bit integer BASIC interpreter, written on top of SCP/BIOS by Yll Buzoku. 
Requires SCP/BIOS. Assembled using NASM 2.15.05.
SCP/BIOS may be acquired here: https://github.com/ybuzoku/Standalone-SCPBIOS

Currently in pre-release and needs to be extensively tested. Syntactically as close to GW-BASIC as I could muster. 
The set of keywords recognised by the interpreter is a strict subset of GW-BASIC.

## Features:
- Line editor allows for lines up to 255 characters long. If you type more than 255 chars, the computer will beep.
- Variable names of up to 40 characters.
- Strings of up to 255 characters long.
- Two data types: signed 64-bit integers and string.
- String variable names MUST be terminated with a $, i.e. name$ = "Player name"
- Line tracing features via TRON and TROFF instructions
- Access to SCP/BIOS Debugger via the DEBUG instruction
- Line numbers up to 65535 allowed.


## Upcoming features:
- Left and Right Arrow keys to allow for editing individual lines
- Improvements to the screen driver to allow for line 25 to have a some built in data displayed (think like GW-BASIC or IBM ROM BASIC)
- PEEK and POKE instructions to allow for accessing RAM directly using variables (allowing for crude pointer-like behaviour)


## Known issues:
- Replacing the start line might cause you to lose the second line in the program.
- Cannot do relational operations on strings.
- All text is capitalised, even in strings.
- Probably many others; if you find them, please submit an issue immediately with as much information as you can about what caused the bug.


This program can be built using the makefile to build a disk image which can run on SCP/BIOS capable machines.
Note SCP/BIOS must be loaded in memory for this application to run.

TODO: Write a full guide to operations.
# GUIDE TO OPERATIONS
The short version is as follows. 
- INTBASIC supports running BASIC statements in both direct and indirect mode. 
   When you start the interpreter, you are in direct mode.
   If you wish to type a program, you must prefix each line with a line number and a space before typing in the statement(s) for that line. 
   In direct mode, you can simply type in the statement and strike enter.
- All keywords need to be postfixed by a space. 
- If you wish to place multiple expressions on a line, they must be separated by a colon : which has a space on BOTH sides of the colon.
- All strings must be encapsulated in speech marks.
- Variables can be assigned with and without the LET keyword.
- True is considered to be any non-zero value (and is by default -1)
- False is considered to be 0.

### BASIC Keywords supported
The following BASIC keywords are supported:

- LET [varname] = [expression]    
    Assigns the result of the expression to the variable or the string to the string variable
- [varname] = [expression]    
    Same as LET
- IF [condition] THEN [statement] ELSE [statement]  
    If the condition is true, then execute the THEN statement, else the ELSE statement
- IF [condition] GOTO [expression] ELSE [statement]  
    If the condition is true, then goto the line number that is the result of the expression, else as above.
- WHILE [condition] ... WEND  
    While the condition is true execute the expressions between the WHILE and WEND
- GOTO [expression]  
    Unconditionally branch to the line number that is the result of the expression
- GOSUB [expression] ... RETURN  
    Goto the line number that is the result of the expression. When RETURN is encountered, return to the next expression after GOSUB
- PRINT [list of expressions][;]  
    Print a line of expressions, either results of operations or strings. Multiple things can be printed on the same line, separated by a ;
- ? [list of expressions][;]  
    Short hand form of the above
- REM [comment]  
    A REMark or comment. All instructions on the line will be ignored, even if split with a :
- ' [comment]  
    Short hand form of the above
- INPUT[;][prompt string;] variable  
    Will accept a prompt string, enclosed in speechmarks. A semicolon after the prompt string supresses the default ? prompt. 
    Provide a variable to store the response in
- CLS  
    Clears the screen
- END  
    Ends the program early. A program may terminate when there are no lines left to execute.
- RND  
    Generates a very bad, random 8-bit value. This will improved in later versions to give a good signed 64 bit random number.

### Logical operators
Logical operators are available for use with numbers and numerical variables. All logical operators are binary except for NOT which is unary, and takes
an argument on the right hand side of the operation. All LOGICAL operators must be enclosed on both sides by a space.
The following logical operators are available in order of precedence:
- NOT
- AND
- OR
- XOR
- EQV, logical equivalence, equivalent to A EQV B = NOT(A XOR B)
- IMP, logical implication, equivalent to A IMP B = NOT(A) OR B

### Shift operators

A number of bit shift operations have also been implemented. They can shift up to a MAXIMUM of 255 bits at a time. 
If a larger number is used for the bit shift, only the value MOD 255 is taken
- SHL, Left shift, used as follows: A SHL B => Shift A left number of bits by the amount described by the expression in B
- SHR, Right shift, used as follows: A SHR B => Shift A right number of bits by the amount described by the expression in B

### Relational operators

Relational operators are available for use with numbers and numerical variables, and return a boolean True or False depending on their evaluation.
The following relational operators are available:
- Equality, =
- Inequality, <> or ><
- Less than, <
- Greater than, >
- Less than or equal to, <=
- Greater than or equal to, >=

### Arithmetic operators

Arithmetic operators are available for use with numbers and numeriacal variables. They follow the BODMAS rules of arithemtic. One additional added operation 
is the modulus operation, which computes the remainder of a quotient, i.e. 5 MOD 3 resolves to 2.
If a open bracket is found without a close bracket, a syntax error will occur.
Division by 0 or attempting to compute a number modulo 0 will trigger an error message on the screen and the result of the division will be either 2^63 - 1 
or -(2^63 - 1) depending on the sign of the Dividend.

### Interpreter commands

Finally, the following commands exist as interpreter instructions. They SHOULD not be used in a program but only used as directives when in direct mode.
Except where noted, using the following instructions in a program can have undesirable effects. Furthermore, to prevent accidentally using these 
instructions in a program, I have made it such that these instructions must be the LAST thing on any line. Unless you are sure you understand what you
are doing, I would refrain from using the following instructions in anything other that direct mode.

- RUN, runs the stored program
- SYSTEM, resets the interpreter
- DEBUG, starts the SCP/BIOS debugger
- NEW, deletes the currently executing program
- LIST, lists the current stored program listing.
- TRON, TRace ON, starts program tracing when the program is run
- TROFF, TRace OFF, ends program tracing when the program is run

### Installation

If using the disk image in the repository (MyDisk.ima or MyDiskMSD.ima), you may flash it directly to a SCP/BIOS compatible USB stick and boot from it.
The BASIC program uses the built in bootloader. 
You may also use emulators such as QEMU or BOCHS to run this program. 
You may also assemble the source code yourself using the makefile provided. In that case however, the disk image generated however will NOT have SCP/BIOS on it. You will have to source it yourself.
All details of how to run SCP/BIOS and programs in conjunction with SCP/BIOS can be found in the SCP/BIOS manual.

### Final remarks
If you find any bugs, please let me know by either submitting a issue on Github or contacting me directly. 
Pull requests will be considered but not without first submitting an issue (so that I know what the error you're trying to fix is).
I am also happy to accept feature improvements and new keywords too as well as general comments on the interpreter!

Enjoy programming in BASIC!




