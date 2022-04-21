#!/bin/sh
assemble:
	nasm BASIC.ASM -o BASIC.BIN -f bin -l BASIC.LST -O0
	dd if=./BASIC.BIN of=./MyDisk.ima bs=512 seek=100 conv=notrunc
	cp ./MyDisk.ima ./MyDiskMSD.ima

#Add a new boot sector to current image
loader:
	nasm LOADER.ASM -o LOADER.BIN -f bin -l LOADER.LST -O0
	dd if=LOADER.BIN of=MyDisk.ima bs=512 count=1 conv=notrunc
	cp ./MyDisk.ima ./MyDiskMSD.ima

#Create a fresh disk image
fresh:
	dd if=/dev/zero of=./MyDisk.IMA bs=512 count=2880 conv=notrunc

	nasm BASIC.ASM -o BASIC.BIN -f bin -l BASIC.LST -O0
	dd if=./BASIC.BIN of=./MyDisk.ima bs=512 seek=100 conv=notrunc

	dd if=./scpbios.bin of=./MyDisk.ima bs=512 seek=33 conv=notrunc

	nasm LOADER.ASM -o LOADER.BIN -f bin -l LOADER.LST -O0
	dd if=LOADER.BIN of=MyDisk.ima bs=512 count=1 conv=notrunc

	cp ./MyDisk.ima ./MyDiskMSD.ima