#ifndef SYMTAB_H
#define SYMTAB_H

#include <stdbool.h>

/* our two types */
typedef enum { TYPE_INT, TYPE_CHAR } VarType;

/* one symbol */
typedef struct Symbol {
    char       *name;
    VarType     type;
    bool        initialized;
    union {
        int  i;
        char c;
    } value;
    struct Symbol *next;
} Symbol;

/* the head of our chained-list table */
extern Symbol *symbolTable;

/* initialize (must be called once before any insert/lookup) */
void initSymbolTable(void);

/* insert new symbol; on redeclaration, report and exit */
void insertSymbol(const char *name, VarType type);

/* lookup; returns NULL if not declared */
Symbol *lookupSymbol(const char *name);

/* mark as initialized and store value */
void setSymbolValue(const char *name, VarType type, 
                    int ival /* for char, pass its ASCII */);

/* print all symbols in tabular form */
void printSymbolTable(void);

/* free all symbol-table memory */
void freeSymbolTable(void);

#endif
