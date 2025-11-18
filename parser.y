%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "./lib/record.h"
#include "./lib/symbol_table.h"

int yylex(void);
void yyerror(const char *s);
char* cat(const char *s1, const char *s2, const char *s3, const char *s4, const char *s5);
const char* map_type(const char* o);

extern int yylineno;
extern char *yytext;
extern FILE *yyin, *yyout;

static int label_count = 0;
static char* current_struct_name = NULL;
static char* current_function_return_type = NULL;

/* STRUCTS PARA PASSAR DADOS DE REGRAS COMPLEXAS */
struct FuncHeader {
    struct record* type_rec;
    char* name;
    struct record* param_rec;
};

struct ForHeader {
    struct record* init_rec;
    struct record* cond_rec;
    struct record* incr_rec;
};

char *new_label() {
    char buf[32];
    sprintf(buf, "L%d", label_count++);
    return strdup(buf);
}

char* deref_if_needed(struct record* rec) {
    if (rec && rec->opt1 && strncmp(rec->opt1, "ref", 3) == 0) {
        return cat("*", rec->code, "", "", "");
    }
    return strdup(rec->code);
}

/* FUNÇÕES DE VERIFICAÇÃO DE TIPO */

void type_error(const char* op, const char* t1, const char* t2) {
    fprintf(stderr, "ERRO SEMÂNTICO (linha %d): Operação '%s' inválida entre os tipos '%s' e '%s'\n",
            yylineno, op, t1, t2);
    exit(1);
}

int is_numeric(const char* type) {
    if (type == NULL) return 0;
    return (strcmp(type, "Int") == 0 || strcmp(type, "Float") == 0);
}

int is_string(const char* type) {
    if (type == NULL) return 0;
    return (strcmp(type, "String") == 0);
}

int is_bool(const char* type) {
    if (type == NULL) return 0;
    return (strcmp(type, "Int") == 0 || strcmp(type, "Bool") == 0);
}

void check_assignment_types(const char* var_type, const char* val_type) {
    if (var_type == NULL || val_type == NULL) return;
    
    if (strcmp(var_type, val_type) == 0) return;
    if (strcmp(var_type, "Float") == 0 && strcmp(val_type, "Int") == 0) return;
    if (strcmp(var_type, "Bool") == 0 && strcmp(val_type, "Int") == 0) return;
    if (strcmp(var_type, "Int") == 0 && strcmp(val_type, "Bool") == 0) return;

    /* Permite atribuição de ponteiros (ex: Lista<Int> = ...malloc...) */
    if (strstr(var_type, "Lista<") && strcmp(val_type, "Pointer") == 0) return;
    if (strstr(var_type, "Matriz<") && strcmp(val_type, "Pointer") == 0) return;

    fprintf(stderr, "ERRO SEMÂNTICO (linha %d): Impossível atribuir tipo '%s' a uma variável do tipo '%s'\n",
            yylineno, val_type, var_type);
    exit(1);
}

const char* get_result_type(const char* t1, const char* t2) {
    if (strcmp(t1, "Float") == 0 || strcmp(t2, "Float") == 0) {
        return "Float";
    }
    return "Int";
}

/* === FUNÇÕES AUXILIARES PARA LISTAS/MATRIZES === */

/* Descasca o tipo para permitir acesso indexado */
char* get_inner_type(const char* complex_type) {
    if (complex_type == NULL) return strdup("void");

    /* Se for Matriz, vira Lista */
    if (strncmp(complex_type, "Matriz<", 7) == 0) {
        int len = strlen(complex_type);
        char* new_type = malloc(len); 
        sprintf(new_type, "Lista<%s", complex_type + 7); 
        return new_type;
    }

    /* Se for Lista, vira o tipo base */
    if (strncmp(complex_type, "Lista<", 6) == 0) {
        const char *start = strchr(complex_type, '<');
        const char *end = strrchr(complex_type, '>');
        if (start && end) {
            int len = end - (start + 1);
            char *base_type = malloc(len + 1);
            strncpy(base_type, start + 1, len);
            base_type[len] = '\0';
            return base_type;
        }
    }

    return strdup(complex_type); 
}

/* Extrai o tipo base C puro para o malloc */
const char* get_c_base_type(const char* complex_type) {
    const char *start = strchr(complex_type, '<');
    const char *end = strrchr(complex_type, '>');
    
    if (start && end) {
        int len = end - (start + 1);
        char *base_string = malloc(len + 1);
        strncpy(base_string, start + 1, len);
        base_string[len] = '\0';
        
        const char* c_type = map_type(base_string);
        free(base_string);
        return c_type;
    }
    return "void";
}

