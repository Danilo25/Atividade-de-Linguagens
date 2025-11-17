#include "type_table.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define MAX_TYPES 100

static CustomType type_table[MAX_TYPES];
static int type_count = 0;

void initTypeTable() {
    type_count = 0;
}

void freeTypeTable() {
    for (int i = 0; i < type_count; i++) {
        free(type_table[i].name);
        for (int j = 0; j < type_table[i].field_count; j++) {
            free(type_table[i].fields[j].name);
            free(type_table[i].fields[j].type);
        }
        free(type_table[i].fields);
    }
    type_count = 0;
}

void insertCustomType(const char *name, Field *fields, int field_count) {
    if (type_count >= MAX_TYPES) {
        fprintf(stderr, "Limite de tipos excedido.\n");
        exit(1);
    }

    type_table[type_count].name = strdup(name);
    type_table[type_count].field_count = field_count;
    type_table[type_count].fields = malloc(sizeof(Field) * field_count);

    for (int i = 0; i < field_count; i++) {
        type_table[type_count].fields[i].name = strdup(fields[i].name);
        type_table[type_count].fields[i].type = strdup(fields[i].type);
    }

    type_count++;
}

int isCustomType(const char *name) {
    for (int i = 0; i < type_count; i++) {
        if (strcmp(type_table[i].name, name) == 0)
            return 1;
    }
    return 0;
}

Field* getFieldsOfType(const char *name, int *count) {
    for (int i = 0; i < type_count; i++) {
        if (strcmp(type_table[i].name, name) == 0) {
            *count = type_table[i].field_count;
            return type_table[i].fields;
        }
    }
    *count = 0;
    return NULL;
}