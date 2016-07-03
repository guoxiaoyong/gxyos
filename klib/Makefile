src       := $(wildcard *.c)
headers   := $(wildcard *.h)
obj       := $(src:%.c=%.o)

useful    := $(src) $(headers) Makefile
rmfiles   := $(filter-out $(useful),$(wildcard *))

all: libkc.a

libkc.a: $(obj)
	ar rcs $@ $(obj)



%.o : %.c
	gcc -m32 -nostdinc -nostdlib -I. -O2 -c -o $@ $^



.PHONY: clean

clean:
	rm -rf $(rmfiles)
