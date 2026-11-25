%{
#include <stdio.h> 
#include <stdlib.h>
#include <string.h>

typedef struct {
    int    count;
    char **args;
} ArgList;

void yyerror(const char *s);
int yylex();
extern FILE *yyin;

static int tempCount = 1, labelCount = 1;
char* newTemp() {
    char *t = malloc(16);
    sprintf(t, "t%d", tempCount++);
    return t;
}
char* newLabel() {
    char *L = malloc(16);
    sprintf(L, "L%d", labelCount++);
    return L;
}

#define MAXLBL 100
static char* lblStack[MAXLBL];
static int   lblTop = -1;
void pushLabel(char *L) { lblStack[++lblTop] = L; }
char* popLabel()      { return lblStack[lblTop--]; }
%}

%union {
    char*           str;
    int             ival;
    struct { char* place; } expr;
    ArgList*        alist;
}

%token <str> ID STRING_CONST INT_CONST CHAR_CONST
%token TBEGIN TEND TENDPROGRAM TENDVARDECL PROGRAM VARDECL INT CHAR
%token IF ELSE WHILE FOR TO DO INC DEC PRINT SCAN
%token <str> ASSIGN PLUS_ASSIGN MINUS_ASSIGN MULT_ASSIGN DIV_ASSIGN MOD_ASSIGN
%token EQ GT LT GEQ LEQ NEQ
%token PLUS MINUS MUL DIV MOD
%token LPAREN RPAREN COMMA SEMICOLON COLON ':' LBRACKET RBRACKET
%token <ival> DIGITS
%token <str> ERROR

%nonassoc  LOWER_THAN_ELSE
%nonassoc ELSE 

%type  <expr>   expression term factor
%type  <alist>  expr_list print_args id_list
%type  <ival>   inc_dec
%type  <str>    relop

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
  | /* empty */
    ;

declaration:
    LPAREN ID opt_array COMMA data_type RPAREN SEMICOLON
    ;

opt_array:
    LBRACKET DIGITS RBRACKET
  | /* empty */
    ;

data_type:
    INT
  | CHAR
    ;

block:
    TBEGIN stmt_list TEND
    ;


stmt_list:
    statement SEMICOLON stmt_list
  | /* empty */
    ;

statement:
    assignment
  | while_stmt
  | for_stmt
  | print_stmt
  | scan_stmt
  | selection_stmt
  | block
    ;

selection_stmt
    : IF LPAREN expression relop expression RPAREN
        { 
          char *tcond = newTemp();
          char *lelse = newLabel();
          char *lexit = newLabel();
          printf("%s := %s %s %s\n", tcond, $3.place, $4, $5.place);
          printf("if %s == 0 goto %s\n", tcond, lelse);
          pushLabel(lexit);
          pushLabel(lelse);
        }
      statement
      opt_else
    ;

opt_else
  : /* no ELSE */ %prec LOWER_THAN_ELSE
      {
        char *lelse = popLabel();
        printf("%s:\n", lelse);
      }
  | ELSE
      {
        char *lelse = popLabel();
        char *lexit = popLabel();
        printf("goto %s\n", lexit);
        printf("%s:\n", lelse);
        pushLabel(lexit);
      }
    statement
      {
        char *lexit = popLabel();
        printf("%s:\n", lexit);
      }
  ;

/* ---------- ASSIGNMENTS ---------- */
assignment:
    ID ASSIGN expression
    {
        printf("%s := %s\n", $1, $3.place);
    }
  | ID PLUS_ASSIGN expression
    {
        char *t = newTemp();
        printf("%s := %s + %s\n", t, $1, $3.place);
        printf("%s := %s\n", $1, t);
    }
  | ID MINUS_ASSIGN expression
    {
        char *t = newTemp();
        printf("%s := %s - %s\n", t, $1, $3.place);
        printf("%s := %s\n", $1, t);
    }
  | ID MULT_ASSIGN expression
    {
        char *t = newTemp();
        printf("%s := %s * %s\n", t, $1, $3.place);
        printf("%s := %s\n", $1, t);
    }
  | ID DIV_ASSIGN expression
    {
        char *t = newTemp();
        printf("%s := %s / %s\n", t, $1, $3.place);
        printf("%s := %s\n", $1, t);
    }
  | ID MOD_ASSIGN expression
    {
        char *t = newTemp();
        printf("%s := %s %% %s\n", t, $1, $3.place);
        printf("%s := %s\n", $1, t);
    }
    ;

/* ---------- WHILE ---------- */
while_stmt:
    WHILE LPAREN expression relop expression RPAREN DO
      {
        char *lstart = newLabel(), *lend = newLabel();
        pushLabel(lend);
        pushLabel(lstart);
        printf("%s:\n", lstart);
        char *tcond = newTemp();
        printf("%s := %s %s %s\n", tcond, $3.place, $4, $5.place);
        printf("if %s == 0 goto %s\n", tcond, lend);
      }
    block
      {
        char *lstart = popLabel(), *lend = popLabel();
        printf("goto %s\n", lstart);
        printf("%s:\n", lend);
      }
    ;

