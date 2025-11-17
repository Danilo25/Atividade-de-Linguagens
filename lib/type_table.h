#ifndef TYPE_TABLE_H
#define TYPE_TABLE_H

// Representa um campo dentro de um tipo composto
typedef struct {
    char *name;
    char *type;
} Field;

// Representa um tipo composto definido pelo usuário
typedef struct {
    char *name;     // Ex: "Rational"
    Field *fields;  // Lista de campos
    int field_count;
} CustomType;

void initTypeTable();
void freeTypeTable();

// Inserção de um novo tipo
void insertCustomType(const char *name, Field *fields, int field_count);

// Verificação se um tipo é customizado
int isCustomType(const char *name);

// Retorna os campos do tipo (caso necessário no futuro)
Field* getFieldsOfType(const char *name, int *count);

#endif