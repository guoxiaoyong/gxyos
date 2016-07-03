
asmsrc   :=  $(wildcard *.asm)
src      :=  $(wildcard *.c)
hdr      :=  $(wildcard *.h)
php      :=  $(wildcard *.php)
txt      :=  bochsrc.txt font.txt
lds      :=  link.ld
useful   :=  $(asmsrc) $(src) $(hdr) $(txt) $(lds) $(php) Makefile copyfile.tcl klib
rmfiles  :=  $(filter-out $(useful), $(wildcard *))
bin      :=  $(asmsrc:.asm=.bin)
CFLAGS := -m32 -O2


all: floppy.bin


floppy.bin: floppy.asm kernel.bin
	nasm -f bin -o $@ $<
	expect copyfile.tcl $@ kernel.bin

kernel.bin: asmhead.bin bootpack.bin
	objcopy -S -O binary bootpack.bin tmp.bin
	cat asmhead.bin tmp.bin > $@

bootpack.bin: bootpack.o naskfunc.o font.o dsctbl.o fifo.o graphic.o int.o mouse.o keyboard.o memory.o sheet.o link.ld
	ld -T link.ld -L./klib -o  $@  $^  -lkc

font.o: font.c

font.c: font.bin
	xxd -i $< | sed 's/font_bin/hankaku/g' > font.c

font.bin: font.txt
	php makefont.php $< $@


%.bin: %.txt
	php makefont.php $^ $@

asmhead.bin: asmhead.asm entry.info
	nasm -f bin `cat entry.info` -o $@ $<


%.o: %.asm
	nasm -f elf32 -o $@ $^

bootpack.o: bootpack.c
	gcc -m32 -I./klib -nostdlib -O2 -c -o $@ $^
	

entry.info: bootpack.bin
	echo "-dENTRY="0x`readelf -a bootpack.bin | grep Hari | grep --color=never -oe '[0-9A-Fa-f]\{8\}'`> entry.info




.PHONY: clean install
clean:
	rm -rf $(rmfiles)

	