%}

%union {
    int int_val;
    double float_val;
    char *str_val;
    struct record *rec;
    struct FuncHeader* func_header;
    struct ForHeader* for_header;
}

%token <str_val> ID
%token <int_val> INT_LIT
%token <float_val> FLOAT_LIT
%token <str_val> STRING_LIT

%token IF ENDIF ELSE FOR ENDFOR SWITCH ENDSWITCH WHILE ENDWHILE
%token RETURN PRINTF SCANF CONST BREAK CONTINUE CASE DEFAULTCASE TRY CATCH FINALLY
%token DO UNTIL FUNCTION ENDFUNCTION STRUCT ENDSTRUCT ENUM
%token REF NEW NULO
%token TYPE_INT TYPE_FLOAT TYPE_STRING TYPE_BOOL TYPE_LIST
%token TYPE_MATRIZ 

%token ASSIGN EQ NE LE GE LT GT
%token AND OR NOT
%token PLUS_ASSIGN MINUS_ASSIGN MUL_ASSIGN DIV_ASSIGN
%token PLUS MINUS MUL DIV PLUSPLUS MINUSMINUS
%token SEMICOLON COLON COMMA LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET DOT

%type <rec> program declaration_list function_definition struct_definition
%type <rec> optional_statement_list statement_list_non_empty
%type <rec> statement declaration_statement
%type <rec> expression_statement if_statement while_statement for_statement return_statement
%type <rec> print_statement scan_statement
%type <rec> type simple_type
%type <rec> expression list_literal lvalue 
%type <rec> parameter_list param_list_non_empty parameter
%type <rec> argument_list expression_list
%type <rec> brace_block
%type <rec> do_statement switch_statement
%type <rec> for_init
%type <rec> case_item case_list default_case

%type <func_header> func_header_push
%type <for_header> for_header_part
%type <rec> for_header_scope
%type <rec> rparen_push
%type <rec> do_push
%type <rec> colon_push
%type <rec> lbrace_push

%right ASSIGN PLUS_ASSIGN MINUS_ASSIGN MUL_ASSIGN DIV_ASSIGN
%left OR
%left AND
%left EQ NE
%left LT LE GT GE
%left PLUS MINUS
%left MUL DIV
%right NOT PLUSPLUS MINUSMINUS
%left DOT LPAREN RPAREN LBRACKET RBRACKET

%%

program:
    declaration_list {
        fprintf(yyout,
            "#include <stdio.h>\n"
            "#include <stdlib.h>\n" 
            "#include <string.h>\n\n"
            /* Função auxiliar para alocar matrizes em C */
            "void** alloc_matrix(int r, int c, size_t size) {\n"
            "    void** m = malloc(r * sizeof(void*));\n"
            "    for(int i=0; i<r; i++) m[i] = malloc(c * size);\n"
            "    return m;\n"
            "}\n\n"
        );
        fprintf(yyout, "%s\n", $1->code);
        freeRecord($1);
    }
    ;

declaration_list:
      { $$ = createRecord("", ""); }
    | declaration_list function_definition {
        char *s = cat($1->code, "\n", $2->code, "", "");
        $$ = createRecord(s, ""); free(s);
        freeRecord($1); freeRecord($2);
    }
    | declaration_list struct_definition {
        $$ = $1;
    }
    ;

struct_definition:
    STRUCT ID
        member_list
    ENDSTRUCT { $$ = createRecord("", ""); }
    ;

member_list:
    | member_list member
    ;

member:
    type ID SEMICOLON
    ;

/* === CORREÇÃO CRÍTICA 1: Escopo de Função === */
/* Abre o escopo ANTES de processar a parameter_list */
func_header_push:
    FUNCTION type ID {
        /* 1. Insere o nome da função no escopo GLOBAL */
        checkDuplicateVariable($3);
        insertSymbol($3, $2->opt1);
    } LPAREN { 
        /* 2. Cria o NOVO escopo para os parâmetros */
        pushScope(); 
    } parameter_list RPAREN { 
        current_function_return_type = strdup($2->opt1);
        
        $$ = malloc(sizeof(struct FuncHeader));
        $$->type_rec = $2;
        $$->name = $3;
        $$->param_rec = $7; /* ATENÇÃO: type(2), ID(3), Action(4), LPAREN(5), Action(6), Params(7) */
    }
    ;

rparen_push:
    RPAREN { pushScope(); $$ = createRecord("", ""); }
    ;

do_push:
    DO { pushScope(); $$ = createRecord("", ""); }
    ;

