#include "ast.h"
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

ASTNode* newLeaf(const char *label, const char *value) {
#ifdef AST_TRACE
    printf("Creating %s node: %s\n", label, value);
#endif
    ASTNode *node = malloc(sizeof(ASTNode));
    if (!node) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(EXIT_FAILURE);
    }
    node->label      = strdup(label);
    node->value      = strdup(value);
    node->childCount = 0;
    node->children   = NULL;
    return node;
}

ASTNode* newNode(const char *label, int childCount, ...) {
#ifdef AST_TRACE
    printf("Creating %s node: %d\n", label, childCount);
#endif
    ASTNode *node = malloc(sizeof(ASTNode));
    if (!node) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(EXIT_FAILURE);
    }
    node->label      = strdup(label);
    node->value      = NULL;
    node->childCount = childCount;
    node->children   = malloc(sizeof(ASTNode*) * childCount);
    va_list ap;
    va_start(ap, childCount);
    for (int i = 0; i < childCount; ++i) {
        node->children[i] = va_arg(ap, ASTNode*);
    }
    va_end(ap);
    return node;
}

void printAST(ASTNode *node) {
    if (!node) return;
    if (node->childCount == 0) {
       
        printf("%s", node->value);
    } else {
    
        printf("(%s", node->label);
        for (int i = 0; i < node->childCount; ++i) {
            printf(" ");
            printAST(node->children[i]);
        }
        printf(")");
    }
}

void freeAST(ASTNode *node) {
    if (!node) return;
    for (int i = 0; i < node->childCount; ++i) {
        freeAST(node->children[i]);
    }
    free(node->children);
    free(node->label);
    free(node->value);
    free(node);
}
