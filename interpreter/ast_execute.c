#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "symtab.h"
#include "ast_execute.h"

static void execStmt(ASTNode *stmt);
static int  evalExpr(ASTNode *expr, VarType *outType);
static int  evalCondition(ASTNode *cond);
void buildSymbolTable(ASTNode *decls) {
    if (!decls) return;
    if (decls->childCount == 2) {
        ASTNode *d = decls->children[0];
        ASTNode *idNode = d->children[0];
        ASTNode *typeNode = d->children[d->childCount-1];
        VarType t = strcmp(typeNode->value,"int")==0
                      ? TYPE_INT : TYPE_CHAR;
        insertSymbol(idNode->value, t);
        buildSymbolTable(decls->children[1]);
    }
}
void execStmtList(ASTNode *stmts) {
    if (!stmts) return;
    if (stmts->childCount == 1 && stmts->label[0] == '\0') {
        execStmtList(stmts->children[0]);
        return;
    }
    if (stmts->childCount == 2) {
        execStmt(stmts->children[0]);
        execStmtList(stmts->children[1]);
    }
}
static void execStmt(ASTNode *stmt) {
    if (strcmp(stmt->label,":=")==0) {
        ASTNode *idNode = stmt->children[0];
        ASTNode *expr   = stmt->children[1];
        VarType exprType;
        int val = evalExpr(expr, &exprType);
        setSymbolValue(idNode->value, exprType, val);
        return;
    }
    if (!strcmp(stmt->label,"+=") ||
        !strcmp(stmt->label,"-=") ||
        !strcmp(stmt->label,"*=") ||
        !strcmp(stmt->label,"/=") ||
        !strcmp(stmt->label,"%=")) {
        ASTNode *idNode = stmt->children[0];
        ASTNode *expr   = stmt->children[1];
        VarType exprType;
        int    val      = evalExpr(expr, &exprType);
        Symbol *s       = lookupSymbol(idNode->value);
        if (!s) {
            fprintf(stderr,"Semantic error: undeclared '%s'\n",
                    idNode->value);
            exit(1);
        }
        if (!s->initialized) {
            fprintf(stderr,
            "Semantic error: '%s' used before initialization\n",
            idNode->value);
            exit(1);
        }
        int old = s->value.i;
        if      (stmt->label[0]=='+') val = old + val;
        else if (stmt->label[0]=='-') val = old - val;
        else if (stmt->label[0]=='*') val = old * val;
        else if ((stmt->label[0]=='/' || stmt->label[0]=='%') && val == 0) {
            fprintf(stderr,"Runtime error: division by zero\n");
            exit(1);
        }
        else if (stmt->label[0]=='/') val = old / val;
        else if (stmt->label[0]=='%') val = old % val;
        setSymbolValue(idNode->value, exprType, val);
        return;
    }
    if (!strcmp(stmt->label, "if")) {
        if (evalCondition(stmt->children[0]))
            execStmtList(stmt->children[1]);
        return;
    }
    if (!strcmp(stmt->label, "ifelse")) {
        if (evalCondition(stmt->children[0]))
            execStmtList(stmt->children[1]);
        else
            execStmtList(stmt->children[2]);
        return;
    }
    if (!strcmp(stmt->label, "while")) {
        while (evalCondition(stmt->children[0]))
            execStmtList(stmt->children[1]);
        return;
    }
    if (!strcmp(stmt->label, "for")) {
        ASTNode *initAssign = stmt->children[0];
        ASTNode *limNode    = stmt->children[1];
        ASTNode *stepNode   = stmt->children[2];
        ASTNode *blockNode  = stmt->children[3];
        execStmt(initAssign);
        VarType tmpType;
        int lim = evalExpr(limNode, &tmpType);
        int step = evalExpr(stepNode->children[0], &tmpType);
        if (!strcmp(stepNode->label, "dec")) step = -step;
        ASTNode *idNode = initAssign->children[0];
        Symbol *s = lookupSymbol(idNode->value);
        if (!s) {
            fprintf(stderr, "Semantic error: undeclared '%s'\n", idNode->value);
            exit(1);
        }
        ASTNode *bodyList = (blockNode->childCount == 1
                             ? blockNode->children[0]
                             : blockNode);
        if (step > 0) {
            while (s->value.i <= lim) {
                execStmtList(bodyList);
                s->value.i += step;
            }
        } else {
            while (s->value.i >= lim) {
                execStmtList(bodyList);
                s->value.i += step;
            }
        }
        return;
    }
    if (!strcmp(stmt->label, "print")) {
        /* strip the quotes and substitute the value for the first '@' */
        ASTNode *strN = stmt->children[0];
        const char *fmt = strN->value;
        size_t len = strlen(fmt);
        if (len >= 2 && fmt[0] == '"' && fmt[len-1] == '"') { fmt++; len -= 2; }
        int hasVal = 0, v = 0; VarType t = TYPE_INT;
        if (stmt->childCount==2) {
            v = evalExpr(stmt->children[1], &t);
            hasVal = 1;
        }
        int used = 0;
        for (size_t i = 0; i < len; i++) {
            if (fmt[i] == '@' && hasVal && !used) {
                if (t == TYPE_CHAR) putchar(v); else printf("%d", v);
                used = 1;
            } else {
                putchar(fmt[i]);
            }
        }
        if (hasVal && !used) {
            if (t == TYPE_CHAR) printf(" %c", v); else printf(" %d", v);
        }
        putchar('\n');
        return;
    }
}
static int evalCondition(ASTNode *cond) {
    if (cond->childCount==1
        && !strcmp(cond->label,"")) {
        Symbol *s = lookupSymbol(cond->children[0]->value);
        if (!s) { fprintf(stderr,"Undeclared '%s'\n",
                            cond->children[0]->value); exit(1);}
        if (!s->initialized) {
            fprintf(stderr,
              "Semantic error: '%s' used before initialization\n",
              cond->children[0]->value);
            exit(1);
        }
        return s->value.i != 0;
    }
    VarType lt, rt;
    int l = evalExpr(cond->children[0], &lt);
    int r = evalExpr(cond->children[1], &rt);
    if (lt!=rt) {
        fprintf(stderr,"Semantic error: type mismatch in condition\n");
        exit(1);
    }
    if      (!strcmp(cond->label,"="))  return l==r;
    else if (!strcmp(cond->label,"<>")) return l!=r;
    else if (!strcmp(cond->label,">"))  return l>r;
    else if (!strcmp(cond->label,">=")) return l>=r;
    else if (!strcmp(cond->label,"<"))  return l<r;
    else if (!strcmp(cond->label,"<=")) return l<=r;
    return 0;
}

