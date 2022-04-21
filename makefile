#!/bin/sh
assemble:
	nasm ./Source/BASIC.ASM -o ./Binaries/BASIC.BIN -f bin -l ./Source/BASIC.LST -O0
	dd if=./Binaries/BASIC.BIN of=./Images/MyDisk.ima bs=512 seek=100 conv=notrunc
	cp ./Images/MyDisk.ima ./Images/MyDiskMSD.ima

#Add a new boot sector to current image
loader:
	nasm ./Source/Boot/LOADER.ASM -o ./Binaries/LOADER.BIN -f bin -l ./Source/Boot/LOADER.LST -O0
	dd if=./Binaries/LOADER.BIN of=./Images/MyDisk.ima bs=512 count=1 conv=notrunc
	cp ./MyDisk.ima ./MyDiskMSD.ima

#Create a fresh disk image
fresh:
	dd if=/dev/zero of=./MyDisk.IMA bs=512 count=2880 conv=notrunc

	nasm ./Source/BASIC.ASM -o ./Binaries/BASIC.BIN -f bin -l ./Source/BASIC.LST -O0
	dd if=./Binaries/BASIC.BIN of=./Images/MyDisk.ima bs=512 seek=100 conv=notrunc

	dd if=./Binaries/scpbios.bin of=./Images/MyDisk.ima bs=512 seek=33 conv=notrunc

	nasm ./Source/Boot/LOADER.ASM -o ./Binaries/LOADER.BIN -f bin -l ./Source/Boot/LOADER.LST -O0
	dd if=./Binaries/LOADER.BIN of=./Images/MyDisk.ima bs=512 count=1 conv=notrunc

	cp ./MyDisk.ima ./MyDiskMSD.ima