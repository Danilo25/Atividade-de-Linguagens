#ifndef TYPE_TABLE_H
#define TYPE_TABLE_H

typedef struct {
    char *name;
    char *type;
} Field;
typedef struct {
    char *name;
    Field *fields;
    int field_count;
} CustomType;

void initTypeTable();
void freeTypeTable();
void insertCustomType(const char *name, Field *fields, int field_count);
int isCustomType(const char *name);
Field* getFieldsOfType(const char *name, int *count);

#endif