/* === CORREÇÃO CRÍTICA 2: Escopo de Loop (Para) === */
/* Abre o escopo ANTES da inicialização */
for_header_scope:
    FOR LPAREN { pushScope(); $$ = createRecord("", ""); }
    ;

for_header_part:
    for_header_scope for_init SEMICOLON expression SEMICOLON expression RPAREN { 
        /* O escopo já foi aberto em for_header_scope */
        
        $$ = malloc(sizeof(struct ForHeader));
        $$->init_rec = $2;
        $$->cond_rec = $4;
        $$->incr_rec = $6;
    }
    ;

colon_push:
    COLON { pushScope(); $$ = createRecord("", ""); }
    ;

lbrace_push:
    LBRACE { pushScope(); $$ = createRecord("", ""); }
    ;


function_definition:
    func_header_push optional_statement_list ENDFUNCTION {
        const char *func_name = $1->name;
        const char *rt = $1->type_rec->code;
        
        if (strcmp($1->name, "Main") == 0) {
            func_name = "main";
            rt = "int";
        }
        
        char *h = cat(rt, " ", func_name, "(", $1->param_rec->code);
        char *b = cat(h, ") {\n", $2->code, "}\n", "");
        $$ = createRecord(b, ""); free(h); free(b);
        
        freeRecord($1->type_rec);
        free($1->name);
        freeRecord($1->param_rec);
        free($1);
        freeRecord($2);
        
        free(current_function_return_type);
        current_function_return_type = NULL;
        popScope();
    }
    ;

parameter_list:
      { $$ = createRecord("", ""); }
    | param_list_non_empty
    ;

param_list_non_empty:
    parameter { $$ = $1; }
    | param_list_non_empty COMMA parameter {
        char *s = cat($1->code, ", ", $3->code, "", "");
        $$ = createRecord(s, ""); free(s);
        freeRecord($1); freeRecord($3);
    }
    ;

parameter:
    type ID {
        checkDuplicateVariable($2);
        char *s = cat($1->code, " ", $2, "", "");
        $$ = createRecord(s, $1->opt1);
        insertSymbol($2, $1->opt1);
        free(s); freeRecord($1); free($2);
    }
    ;

type:
    simple_type { $$ = $1; }
    | TYPE_LIST LT simple_type GT {
        char* c_type = cat($3->code, "*", "", "", ""); 
        char* internal_type = cat("Lista<", $3->opt1, ">", "", "");
        $$ = createRecord(c_type, internal_type);
        free(c_type); free(internal_type);
        freeRecord($3);
    }
    | TYPE_MATRIZ LT simple_type GT {
        char* c_type = cat($3->code, "**", "", "", ""); 
        char* internal_type = cat("Matriz<", $3->opt1, ">", "", "");
        $$ = createRecord(c_type, internal_type);
        free(c_type); free(internal_type);
        freeRecord($3);
    }
    | REF simple_type {
        char* s = cat($2->code, "*", "", "", "");
        char* t = cat("ref", $2->opt1, "", "", "");
        $$ = createRecord(s, t); free(s); free(t);
        freeRecord($2);
    }
    ;

simple_type:
    TYPE_INT    { $$ = createRecord("int", "Int"); }
    | TYPE_FLOAT  { $$ = createRecord("double", "Float"); }
    | TYPE_STRING { $$ = createRecord("char*", "String"); }
    | TYPE_BOOL   { $$ = createRecord("int", "Bool"); }
    | ID          { $$ = createRecord($1, $1); free($1); }
    ;

brace_block:
    lbrace_push optional_statement_list RBRACE { 
        popScope(); 
        $$ = $2; 
        freeRecord($1);
    }
    ;

optional_statement_list:
      { $$ = createRecord("", ""); }
    | statement_list_non_empty  { $$ = $1; }
    ;

statement_list_non_empty:
      statement { $$ = $1; }
    | statement_list_non_empty statement {
        if ($2 == NULL) { $$ = $1; }
        else {
            char *s = cat($1->code, $2->code, "\n", "", "");
            $$ = createRecord(s, ""); free(s);
            freeRecord($1); freeRecord($2);
        }
    }
    ;


statement:
    expression_statement    { $$ = $1; }
    | declaration_statement   { $$ = $1; }
    | do_statement            { $$ = $1; }
    | if_statement            { $$ = $1; }
    | switch_statement        { $$ = $1; }
    | while_statement         { $$ = $1; }
    | for_statement           { $$ = $1; }
    | return_statement        { $$ = $1; }
    | print_statement         { $$ = $1; }
    | scan_statement          { $$ = $1; }
    | brace_block             { $$ = $1; }
    | SEMICOLON               { $$ = createRecord("", ""); }
    ;

