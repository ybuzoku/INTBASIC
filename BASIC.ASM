    [map all BASIC.MAP]
    [DEFAULT REL]
    BITS 64
%include "MEM.INC"
Segment .text align=1
%include "RELOC.ASM"
Segment dSeg nobits align=1 start=0
%include "BSS.ASM"
Segment resSeg follows=.text align=1 vfollows=dSeg valign=1
%include "MAIN.ASM"
%include "PARSE.ASM"
%include "COMMANDS.ASM"
%include "MATH.ASM"
%include "MEMORY.ASM"
%include "BASICDAT.ASM"
Segment programArea follows=resSeg align=1 vfollows=resSeg valign=1
ENDOFPROGRAM: