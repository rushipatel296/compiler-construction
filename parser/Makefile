CC ?= gcc
INPUT ?= ../examples/sum.txt
SRC = 

parser: parser.tab.c lex.yy.c $(SRC)
	$(CC) -o $@ parser.tab.c lex.yy.c $(SRC)

parser.tab.c parser.tab.h: parser.y
	bison -d parser.y

lex.yy.c: parser.l parser.tab.h
	flex parser.l

run: parser
	./parser $(INPUT)

clean:
	rm -f parser parser.tab.c parser.tab.h lex.yy.c

.PHONY: run clean