declaration_statement:
    type ID SEMICOLON {
        checkDuplicateVariable($2);
        char *s_p = cat("    ", $1->code, " ", $2, ";");
        char *s = cat(s_p, "", "", "", "");
        $$ = createRecord(s, ""); free(s_p); free(s);
        insertSymbol($2, $1->opt1);
        freeRecord($1); free($2);
    }
    | type ID ASSIGN expression SEMICOLON {
        checkDuplicateVariable($2);
        check_assignment_types($1->opt1, $4->opt1);
        char *s_p1 = cat("    ", $1->code, " ", $2, " = ");
        char *s_p2 = cat($4->code, ";", "", "", "");
        char *s = cat(s_p1, s_p2, "", "", "");
        $$ = createRecord(s, ""); free(s_p1); free(s_p2); free(s);
        insertSymbol($2, $1->opt1);
        freeRecord($1); free($2); freeRecord($4);
    }
    ;

expression_statement:
    expression SEMICOLON {
        char *s = cat("    ", $1->code, ";", "", "");
        $$ = createRecord(s, ""); free(s);
        freeRecord($1);
    }
    ;

scan_statement:
    SCANF LPAREN expression RPAREN SEMICOLON {
        char *format_spec = "";
        if (strcmp($3->opt1, "Int") == 0) format_spec = "%d";
        else if (strcmp($3->opt1, "Float") == 0) format_spec = "%lf";
        else if (strcmp($3->opt1, "String") == 0) format_spec = "%s";

        char *s = cat("    scanf(\"", format_spec, "\", &", $3->code, ");");
        $$ = createRecord(s, ""); free(s);
        freeRecord($3);
    }
    ;

do_statement:
    do_push optional_statement_list UNTIL LPAREN expression RPAREN SEMICOLON { 
        popScope();
        char *l_begin = new_label();
        char *label_begin = cat(l_begin, ":", "", "", "");
        char *c_p = cat("    if (!(", $5->code, ")) goto ", l_begin, ";");
        char *cond = cat(c_p, "", "", "", "");
        char *s1 = cat("    ", label_begin, "\n", $2->code, "\n");
        char *code = cat(s1, cond, "\n", "", "");
        $$ = createRecord(code, "");
        free(l_begin); free(label_begin); free(c_p); free(cond); free(s1); free(code);
        freeRecord($1); freeRecord($2); freeRecord($5);
    }
    ;

if_statement:
    IF LPAREN expression rparen_push optional_statement_list { popScope(); } ENDIF {
        char *lend = new_label();
        char *c_p = cat("    if (!(", $3->code, ")) goto ", lend, ";");
        char *cond = cat(c_p, "", "", "", "");
        char *body = $5->code;
        char *label = cat(lend, ":", "", "", "");
        char *s1 = cat(cond, "\n", body, "\n    ", label);
        char *code = cat(s1, "\n", "", "", "");
        $$ = createRecord(code, "");
        free(lend); free(c_p); free(cond); free(label); free(s1); free(code);
        freeRecord($3); freeRecord($4); freeRecord($5);
    }
    | IF LPAREN expression rparen_push optional_statement_list { popScope(); } ELSE { pushScope(); } optional_statement_list { popScope(); } ENDIF {
        char *l_else = new_label();
        char *l_end = new_label();
        char *c_p = cat("    if (!(", $3->code, ")) goto ", l_else, ";");
        char *cond = cat(c_p, "", "", "", "");
        char *body_if = $5->code;
        char *goto_end = cat("    goto ", l_end, ";", "", "");
        char *label_else = cat(l_else, ":", "", "", "");
        char *body_else = $9->code;
        char *label_end = cat(l_end, ":", "", "", "");

        char *s1 = cat(cond, "\n", body_if, "\n", goto_end);
        char *s2_p = cat("\n", "    ", label_else, "\n", body_else);
        char *s2 = cat(s2_p, "\n    ", label_end, "\n", "");
        char *code = cat(s1, s2, "", "", "");
        
        $$ = createRecord(code, "");
        free(l_else); free(l_end); free(c_p); free(cond); free(goto_end); free(label_else);
        free(label_end); free(s1); free(s2_p); free(s2); free(code);
        freeRecord($3); freeRecord($4); freeRecord($5); freeRecord($9);
    }
    ;

case_item:
    CASE expression colon_push optional_statement_list { popScope(); } {
        char* s_p = cat("    case ", $2->code, ":\n", $4->code, "\n      break;\n");
        char* s = cat(s_p, "", "", "", "");
        $$ = createRecord(s, ""); free(s_p); free(s);
        freeRecord($2); freeRecord($3); freeRecord($4);
    }
    ;

