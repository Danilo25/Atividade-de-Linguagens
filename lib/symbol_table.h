// symbol_table.h
#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

void initSymbolTable(void);
void insertSymbol(const char *name, const char *type);
const char *lookupSymbol(const char *name);
int symbolExists(const char *name);
int symbolAlreadyDeclared(const char *name);
void freeSymbolTable(void);

// Funções para gerenciamento de escopo
void pushScope(void);
void popScope(void);
int symbolExistsInCurrentScope(const char *name);
void checkUndeclaredVariable(const char *name);
void checkDuplicateVariable(const char *name);
int getCurrentScope(void);

#endif