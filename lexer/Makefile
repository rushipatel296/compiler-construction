CC ?= gcc
INPUT ?= ../examples/sum.txt

lexer: lex.yy.c
	$(CC) -o $@ lex.yy.c

lex.yy.c: lexer.l
	flex lexer.l

run: lexer
	./lexer $(INPUT)

clean:
	rm -f lexer lex.yy.c

.PHONY: run clean
