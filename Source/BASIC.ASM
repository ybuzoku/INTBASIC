    [map all ./Source/BASIC.MAP]
    [DEFAULT REL]
    BITS 64
%include "./Source/Include/MEM.INC"
Segment .text align=1
%include "./Source/BASIC/RELOC.ASM"
Segment dSeg nobits align=1 start=0
%include "./Source/BASIC/BSS.ASM"
Segment resSeg follows=.text align=1 vfollows=dSeg valign=1
%include "./Source/BASIC/MAIN.ASM"
%include "./Source/BASIC/TTY.ASM"
%include "./Source/BASIC/PROCESS.ASM"
%include "./Source/BASIC/PARSE.ASM"
%include "./Source/BASIC/COMMANDS.ASM"
%include "./Source/BASIC/CTRLFLOW.ASM"
%include "./Source/BASIC/MATH.ASM"
%include "./Source/BASIC/MEMORY.ASM"
%include "./Source/BASIC/BASICDAT.ASM"
Segment programArea follows=resSeg align=1 vfollows=resSeg valign=1
ENDOFPROGRAM: