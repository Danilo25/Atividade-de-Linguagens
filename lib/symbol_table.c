#include "symbol_table.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "parser.tab.h"

extern int yylineno;

typedef struct Sym {
    char *name;
    char *type;
    int scope_level;
    struct Sym *next;
} Sym;

static Sym *symbols = NULL;
static int current_scope = 0;

void initSymbolTable(void) {
    symbols = NULL;
    current_scope = 0;
}

void pushScope(void) {
    current_scope++;
}

void popScope(void) {
    Sym **current = &symbols;
    while (*current) {
        if ((*current)->scope_level == current_scope) {
            Sym *to_remove = *current;
            *current = (*current)->next;
            free(to_remove->name);
            free(to_remove->type);
            free(to_remove);
        } else {
            current = &((*current)->next);
        }
    }
    current_scope--;
}

void insertSymbol(const char *name, const char *type) {
    Sym *s = malloc(sizeof *s);
    s->name = strdup(name);
    s->type = strdup(type);
    s->scope_level = current_scope;
    s->next = symbols;
    symbols = s;
}

const char *lookupSymbol(const char *name) {
    Sym *best_match = NULL;
    for (Sym *s = symbols; s; s = s->next) {
        if (strcmp(s->name, name) == 0) {
            if (s->scope_level <= current_scope) {
                if (best_match == NULL || s->scope_level > best_match->scope_level) {
                    best_match = s;
                }
            }
        }
    }

    if (best_match != NULL) {
        return best_match->type;
    }
    return NULL;
}

int symbolExists(const char *name) {
    Sym *best_match = NULL;
    for (Sym *s = symbols; s; s = s->next) {
        if (strcmp(s->name, name) == 0) {
            if (s->scope_level <= current_scope) {
                if (best_match == NULL || s->scope_level > best_match->scope_level) {
                    best_match = s;
                }
            }
        }
    }
    return (best_match != NULL);
}

int symbolExistsInCurrentScope(const char *name) {
    for (Sym *s = symbols; s; s = s->next) {
        if (strcmp(s->name, name) == 0 && s->scope_level == current_scope) {
            return 1;
        }
    }
    return 0;
}

int symbolAlreadyDeclared(const char *name) {
    return symbolExistsInCurrentScope(name);
}

void checkUndeclaredVariable(const char *name) {
    if (!symbolExists(name)) {
        fprintf(stderr, "ERRO SEMÂNTICO: variável '%s' não declarada (linha %d)\n", name, yylineno);
        exit(1);
    }
}

void checkDuplicateVariable(const char *name) {
    if (symbolExistsInCurrentScope(name)) {
        fprintf(stderr, "ERRO SEMÂNTICO: variável '%s' já declarada no escopo atual (linha %d)\n", name, yylineno);
        exit(1);
    }
}

int getCurrentScope(void) {
    return current_scope;
}

void freeSymbolTable(void) {
    while (symbols) {
        Sym *next = symbols->next;
        free(symbols->name);
        free(symbols->type);
        free(symbols);
        symbols = next;
    }
}