CC ?= gcc
INPUT ?= ../examples/sum.txt
SRC = 

codegen: codegen.tab.c lex.yy.c $(SRC)
	$(CC) -o $@ codegen.tab.c lex.yy.c $(SRC)

codegen.tab.c codegen.tab.h: codegen.y
	bison -d codegen.y

lex.yy.c: codegen.l codegen.tab.h
	flex codegen.l

run: codegen
	./codegen $(INPUT)

clean:
	rm -f codegen codegen.tab.c codegen.tab.h lex.yy.c

.PHONY: run clean
