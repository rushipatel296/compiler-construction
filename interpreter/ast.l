%{
#include "ast.h"
#include "ast.tab.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
extern int yylineno;
void yyerror(const char *s);
%}

%option yylineno
DIGITS     [0-9]+
LETTER     [a-z]
ID         {LETTER}({LETTER}|[0-9])*
INT_CONST  \([0-9]+,[ ]*(2|8|10)\)
CHAR_CONST \'[^\']\'
STRING     \"[^\"]*\"

%%
"begin"            { return TBEGIN; }
"end program"      { return TENDPROGRAM; }
"end VarDecl"      { return TENDVARDECL; }
"end"              { return TEND; }
"program"          { return PROGRAM; }
"VarDecl"          { return VARDECL; }
"int"              { return INT; }
"char"             { return CHAR; }
"if"               { return IF; }
"else"             { return ELSE; }
"while"            { return WHILE; }
"for"              { return FOR; }
"to"               { return TO; }
"do"               { return DO; }
"inc"              { return INC; }
"dec"              { return DEC; }
"print"            { return PRINT; }
"scan"             { return SCAN; }

":="               { return ASSIGN; }
"+="               { return PLUS_ASSIGN; }
"-="               { return MINUS_ASSIGN; }
"*="               { return MULT_ASSIGN; }
"/="               { return DIV_ASSIGN; }
"%="               { return MOD_ASSIGN; }

"="                { return EQ; }
">"                { return GT; }
"<"                { return LT; }
">="               { return GEQ; }
"<="               { return LEQ; }
"<>"               { return NEQ; }
"+"                { return PLUS; }
"-"                { return MINUS; }
"*"                { return MUL; }
"/"                { return DIV; }
"%"                { return MOD; }
"("                { return LPAREN; }
")"                { return RPAREN; }
","                { return COMMA; }
";"                { return SEMICOLON; }
":"                { return COLON; }
"["                { return LBRACKET; }
"]"                { return RBRACKET; }
"\n"		   {}	

{INT_CONST}        { yylval.str = strdup(yytext); return INT_CONST; }
{CHAR_CONST}       { yylval.str = strdup(yytext); return CHAR_CONST; }
{STRING}           { yylval.str = strdup(yytext); return STRING_CONST; }
{ID}               { yylval.str = strdup(yytext); return ID; }
{DIGITS}           { yylval.ival = atoi(yytext); return DIGITS; }

[ \t\n\r]+         {}    
"//".*             {}   
"/*"([^*]|\*+[^*/])*\*+"/"   {} 

.                  { return ERROR; }
%%

int yywrap() { return 1; }

