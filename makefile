#!/bin/sh
assemble:
	nasm BASIC.ASM -o BASIC.BIN -f bin -l BASIC.LST -O0
	dd if=./BASIC.BIN of=./MyDisk.ima bs=512 seek=100 conv=notrunc
# Copy to make a fake USB device
	cp ./MyDisk.ima ./MyDiskMSD.ima