default_case:
    DEFAULTCASE colon_push optional_statement_list { popScope(); } {
        char* s = cat("    default:\n", $3->code, "\n      break;\n", "", "");
        $$ = createRecord(s, ""); free(s);
        freeRecord($2); freeRecord($3);
    }
    ;

case_list:
    case_item { $$ = $1; }
    | case_list case_item {
        char* s = cat($1->code, $2->code, "", "", "");
        $$ = createRecord(s, ""); free(s);
        freeRecord($1); freeRecord($2);
    }
    ;

switch_statement:
    SWITCH LPAREN expression RPAREN case_list ENDSWITCH {
        char* s1 = cat("    switch(", $3->code, ") {\n", $5->code, "");
        char* code = cat(s1, "    }\n", "", "", "");
        $$ = createRecord(code, ""); free(s1); free(code);
        freeRecord($3); freeRecord($5);
    }
    | SWITCH LPAREN expression RPAREN case_list default_case ENDSWITCH {
        char* s1 = cat("    switch(", $3->code, ") {\n", $5->code, $6->code);
        char* code = cat(s1, "    }\n", "", "", "");
        $$ = createRecord(code, ""); free(s1); free(code);
        freeRecord($3); freeRecord($5); freeRecord($6);
    }
    ;

while_statement:
    WHILE LPAREN expression rparen_push optional_statement_list { popScope(); } ENDWHILE {
        char *l_begin = new_label();
        char *l_end = new_label();
        char *label_begin = cat(l_begin, ":", "", "", "");
        char *c_p = cat("    if (!(", $3->code, ")) goto ", l_end, ";");
        char *cond = cat(c_p, "", "", "", "");
        char *body = $5->code;
        char *goto_begin = cat("    goto ", l_begin, ";", "", "");
        char *label_end = cat(l_end, ":", "", "", "");

        char *s1 = cat("    ", label_begin, "\n", cond, "\n");
        char *s2 = cat(body, "\n", "    ", goto_begin, "\n");
        char *s3 = cat("    ", label_end, "\n", "", "");
        char *code_p = cat(s1, s2, s3, "", "");
        char *code = cat(code_p, "", "", "", "");

        $$ = createRecord(code, "");
        free(l_begin); free(l_end); free(label_begin); free(c_p); free(cond);
        free(goto_begin); free(label_end); free(s1); free(s2); free(s3); free(code_p); free(code);
        freeRecord($3); freeRecord($4); freeRecord($5);
    }
    ;

for_statement:
    for_header_part optional_statement_list { popScope(); } ENDFOR {
        char *l_begin = new_label();
        char *l_end = new_label();
        char *label_begin = cat(l_begin, ":", "", "", "");
        char *c_p = cat("    if (!(", $1->cond_rec->code, ")) goto ", l_end, ";");
        char *cond = cat(c_p, "", "", "", "");
        char *body = $2->code;
        char *increment = cat("    ", $1->incr_rec->code, ";", "", "");
        char *goto_begin = cat("    goto ", l_begin, ";", "", "");
        char *label_end = cat(l_end, ":", "", "", "");

        char *s1 = cat("    ", $1->init_rec->code, ";\n", "    ", label_begin);
        char *s2 = cat("\n", cond, "\n", body, "\n");
        char *s3 = cat(increment, "\n", goto_begin, "\n", "    ");
        char *s4 = cat(label_end, "\n", "", "", "");
        
        /* --- ENVOLVER EM CHAVES {} NO C GERADO --- */
        char *code_p1 = cat(s1, s2, "", "", "");
        char *code_p2 = cat(s3, s4, "", "", "");
        char *inner = cat(code_p1, code_p2, "", "", "");
        char *code = cat("{\n", inner, "}\n", "", "");


        $$ = createRecord(code, "");
        free(l_begin); free(l_end); free(label_begin); free(c_p); free(cond);
        free(increment); free(goto_begin); free(label_end);
        free(s1); free(s2); free(s3); free(s4); free(code_p1); free(code_p2); free(inner);
        
        freeRecord($1->init_rec);
        freeRecord($1->cond_rec);
        freeRecord($1->incr_rec);
        free($1);
        freeRecord($2);
    }
    ;

for_init:
    type ID ASSIGN expression {
        checkDuplicateVariable($2);
        check_assignment_types($1->opt1, $4->opt1);
        char* s = cat($1->code, " ", $2, " = ", $4->code);
        $$ = createRecord(s, ""); free(s);
        insertSymbol($2, $1->opt1);
        freeRecord($1); free($2); freeRecord($4);
    }
    | expression { $$ = $1; }
    ;