/* ---------- FOR ---------- */
for_stmt:
    FOR ID ASSIGN expression TO expression inc_dec expression DO
      {
        char *lstart = newLabel(), *lend = newLabel();
        pushLabel(lend);
        pushLabel(lstart);
        printf("%s := %s\n", $2, $4.place);
        printf("%s:\n", lstart);
        char *tcond = newTemp();
        if ($7 > 0)
          printf("%s := %s <= %s\n", tcond, $2, $6.place);
        else
          printf("%s := %s >= %s\n", tcond, $2, $6.place);
        printf("if %s == 0 goto %s\n", tcond, lend);
      }
    block
      {
        if ($7 > 0)
          printf("%s := %s + %s\n", $2, $2, $8.place);
        else
          printf("%s := %s - %s\n", $2, $2, $8.place);
        char *lstart = popLabel(), *lend = popLabel();
        printf("goto %s\n", lstart);
        printf("%s:\n", lend);
      }
    ;

/* ---------- PRINT ---------- */
print_stmt:
    PRINT LPAREN print_args RPAREN
      {
        for (int i = 0; i < $3->count; i++)
          printf("param %s\n", $3->args[i]);
        printf("call print,%d\n", $3->count);
      }
    ;

/* ---------- SCAN ---------- */
scan_stmt:
    SCAN LPAREN STRING_CONST COMMA id_list RPAREN
      {
        printf("param %s\n", $3);
        for (int i = 0; i < $5->count; i++)
          printf("param %s\n", $5->args[i]);
        printf("call scan,%d\n", $5->count + 1);
      }
    ;

/* ---------- RELATIONAL OPS ---------- */
relop:
    EQ  { $$ = strdup("=="); }
  | NEQ { $$ = strdup("!="); }
  | GT  { $$ = strdup(">");  }
  | LT  { $$ = strdup("<");  }
  | GEQ { $$ = strdup(">="); }
  | LEQ { $$ = strdup("<="); }
    ;

/* ---------- EXPRESSIONS ---------- */
expression:
    expression PLUS term
      {
        char *t = newTemp();
        printf("%s := %s + %s\n", t, $1.place, $3.place);
        $$.place = t;
      }
  | expression MINUS term
      {
        char *t = newTemp();
        printf("%s := %s - %s\n", t, $1.place, $3.place);
        $$.place = t;
      }
  | term
      { $$.place = $1.place; }
    ;

term:
    term MUL factor
      {
        char *t = newTemp();
        printf("%s := %s * %s\n", t, $1.place, $3.place);
        $$.place = t;
      }
  | term DIV factor
      {
        char *t = newTemp();
        printf("%s := %s / %s\n", t, $1.place, $3.place);
        $$.place = t;
      }
  | term MOD factor
      {
        char *t = newTemp();
        printf("%s := %s %% %s\n", t, $1.place, $3.place);
        $$.place = t;
      }
  | factor
      { $$.place = $1.place; }
    ;

factor:
    LPAREN expression RPAREN
      { $$.place = $2.place; }
  | ID
      { $$.place = $1; }
  | INT_CONST
      {
        $$.place = strdup($1);
      }
  | CHAR_CONST
      {
        char *c = malloc(2);
        c[0] = $1[1];
        c[1] = '\0';
        $$.place = c;
      }
    ;

/* ---------- LISTS for PRINT/SCAN ---------- */
expr_list:
    expression
      {
        ArgList *L = malloc(sizeof *L);
        L->count = 1;
        L->args  = malloc(sizeof *L->args);
        L->args[0] = $1.place;
        $$ = L;
      }
  | expression COMMA expr_list
      {
        ArgList *rest = $3;
        ArgList *L = malloc(sizeof *L);
        L->count = rest->count + 1;
        L->args  = malloc(sizeof *L->args * L->count);
        L->args[0] = $1.place;
        for (int i = 0; i < rest->count; i++)
          L->args[i+1] = rest->args[i];
        free(rest->args);
        free(rest);
        $$ = L;
      }
    ;

print_args:
    STRING_CONST
      {
        ArgList *L = malloc(sizeof *L);
        L->count = 1;
        L->args  = malloc(sizeof *L->args);
        L->args[0] = strdup($1);
        $$ = L;
      }
  | STRING_CONST COMMA expr_list
      {
        ArgList *rest = $3;
        ArgList *L = malloc(sizeof *L);
        L->count = rest->count + 1;
        L->args  = malloc(sizeof *L->args * L->count);
        L->args[0] = strdup($1);
        for (int i = 0; i < rest->count; i++)
          L->args[i+1] = rest->args[i];
        free(rest->args);
        free(rest);
        $$ = L;
      }
    ;

id_list:
    ID
      {
        ArgList *L = malloc(sizeof *L);
        L->count = 1;
        L->args  = malloc(sizeof *L->args);
        L->args[0] = strdup($1);
        $$ = L;
      }
  | ID COMMA id_list
      {
        ArgList *rest = $3;
        ArgList *L = malloc(sizeof *L);
        L->count = rest->count + 1;
        L->args  = malloc(sizeof *L->args * L->count);
        L->args[0] = strdup($1);
        for (int i = 0; i < rest->count; i++)
          L->args[i+1] = rest->args[i];
        free(rest->args);
        free(rest);
        $$ = L;
      }
    ;

/* direction for FOR */
inc_dec:
    INC { $$ =  1; }
  | DEC { $$ = -1; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error: %s\n", s);
    exit(1);
}
int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input file>\n", argv[0]);
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if (!yyin) { perror("Error opening file"); return 1; }
    yyparse();
    fclose(yyin);
    return 0;
}