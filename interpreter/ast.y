%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "symtab.h"
#include "ast_execute.h"

extern FILE *yyin;
extern int   yylineno;
int yylex(void);
void yyerror(const char *s);
ASTNode *root;  
%}

%union {
    char    *str;
    int      ival;
    ASTNode *ast;
}

%token <str> ID STRING_CONST INT_CONST CHAR_CONST
%token       TBEGIN TEND TENDPROGRAM TENDVARDECL PROGRAM VARDECL INT CHAR
%token       IF ELSE WHILE FOR TO DO PRINT SCAN
%token <str> ASSIGN PLUS_ASSIGN MINUS_ASSIGN MULT_ASSIGN DIV_ASSIGN MOD_ASSIGN
%token <str> INC DEC EQ GT LT GEQ LEQ NEQ
%token       PLUS MINUS MUL DIV MOD
%token       LPAREN RPAREN COMMA SEMICOLON COLON LBRACKET RBRACKET
%token <ival> DIGITS
%token        ERROR

%type <ast>   program variable_decl declarations declaration opt_array data_type
              stmt_list statement assignment if_stmt if_else_stmt
              while_stmt for_stmt print_stmt scan_stmt
              id_list block condition expression term factor

%type <str> assign_op inc_dec rel_op

%%

program:	TBEGIN PROGRAM COLON variable_decl stmt_list TENDPROGRAM {root = newNode("", 2, $4, $5);};

variable_decl:	TBEGIN VARDECL COLON declarations TENDVARDECL {$$ = newNode("", 1, $4);};

declarations:	declaration declarations {$$ = newNode("", 2, $1, $2);}
  	    	|			 {$$ = NULL;};
  	 
declaration:	LPAREN ID opt_array COMMA data_type RPAREN SEMICOLON {
        ASTNode *idNode   = newLeaf("ID", $2);  free($2);
        if($3){
            $$ = newNode("", 3, idNode, $3, $5);
        }else{
            $$ = newNode("", 2, idNode, $5);
        }
    }
    ;
opt_array:
    LBRACKET DIGITS RBRACKET {
        char buf[32];
        snprintf(buf, sizeof(buf), "%d", $2);
        $$ = newLeaf("DIM", buf);
    }
  	|  {
        $$ = NULL;
    }
    ;
data_type:	INT  { $$ = newLeaf("TYPE", "int"); }
  		| CHAR { $$ = newLeaf("TYPE", "char"); }
    		;

stmt_list:	statement SEMICOLON stmt_list {
        	$$ = newNode("", 2, $1, $3);
    		}
  		|  {
        	$$ = NULL;
    		}
    		;

statement:	assignment     { $$ = $1; }
  		| if_stmt        { $$ = $1; }
		| if_else_stmt   { $$ = $1; }
  		| while_stmt     { $$ = $1; }
  		| for_stmt       { $$ = $1; }
  		| print_stmt     { $$ = $1; }
  		| scan_stmt      { $$ = $1; }
  		;

assignment:	ID assign_op expression {
        	ASTNode *idNode = newLeaf("ID", $1); free($1);
        	$$ = newNode($2, 2, idNode, $3);  free($2);
    		}
    		;

assign_op:	ASSIGN      { $$ = strdup(":="); }
  		| PLUS_ASSIGN { $$ = strdup("+="); }
  		| MINUS_ASSIGN{ $$ = strdup("-="); }
  		| MULT_ASSIGN { $$ = strdup("*="); }
  		| DIV_ASSIGN  { $$ = strdup("/="); }
  		| MOD_ASSIGN  { $$ = strdup("%="); }
    		;

if_stmt:	IF LPAREN condition RPAREN block {
        	$$ = newNode("if", 2, $3, $5);
    		}
    		;
    		
if_else_stmt:	IF LPAREN condition RPAREN block ELSE block {
        	$$ = newNode("ifelse", 3, $3, $5, $7);
    		}
    		;

while_stmt:	WHILE LPAREN condition RPAREN DO block {
        	$$ = newNode("while", 2, $3, $6);
    		}
    		;

for_stmt:	FOR ID assign_op expression TO expression inc_dec expression DO block {
        		ASTNode *idNode     = newLeaf("id", $2); free($2);
        		ASTNode *initAssign = newNode($3, 2, idNode, $4); free($3);
        		ASTNode *step = newNode($7, 1, $8); free($7);
        		$$ = newNode("for", 4, initAssign, $6, step, $10);
    		}
    		;

inc_dec:	INC { $$ = strdup("inc"); }
  		| DEC { $$ = strdup("dec"); }
    		;

print_stmt:	PRINT LPAREN STRING_CONST RPAREN {
        		ASTNode *s = newLeaf("STRING", $3); free($3);
       			$$ = newNode("print", 1, s);
    			}
  		| PRINT LPAREN STRING_CONST COMMA expression RPAREN {
        		ASTNode *s = newLeaf("STRING", $3); free($3);
        		$$ = newNode("print", 2, s, $5);
    			}
  			;

scan_stmt:	SCAN LPAREN STRING_CONST COMMA id_list RPAREN {
        	ASTNode *s = newLeaf("STRING", $3); free($3);
        	$$ = newNode("SCAN", 2, s, $5);
    		}
    		;

id_list:	ID {
        	$$ = newLeaf("ID", $1); free($1);
    		}
  		| ID COMMA id_list {
        	ASTNode *i = newLeaf("ID", $1); free($1);
        	$$ = newNode("ID_LIST", 2, i, $3);
    		}
    		;

block:		TBEGIN stmt_list TEND {
      		$$ = newNode("", 1, $2);
    		}
    		;

condition:	expression rel_op expression {
        	$$ = newNode($2, 2, $1, $3); free($2);
    		}
  		| ID {
        	$$ = newLeaf("ID", $1); free($1);
    		}
    		;

rel_op:		EQ  { $$ = strdup("="); }
  		| GT  { $$ = strdup(">"); }
  		| LT  { $$ = strdup("<"); }
  		| GEQ { $$ = strdup(">="); }
  		| LEQ { $$ = strdup("<="); }
  		| NEQ { $$ = strdup("<>"); }
    		;

expression:	expression PLUS term {
        	$$ = newNode("+", 2, $1, $3);
    		}
  		| expression MINUS term {
        	$$ = newNode("-", 2, $1, $3);
    		}
  		| term {
        	$$ = $1;
    		}
    		;

term:		term MUL factor {
     		   $$ = newNode("*", 2, $1, $3);
    		}
  		| term DIV factor {
        	$$ = newNode("/", 2, $1, $3);
    		}
  		| term MOD factor {
        	$$ = newNode("%", 2, $1, $3);
    		}
  		| factor {
        	$$ = $1;
    		}
    		;

factor: 	LPAREN expression RPAREN { $$ = $2; }
  		| ID          { $$ = newLeaf("ID", $1);       free($1); }
  		| INT_CONST   { $$ = newLeaf("INT_CONST", $1); free($1); }
  		| CHAR_CONST  { $$ = newLeaf("CHAR_CONST", $1);free($1); }
  		;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error at line %d: %s\n", yylineno, s);
    exit(1);
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <source-file>\n", argv[0]);
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if (!yyin) { perror("Error opening file"); return 1; }
    if (yyparse() == 0) {
        printf("Parsing successful!\n\n");

        initSymbolTable();
        /* the root we build is newNode("",2,decls,stmts) */
		buildSymbolTable(root->children[0]->children[0]);
        execStmtList(root->children[1]);

        finishInterpretation();  /* prints + frees the symbol table */

        freeAST(root);
    }
    fclose(yyin);
    return 0;
}