return_statement:
    RETURN expression SEMICOLON {
        if (current_function_return_type == NULL) {
            fprintf(stderr, "ERRO SEMÂNTICO (linha %d): 'retorne' fora de uma função.\n", yylineno);
            exit(1);
        }
        check_assignment_types(current_function_return_type, $2->opt1);
        
        char *s = cat("    return ", $2->code, ";", "", "");
        $$ = createRecord(s, ""); free(s);
        freeRecord($2);
    }
    ;

print_statement:
    PRINTF LPAREN expression RPAREN SEMICOLON {
        char* format_spec = "";
        char* code_to_print = $3->code;
        char* type = $3->opt1;
        char* s;

        if (strncmp(type, "Int|", 4) == 0) {
            format_spec = "%d\\n";
            char* var_code = strchr(type, '|') + 1;
            s = cat("    printf(\"", code_to_print, " ", format_spec, "\", ");
            char* s_final = cat(s, var_code, ");", "", "");
            free(s); s = s_final;
        } else if (strncmp(type, "Float|", 6) == 0) {
            format_spec = "%lf\\n";
            char* var_code = strchr(type, '|') + 1;
            s = cat("    printf(\"", code_to_print, " ", format_spec, "\", ");
            char* s_final = cat(s, var_code, ");", "", "");
            free(s); s = s_final;
        } else if (strncmp(type, "Bool|", 5) == 0) {
            format_spec = "%d\\n";
            char* var_code = strchr(type, '|') + 1;
            s = cat("    printf(\"", code_to_print, " ", format_spec, "\", ");
            char* s_final = cat(s, var_code, ");", "", "");
            free(s); s = s_final;
        } else if (strncmp(type, "String|", 7) == 0) {
            format_spec = "%s\\n";
            char* var_code = strchr(type, '|') + 1;
            s = cat("    printf(\"", code_to_print, " ", format_spec, "\", ");
            char* s_final = cat(s, var_code, ");", "", "");
            free(s); s = s_final;
        } else {
            if (strcmp(type, "String") == 0) {
                char* quoted_string = cat("\"", code_to_print, "\"", "", "");
                s = cat("    printf(\"%s\\n\", ", quoted_string, ");", "", "");
                free(quoted_string);
            } else if (strcmp(type, "Int") == 0) {
                s = cat("    printf(\"%d\\n\", ", code_to_print, ");", "", "");
            } else if (strcmp(type, "Float") == 0) {
                s = cat("    printf(\"%lf\\n\", ", code_to_print, ");", "", "");
            } else if (strcmp(type, "Bool") == 0) {
                s = cat("    printf(\"%d\\n\", ", code_to_print, ");", "", "");
            } else {
                s = cat("    printf(\"TIPO DESCONHECIDO\\n\");", "", "", "", "");
            }
        }
        
        $$ = createRecord(s, ""); free(s);
        freeRecord($3);
    }
;

lvalue:
    ID {
        checkUndeclaredVariable($1);
        const char *type = lookupSymbol($1);
        $$ = createRecord($1, strdup(type ? type : ""));
    }
    | lvalue LBRACKET expression RBRACKET {
        char* s = cat($1->code, "[", $3->code, "]", "");
        char* base_type = get_inner_type($1->opt1);
        
        $$ = createRecord(s, base_type);
        free(s); free(base_type);
        freeRecord($1); freeRecord($3);
    }
    ;

