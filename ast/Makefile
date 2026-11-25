CC ?= gcc
INPUT ?= ../examples/sum.txt
SRC = driver.c

ast: ast.tab.c lex.yy.c $(SRC)
	$(CC) -o $@ ast.tab.c lex.yy.c $(SRC)

ast.tab.c ast.tab.h: ast.y
	bison -d ast.y

lex.yy.c: ast.l ast.tab.h
	flex ast.l

run: ast
	./ast $(INPUT)

clean:
	rm -f ast ast.tab.c ast.tab.h lex.yy.c

.PHONY: run clean
