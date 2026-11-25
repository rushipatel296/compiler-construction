#ifndef AST_H
#define AST_H

typedef struct ASTNode {
    char           *label;      
    char           *value;      
    struct ASTNode **children;  
    int             childCount; 
} ASTNode;


ASTNode* newLeaf(const char *label, const char *value);


ASTNode* newNode(const char *label, int childCount, ...);


void printAST(ASTNode *node);


void freeAST(ASTNode *node);

#endif