expression:
    INT_LIT {
        char b[32]; sprintf(b, "%d", $1);
        $$ = createRecord(strdup(b), "Int");
    }
    | FLOAT_LIT {
        char b[32]; sprintf(b, "%f", $1);
        $$ = createRecord(strdup(b), "Float");
    }
    | STRING_LIT {
        $$ = createRecord(strdup($1), "String");
        free($1);
    }
    | lvalue { $$ = $1; }
    | expression PLUS expression {
        const char* t1 = $1->opt1;
        const char* t2 = $3->opt1;
        
        if (is_string(t1)) {
            char* type_plus_code = cat(t2, "|", $3->code, "", "");
            $$ = createRecord(strdup($1->code), type_plus_code);
            free(type_plus_code);
            freeRecord($1); freeRecord($3);
        } 
        else if (is_numeric(t1) && is_numeric(t2)) {
            const char *res_type = get_result_type(t1, t2);
            char *s = cat("(", $1->code, " + ", $3->code, ")");
            $$ = createRecord(s, strdup(res_type));
            free(s); freeRecord($1); freeRecord($3);
        } 
        else {
            type_error("+", t1, t2);
            YYABORT;
        }
    }
    | expression MINUS expression {
        if (!is_numeric($1->opt1) || !is_numeric($3->opt1)) { type_error("-", $1->opt1, $3->opt1); YYABORT; }
        const char *res_type = get_result_type($1->opt1, $3->opt1);
        char *s = cat("(", $1->code, " - ", $3->code, ")");
        $$ = createRecord(s, strdup(res_type));
        free(s); freeRecord($1); freeRecord($3);
    }
    | expression MUL expression {
        if (!is_numeric($1->opt1) || !is_numeric($3->opt1)) { type_error("*", $1->opt1, $3->opt1); YYABORT; }
        const char *res_type = get_result_type($1->opt1, $3->opt1);
        char *s = cat("(", $1->code, " * ", $3->code, ")");
        $$ = createRecord(s, strdup(res_type));
        free(s); freeRecord($1); freeRecord($3);
    }
    | expression DIV expression {
        if (!is_numeric($1->opt1) || !is_numeric($3->opt1)) { type_error("/", $1->opt1, $3->opt1); YYABORT; }
        char *s = cat("(", $1->code, " / ", $3->code, ")");
        $$ = createRecord(s, "Float");
        free(s); freeRecord($1); freeRecord($3);
    }
    | expression LT expression {
        if (!is_numeric($1->opt1) || !is_numeric($3->opt1)) { type_error("<", $1->opt1, $3->opt1); YYABORT; }
        char *s = cat("(", $1->code, " < ", $3->code, ")");
        $$ = createRecord(s, "Bool"); free(s);
        freeRecord($1); freeRecord($3);
    }
    | expression GT expression {
        if (!is_numeric($1->opt1) || !is_numeric($3->opt1)) { type_error(">", $1->opt1, $3->opt1); YYABORT; }
        char *s = cat("(", $1->code, " > ", $3->code, ")");
        $$ = createRecord(s, "Bool"); free(s);
        freeRecord($1); freeRecord($3);
    }
    | expression LE expression {
        if (!is_numeric($1->opt1) || !is_numeric($3->opt1)) { type_error("<=", $1->opt1, $3->opt1); YYABORT; }
        char *s = cat("(", $1->code, " <= ", $3->code, ")");
        $$ = createRecord(s, "Bool"); free(s);
        freeRecord($1); freeRecord($3);
    }
    | expression GE expression {
        if (!is_numeric($1->opt1) || !is_numeric($3->opt1)) { type_error(">=", $1->opt1, $3->opt1); YYABORT; }
        char *s = cat("(", $1->code, " >= ", $3->code, ")");
        $$ = createRecord(s, "Bool"); free(s);
        freeRecord($1); freeRecord($3);
    }
    | expression EQ expression {
        if (!is_numeric($1->opt1) || !is_numeric($3->opt1)) { type_error("==", $1->opt1, $3->opt1); YYABORT; }
        char *s = cat("(", $1->code, " == ", $3->code, ")");
        $$ = createRecord(s, "Bool"); free(s);
        freeRecord($1); freeRecord($3);
    }
    | expression NE expression {
        if (!is_numeric($1->opt1) || !is_numeric($3->opt1)) { type_error("!=", $1->opt1, $3->opt1); YYABORT; }
        char *s = cat("(", $1->code, " != ", $3->code, ")");
        $$ = createRecord(s, "Bool"); free(s);
        freeRecord($1); freeRecord($3);
    }
    | expression AND expression {
        if (!is_bool($1->opt1) || !is_bool($3->opt1)) { type_error("&&", $1->opt1, $3->opt1); YYABORT; }
        char *s = cat("(", $1->code, " && ", $3->code, ")");
        $$ = createRecord(s, "Bool"); free(s);
        freeRecord($1); freeRecord($3);
    }
    | expression OR expression {
        if (!is_bool($1->opt1) || !is_bool($3->opt1)) { type_error("||", $1->opt1, $3->opt1); YYABORT; }
        char *s = cat("(", $1->code, " || ", $3->code, ")");
        $$ = createRecord(s, "Bool"); free(s);
        freeRecord($1); freeRecord($3);
    }
    | NOT expression {
        if (!is_bool($2->opt1)) { type_error("!", $2->opt1, ""); YYABORT; }
        char *s = cat("!(", $2->code, ")", "", "");
        $$ = createRecord(s, "Bool"); free(s);
        freeRecord($2);
    }
    | expression PLUSPLUS {
        if (!is_numeric($1->opt1)) { type_error("++", $1->opt1, ""); YYABORT; }
        char *s = cat($1->code, "++", "", "", "");
        $$ = createRecord(s, $1->opt1); free(s);
        freeRecord($1);
    }
    | expression MINUSMINUS {
        if (!is_numeric($1->opt1)) { type_error("--", $1->opt1, ""); YYABORT; }
        char *s = cat($1->code, "--", "", "", "");
        $$ = createRecord(s, $1->opt1); free(s);
        freeRecord($1);
    }
    | lvalue ASSIGN expression {
        check_assignment_types($1->opt1, $3->opt1);
        char *s = cat($1->code, " = ", $3->code, "", "");
        $$ = createRecord(s, $1->opt1); free(s);
        freeRecord($1); freeRecord($3);
    }
    | expression PLUS_ASSIGN expression
    | expression MINUS_ASSIGN expression
    | expression MUL_ASSIGN expression
    | expression DIV_ASSIGN expression
    | LPAREN expression RPAREN { $$ = $2; }
    | ID LPAREN argument_list RPAREN {
        checkUndeclaredVariable($1);
        const char* func_type = lookupSymbol($1);
        char *s = cat($1, "(", $3->code, ")", "");
        $$ = createRecord(s, strdup(func_type ? func_type : "Unit"));
        free(s); free($1); freeRecord($3);
    }
    | expression DOT ID
    | expression DOT ID LPAREN argument_list RPAREN
    | list_literal
    | NEW type LPAREN expression RPAREN {
        /* new Lista<Int>(10) */
        const char* c_base_type = get_c_base_type($2->opt1);
        /* Quebrando cat em dois passos para respeitar o limite de 5 argumentos */
        char* part1 = cat("( (", $2->code, ") malloc(sizeof(", c_base_type, "");
        char* part2 = cat(") * (", $4->code, ")) )", "", "");
        
        char* s = cat(part1, part2, "", "", "");
        
        $$ = createRecord(s, "Pointer");
        free(part1); free(part2); free(s);
        freeRecord($2); freeRecord($4);
    }
    | NEW type LPAREN expression COMMA expression RPAREN {
        /* new Matriz<Int>(10, 20) */
        const char* c_base_type = get_c_base_type($2->opt1);
        
        /* Chama a função auxiliar alloc_matrix(rows, cols, sizeof(base_type)) */
        char* s_alloc = cat("alloc_matrix(", $4->code, ", ", $6->code, ", sizeof(");
        char* s_final = cat(s_alloc, c_base_type, "))", "", "");
        
        /* Cast para o tipo da variável (ex: int**) */
        char* s_cast = cat("( (", $2->code, ") ", s_final, ")");
        
        $$ = createRecord(s_cast, "Pointer");
        free(s_alloc); free(s_final); free(s_cast);
        freeRecord($2); freeRecord($4); freeRecord($6);
    }
    | NULO { $$ = createRecord("NULL", "null"); }
    ;