static int evalExpr(ASTNode *expr, VarType *outType) {
    if (expr->childCount == 0) {
        if (!strcmp(expr->label,"INT_CONST")) {
            char *buf = strdup(expr->value + 1);
            char *comma = strchr(buf, ',');
            if (!comma) {
                fprintf(stderr, "Bad INT_CONST format: %s\n", expr->value);
                exit(1);
            }
            *comma = '\0';
            char *digits  = buf;
            char *basestr = comma + 1;
            char *rparen = strchr(basestr, ')');
            if (rparen) *rparen = '\0';
            int base = atoi(basestr);
            long v  = strtol(digits, NULL, base);
            free(buf);
            *outType = TYPE_INT;
            return (int)v;
        }
        if (!strcmp(expr->label,"CHAR_CONST")) {
            *outType = TYPE_CHAR;
            return expr->value[1];
        }
        if (!strcmp(expr->label,"ID")) {
            Symbol *s = lookupSymbol(expr->value);
            if (!s) {
                fprintf(stderr,
                   "Semantic error: undeclared '%s'\n", expr->value);
                exit(1);
            }
            if (!s->initialized) {
                fprintf(stderr,
                  "Semantic error: '%s' used before initialization\n",
                  expr->value);
                exit(1);
            }
            *outType = s->type;
            return s->value.i;
        }
    }
    VarType lt, rt;
    int l = evalExpr(expr->children[0], &lt);
    int r = evalExpr(expr->children[1], &rt);
    if (lt!=rt) {
        fprintf(stderr,"Semantic error: type mismatch in expression\n");
        exit(1);
    }
    *outType = lt;
    if      (!strcmp(expr->label,"+")) return l + r;
    else if (!strcmp(expr->label,"-")) return l - r;
    else if (!strcmp(expr->label,"*")) return l * r;
    if ((!strcmp(expr->label,"/") || !strcmp(expr->label,"%")) && r == 0) {
        fprintf(stderr,"Runtime error: division by zero\n");
        exit(1);
    }
    if      (!strcmp(expr->label,"/")) return l / r;
    else if (!strcmp(expr->label,"%")) return l % r;
    return 0;
}
void finishInterpretation(void) {
    printSymbolTable();
    freeSymbolTable();
}