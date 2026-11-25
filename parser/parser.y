%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex();
extern FILE *yyin;
%}

%union {
    char* str;
    int ival;
}

%token <str> ID STRING_CONST INT_CONST CHAR_CONST
%token TBEGIN TEND TENDPROGRAM TENDVARDECL PROGRAM VARDECL INT CHAR
%token IF ELSE WHILE FOR TO DO INC DEC PRINT SCAN
%token ASSIGN PLUS_ASSIGN MINUS_ASSIGN MULT_ASSIGN DIV_ASSIGN MOD_ASSIGN
%token EQ GT LT GEQ LEQ NEQ
%token PLUS MINUS MUL DIV MOD
%token LPAREN RPAREN COMMA SEMICOLON COLON LBRACKET RBRACKET
%token DIGITS
%token ERROR
%start program

%%

program:
    TBEGIN PROGRAM COLON variable_decl stmt_list TENDPROGRAM
    ;

variable_decl:
    TBEGIN VARDECL COLON declarations TENDVARDECL
    ;

declarations:
    declaration declarations
    |
    ;

declaration:
    LPAREN ID opt_array COMMA data_type RPAREN SEMICOLON
    ;

opt_array:
    LBRACKET DIGITS RBRACKET
    |
    ;

data_type:
    INT
    | CHAR
    ;

stmt_list:
    statement SEMICOLON stmt_list
    |
    ;

statement:
    assignment
    | if_stmt
    | if_else_stmt
    | while_stmt
    | for_stmt
    | print_stmt
    | scan_stmt
    ;

assignment:
    ID assign_op expression
    ;

assign_op:
    ASSIGN | PLUS_ASSIGN | MINUS_ASSIGN | MULT_ASSIGN | DIV_ASSIGN | MOD_ASSIGN
    ;

if_stmt:
    IF LPAREN condition RPAREN block
    ;

if_else_stmt:
    IF LPAREN condition RPAREN block ELSE block
    ;

while_stmt:
    WHILE LPAREN condition RPAREN DO block
    ;

for_stmt:
    FOR ID assign_op expression TO expression inc_dec expression DO block
    ;

inc_dec:
    INC | DEC
    ;

print_stmt:
    PRINT LPAREN print_args RPAREN
    ;

print_args:
    STRING_CONST
    | STRING_CONST COMMA expr_list
    ;

scan_stmt:
    SCAN LPAREN STRING_CONST COMMA id_list RPAREN
    ;

id_list:
    ID
    | ID COMMA id_list
    ;

block:
    TBEGIN stmt_list TEND
    ;

condition:
    expression rel_op expression
    | ID
    ;

rel_op:
    EQ | GT | LT | GEQ | LEQ | NEQ
    ;

expression:
    expression PLUS term
    | expression MINUS term
    | term
    ;

term:
    term MUL factor
    | term DIV factor
    | term MOD factor
    | factor
    ;

factor:
    LPAREN expression RPAREN
    | ID
    | INT_CONST
    | CHAR_CONST
    ;

expr_list:
    expression
    | expression COMMA expr_list
    ;


%%

extern char *yytext;
extern int yylineno;

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error at line %d near token '%s': %s!!!\n", yylineno, yytext, s);
    exit(1);
}


int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input file>\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror("Error opening file");
        return 1;
    }

    if (yyparse() == 0)
        printf("Successfully parsed !!!\n");

    fclose(yyin);
    return 0;
}