list_literal:
    LBRACKET RBRACKET { $$ = createRecord("NULL", "List"); }
    | LBRACKET expression_list RBRACKET { $$ = $2; }
    ;

argument_list:
      { $$ = createRecord("", ""); }
    | expression_list
    ;

expression_list:
    expression { $$ = $1; }
    | expression_list COMMA expression {
        char *s = cat($1->code, ", ", $3->code, "", "");
        $$ = createRecord(s, ""); free(s);
        freeRecord($1); freeRecord($3);
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro de Sintaxe na linha %d: %s (perto de '%s')\n", yylineno, s, yytext);
}

char* cat(const char *s1, const char *s2, const char *s3, const char *s4, const char *s5) {
    size_t len = strlen(s1) + strlen(s2) + strlen(s3) + strlen(s4) + strlen(s5) + 1;
    char *o = malloc(len);
    if (!o) { fprintf(stderr, "Erro de malloc!\n"); exit(1); }
    sprintf(o, "%s%s%s%s%s", s1, s2, s3, s4, s5);
    return o;
}

const char* map_type(const char* o) {
    if (strcmp(o, "Int") == 0) return "int";
    if (strcmp(o, "Float") == 0) return "double";
    if (strcmp(o, "String") == 0) return "char*";
    if (strcmp(o, "Bool") == 0) return "int";
    return "void";
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "Uso: %s <in> <out>\n", argv[0]);
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror("fopen in"); return 1;
    }
    yyout = fopen(argv[2], "w");
    if (!yyout) {
        perror("fopen out"); fclose(yyin); return 1;
    }
    initSymbolTable();
    yyparse();
    freeSymbolTable();
    fclose(yyin);
    fclose(yyout);
    return 0;
}