#ifndef AST_EXECUTE_H
#define AST_EXECUTE_H

#include "ast.h"

/* build symbol-table from the declarations subtree */
void buildSymbolTable(ASTNode *decls);

/* walk the statement-list subtree, simulate and print output */
void execStmtList(ASTNode *stmts);

/* clean up, then print the symbol table at the end */
void finishInterpretation(void);

#endif
