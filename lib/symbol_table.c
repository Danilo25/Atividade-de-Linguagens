// symbol_table.c
#include "symbol_table.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// Uma lista simples de pares nome→tipo com suporte a escopo
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
    // Remove todas as variáveis do escopo atual
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
    for (Sym *s = symbols; s; s = s->next) {
        if (strcmp(s->name, name) == 0) {
            return s->type;
        }
    }
    return NULL; // Variável não encontrada
}

// Função para verificar se um símbolo existe
int symbolExists(const char *name) {
    for (Sym *s = symbols; s; s = s->next) {
        if (strcmp(s->name, name) == 0) {
            return 1;
        }
    }
    return 0;
}

// Função para verificar se um símbolo existe no escopo atual
int symbolExistsInCurrentScope(const char *name) {
    for (Sym *s = symbols; s; s = s->next) {
        if (strcmp(s->name, name) == 0 && s->scope_level == current_scope) {
            return 1;
        }
    }
    return 0;
}

// Função para verificar se um símbolo já foi declarado no escopo atual
int symbolAlreadyDeclared(const char *name) {
    return symbolExistsInCurrentScope(name);
}

// Função para verificar variável não declarada
void checkUndeclaredVariable(const char *name) {
    if (!symbolExists(name)) {
        fprintf(stderr, "ERRO SEMÂNTICO: variável '%s' não declarada\n", name);
        exit(1);
    }
}

// Função para verificar variável duplicada no mesmo escopo
void checkDuplicateVariable(const char *name) {
    if (symbolExistsInCurrentScope(name)) {
        fprintf(stderr, "ERRO SEMÂNTICO: variável '%s' já declarada no escopo atual\n", name);
        exit(1);
    }
}

// Função para obter o escopo atual
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