#include "symtab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

Symbol *symbolTable = NULL;

void initSymbolTable(void) {
    symbolTable = NULL;
}

static void fatal(const char *msg) {
    fprintf(stderr, "Semantic error: %s\n", msg);
    exit(1);
}

void insertSymbol(const char *name, VarType type) {
    if (lookupSymbol(name) != NULL) {
        char buf[256];
        snprintf(buf, sizeof(buf), "redeclaration of '%s'", name);
        fatal(buf);
    }
    Symbol *sym = malloc(sizeof *sym);
    if (!sym) { perror("malloc"); exit(1); }
    sym->name        = strdup(name);
    sym->type        = type;
    sym->initialized = false;
    sym->next        = symbolTable;
    symbolTable      = sym;
}

Symbol *lookupSymbol(const char *name) {
    for (Symbol *s = symbolTable; s; s = s->next)
        if (strcmp(s->name,name)==0) return s;
    return NULL;
}

void setSymbolValue(const char *name, VarType type, int ival) {
    Symbol *s = lookupSymbol(name);
    if (!s) {
        char buf[256];
        snprintf(buf, sizeof(buf), "use of undeclared variable '%s'", name);
        fatal(buf);
    }
    if (s->type != type) {
        char buf[256];
        snprintf(buf, sizeof(buf),
                 "type mismatch assigning to '%s' (expected %s)",
                 name,
                 s->type==TYPE_INT ? "int" : "char");
        fatal(buf);
    }
    s->value.i        = ival;
    s->initialized    = true;
}

void printSymbolTable(void) {
    printf("\n=== Symbol Table ===\n");
    printf("%-10s | %-5s | %-11s | %s\n", 
           "Name", "Type", "Initialized", "Value");
    printf("--------------------------------\n");
    for (Symbol *s = symbolTable; s; s = s->next) {
        printf("%-10s | %-5s | %-11s | ",
               s->name,
               s->type==TYPE_INT ? "int" : "char",
               s->initialized ? "yes" : "no");
        if (s->initialized) {
            if (s->type == TYPE_INT)      printf("%d\n", s->value.i);
            else /* char */               printf("'%c'\n", (char)s->value.i);
        } else {
            printf("—\n");
        }
    }
    printf("====================\n");
}

void freeSymbolTable(void) {
    Symbol *s = symbolTable;
    while (s) {
        Symbol *next = s->next;
        free(s->name);
        free(s);
        s = next;
    }
    symbolTable = NULL;
}
