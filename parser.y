%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "./lib/record.h"
#include "./lib/symbol_table.h"
#include "./lib/type_table.h"

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

static Field temp_fields[100];
static int temp_field_count = 0;

struct FuncHeader {
    struct record* type_rec;
    char* name;
    struct record* param_rec;
};

struct ForHeader {
    struct record* init_rec;
    struct record* cond_rec;
    struct record* incr_rec;
    char *l_cond;
    char *l_incr;
    char *l_end;
};

struct WhileHeader {
    struct record* cond_rec;
    char *l_start;
    char *l_end;
};

struct DoHeader {
    char *l_start;
    char *l_cond;
    char *l_end;
};

typedef struct {
    char *lbl_continue;
    char *lbl_break;
} LoopLabelInfo;

#define MAX_LOOPS 50
static LoopLabelInfo loop_stack[MAX_LOOPS];
static int loop_top = -1;

void push_loop(char *lbl_cont, char *lbl_brk) {
    if (loop_top < MAX_LOOPS - 1) {
        loop_top++;
        loop_stack[loop_top].lbl_continue = strdup(lbl_cont);
        loop_stack[loop_top].lbl_break = strdup(lbl_brk);
    } else {
        fprintf(stderr, "Erro fatal: Muitos laços aninhados (limite %d)\n", MAX_LOOPS);
        exit(1);
    }
}

void pop_loop() {
    if (loop_top >= 0) {
        free(loop_stack[loop_top].lbl_continue);
        free(loop_stack[loop_top].lbl_break);
        loop_top--;
    }
}

const char* get_current_continue_label() {
    if (loop_top >= 0) return loop_stack[loop_top].lbl_continue;
    return NULL;
}

const char* get_current_break_label() {
    if (loop_top >= 0) return loop_stack[loop_top].lbl_break;
    return NULL;
}

char *new_label() {
    char buf[32];
    sprintf(buf, "L%d", label_count++);
    return strdup(buf);
}

char* get_val_code(struct record* rec) {
    if (rec->opt1 && strncmp(rec->opt1, "ref", 3) == 0) {
        return cat("(*", rec->code, ")", "", "");
    }
    return strdup(rec->code);
}

const char* get_base_type_name(const char* type) {
    if (type && strncmp(type, "ref", 3) == 0) {
        return type + 3;
    }
    return type;
}

const char* get_field_type_from_table(const char* struct_name, const char* field_name) {
    const char* s_name = get_base_type_name(struct_name);
    int count = 0;
    Field* fields = getFieldsOfType(s_name, &count);
    if (!fields) return NULL;
    for(int i=0; i<count; i++) {
        if(strcmp(fields[i].name, field_name) == 0) return fields[i].type;
    }
    return NULL;
}

void type_error(const char* op, const char* t1, const char* t2) {
    fprintf(stderr, "ERRO SEMÂNTICO (linha %d): Operação '%s' inválida entre os tipos '%s' e '%s'\n", yylineno, op, t1, t2);
    exit(1);
}

int is_numeric(const char* type) {
    const char* t = get_base_type_name(type);
    if (t == NULL) return 0;
    return (strcmp(t, "Int") == 0 || strcmp(t, "Float") == 0);
}

int is_string(const char* type) {
    const char* t = get_base_type_name(type);
    if (t == NULL) return 0;
    return (strcmp(t, "String") == 0);
}

int is_bool(const char* type) {
    const char* t = get_base_type_name(type);
    if (t == NULL) return 0;
    return (strcmp(t, "Int") == 0 || strcmp(t, "Bool") == 0);
}

int is_print_chain(const char* type) {
    if (type == NULL) return 0;
    return (strncmp(type, "PrintChain", 10) == 0);
}

void check_assignment_types(const char* var_type, const char* val_type) {
    if (var_type == NULL || val_type == NULL) return;
    const char* t1 = get_base_type_name(var_type);
    const char* t2 = get_base_type_name(val_type);
    
    if (strcmp(t1, t2) == 0) return;
    if (strcmp(t1, "Float") == 0 && strcmp(t2, "Int") == 0) return;
    if (strcmp(t1, "Bool") == 0 && strcmp(t2, "Int") == 0) return;
    if (strcmp(t1, "Int") == 0 && strcmp(t2, "Bool") == 0) return;
    if (strstr(var_type, "Lista<") && strcmp(val_type, "Pointer") == 0) return;
    if (strstr(var_type, "Matriz<") && strcmp(val_type, "Pointer") == 0) return;
    if (strcmp(val_type, "Pointer") == 0) return;
    if (strcmp(val_type, "null") == 0 && !is_numeric(var_type) && !is_bool(var_type)) return;

    fprintf(stderr, "ERRO SEMÂNTICO (linha %d): Impossível atribuir tipo '%s' a uma variável do tipo '%s'\n", yylineno, val_type, var_type);
    exit(1);
}

const char* get_result_type(const char* t1, const char* t2) {
    const char* b1 = get_base_type_name(t1);
    const char* b2 = get_base_type_name(t2);
    if (strcmp(b1, "Float") == 0 || strcmp(b2, "Float") == 0) return "Float";
    return "Int";
}

char* get_inner_type(const char* complex_type) {
    const char* type = get_base_type_name(complex_type);
    if (type == NULL) return strdup("void");
    if (strncmp(type, "Matriz<", 7) == 0) {
        int len = strlen(type);
        char* new_type = malloc(len); 
        sprintf(new_type, "Lista<%s", type + 7); 
        return new_type;
    }
    if (strncmp(type, "Lista<", 6) == 0) {
        const char *start = strchr(type, '<');
        const char *end = strrchr(type, '>');
        if (start && end) {
            int len = end - (start + 1);
            char *base_type = malloc(len + 1);
            strncpy(base_type, start + 1, len);
            base_type[len] = '\0';
            return base_type;
        }
    }
    return strdup(type); 
}

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
    struct WhileHeader* while_header;
    struct DoHeader* do_header;
}

%token <str_val> ID
%token <int_val> INT_LIT
%token <float_val> FLOAT_LIT
%token <str_val> STRING_LIT

%token IF ENDIF ELSE FOR ENDFOR SWITCH ENDSWITCH WHILE ENDWHILE
%token RETURN PRINTF SHOW SCANF CONST BREAK CONTINUE CASE DEFAULTCASE TRY CATCH FINALLY
%token DO UNTIL FUNCTION ENDFUNCTION STRUCT ENDSTRUCT ENUM
%token REF NEW NULO
%token TYPE_INT TYPE_FLOAT TYPE_STRING TYPE_BOOL TYPE_LIST TYPE_MATRIZ 

%token ASSIGN EQ NE LE GE LT GT AND OR NOT
%token PLUS_ASSIGN MINUS_ASSIGN MUL_ASSIGN DIV_ASSIGN
%token PLUS MINUS MUL DIV PLUSPLUS MINUSMINUS MOD AMPERSAND
%token SEMICOLON COLON COMMA LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET DOT

%type <rec> program declaration_list function_definition struct_definition member_list member
%type <rec> optional_statement_list statement_list_non_empty
%type <rec> statement declaration_statement
%type <rec> expression_statement if_statement while_statement for_statement return_statement
%type <rec> print_statement show_statement scan_statement
%type <rec> type simple_type
%type <rec> expression list_literal lvalue 
%type <rec> parameter_list param_list_non_empty parameter
%type <rec> argument_list expression_list
%type <rec> brace_block do_statement switch_statement for_init case_item case_list default_case

%type <func_header> func_header_push
%type <for_header> for_header_part
%type <while_header> while_header_part
%type <do_header> do_header_part
%type <rec> for_header_scope rparen_push colon_push lbrace_push

%right ASSIGN PLUS_ASSIGN MINUS_ASSIGN MUL_ASSIGN DIV_ASSIGN
%left OR
%left AND
%left EQ NE
%left LT LE GT GE
%left PLUS MINUS
%left MUL DIV MOD
%right NOT PLUSPLUS MINUSMINUS AMPERSAND
%left DOT LPAREN RPAREN LBRACKET RBRACKET

%%

program:
    declaration_list {
        fprintf(yyout, "#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n\nvoid** alloc_matrix(int r, int c, size_t size) {\n    void** m = malloc(r * sizeof(void*));\n    for(int i=0; i<r; i++) m[i] = malloc(c * size);\n    return m;\n}\n\n");
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
        char *s = cat($1->code, "\n", $2->code, "", "");
        $$ = createRecord(s, ""); free(s);
        freeRecord($1); freeRecord($2);
    }
    ;

struct_definition:
    STRUCT ID { current_struct_name = strdup($2); temp_field_count = 0; } member_list ENDSTRUCT { 
        char *typedef_decl = cat("typedef struct ", $2, " ", $2, ";\n");
        char *struct_body = cat("struct ", $2, " {\n", $4->code, "};\n");
        char *final_code = cat(typedef_decl, struct_body, "", "", "");
        $$ = createRecord(final_code, ""); 
        insertCustomType($2, temp_fields, temp_field_count);
        free(typedef_decl); free(struct_body); free(final_code);
        free($2); freeRecord($4);
        free(current_struct_name); current_struct_name = NULL;
    }
    ;

member_list:
      { $$ = createRecord("", ""); }
    | member_list member {
        char *s = cat($1->code, $2->code, "", "", "");
        $$ = createRecord(s, ""); free(s);
        freeRecord($1); freeRecord($2);
    }
    ;

member:
    type ID SEMICOLON {
        char *s = cat("    ", $1->code, " ", $2, ";\n");
        $$ = createRecord(s, ""); free(s);
        if(temp_field_count < 100) {
            temp_fields[temp_field_count].name = strdup($2);
            temp_fields[temp_field_count].type = strdup($1->opt1);
            temp_field_count++;
        }
        freeRecord($1); free($2);
    }
    ;

func_header_push:
    FUNCTION type ID { checkDuplicateVariable($3); insertSymbol($3, $2->opt1); } LPAREN { pushScope(); } parameter_list RPAREN { 
        current_function_return_type = strdup($2->opt1);
        $$ = malloc(sizeof(struct FuncHeader));
        $$->type_rec = $2; $$->name = $3; $$->param_rec = $7;
    }
    ;

rparen_push: RPAREN { pushScope(); $$ = createRecord("", ""); } ;
do_header_part: DO { 
        pushScope();
        struct DoHeader *dh = malloc(sizeof(struct DoHeader));
        dh->l_start = new_label();
        dh->l_cond = new_label();
        dh->l_end = new_label();
        push_loop(dh->l_cond, dh->l_end);
        $$ = dh;
    } ;

for_header_scope: FOR LPAREN { pushScope(); $$ = createRecord("", ""); } ;

for_header_part: for_header_scope for_init SEMICOLON expression SEMICOLON expression RPAREN { 
        $$ = malloc(sizeof(struct ForHeader));
        $$->init_rec = $2; $$->cond_rec = $4; $$->incr_rec = $6;
        $$->l_cond = new_label();
        $$->l_incr = new_label();
        $$->l_end = new_label();
        push_loop($$->l_incr, $$->l_end);
    } ;

while_header_part: WHILE LPAREN expression RPAREN {
        pushScope();
        struct WhileHeader *wh = malloc(sizeof(struct WhileHeader));
        wh->cond_rec = $3;
        wh->l_start = new_label();
        wh->l_end = new_label();
        push_loop(wh->l_start, wh->l_end);
        $$ = wh;
    } ;

colon_push: COLON { pushScope(); $$ = createRecord("", ""); } ;
lbrace_push: LBRACE { pushScope(); $$ = createRecord("", ""); } ;

function_definition:
    func_header_push optional_statement_list ENDFUNCTION {
        const char *func_name = $1->name;
        const char *rt = $1->type_rec->code;
        if (strcmp($1->name, "Main") == 0) { func_name = "main"; rt = "int"; }
        char *h = cat(rt, " ", func_name, "(", $1->param_rec->code);
        char *b = cat(h, ") {\n", $2->code, "}\n", "");
        $$ = createRecord(b, ""); free(h); free(b);
        freeRecord($1->type_rec); free($1->name); freeRecord($1->param_rec); free($1); freeRecord($2);
        free(current_function_return_type); current_function_return_type = NULL; popScope();
    }
    ;

parameter_list: { $$ = createRecord("", ""); } | param_list_non_empty ;
param_list_non_empty: parameter { $$ = $1; } | param_list_non_empty COMMA parameter {
        char *s = cat($1->code, ", ", $3->code, "", "");
        $$ = createRecord(s, ""); free(s); freeRecord($1); freeRecord($3);
    } ;
parameter: type ID {
        checkDuplicateVariable($2);
        char *s = cat($1->code, " ", $2, "", "");
        $$ = createRecord(s, $1->opt1); insertSymbol($2, $1->opt1);
        free(s); freeRecord($1); free($2);
    } ;

type:
    simple_type { $$ = $1; }
    | TYPE_LIST LT simple_type GT {
        char* c_type = cat($3->code, "*", "", "", "");
        char* internal_type = cat("Lista<", $3->opt1, ">", "", "");
        $$ = createRecord(c_type, internal_type); free(c_type); free(internal_type); freeRecord($3);
    }
    | TYPE_MATRIZ LT simple_type GT {
        char* c_type = cat($3->code, "**", "", "", "");
        char* internal_type = cat("Matriz<", $3->opt1, ">", "", "");
        $$ = createRecord(c_type, internal_type); free(c_type); free(internal_type); freeRecord($3);
    }
    | REF simple_type {
        char* s = cat($2->code, "*", "", "", "");
        char* t = cat("ref", $2->opt1, "", "", "");
        $$ = createRecord(s, t); free(s); free(t); freeRecord($2);
    }
    ;

simple_type:
    TYPE_INT { $$ = createRecord("int", "Int"); }
    | TYPE_FLOAT { $$ = createRecord("double", "Float"); }
    | TYPE_STRING { $$ = createRecord("char*", "String"); }
    | TYPE_BOOL { $$ = createRecord("int", "Bool"); }
    | ID { 
        char* s = cat($1, "*", "", "", "");
        $$ = createRecord(s, $1); free(s); free($1); 
    }
    ;

brace_block: lbrace_push optional_statement_list RBRACE { popScope(); $$ = $2; freeRecord($1); } ;
optional_statement_list: { $$ = createRecord("", ""); } | statement_list_non_empty { $$ = $1; } ;
statement_list_non_empty: statement { $$ = $1; } | statement_list_non_empty statement {
        if ($2 == NULL) { $$ = $1; }
        else {
            char *s = cat($1->code, $2->code, "\n", "", "");
            $$ = createRecord(s, ""); free(s); freeRecord($1); freeRecord($2);
        }
    } ;

statement:
    expression_statement { $$ = $1; }
    | declaration_statement { $$ = $1; }
    | do_statement { $$ = $1; }
    | if_statement { $$ = $1; }
    | switch_statement { $$ = $1; }
    | while_statement { $$ = $1; }
    | for_statement { $$ = $1; }
    | return_statement { $$ = $1; }
    | print_statement { $$ = $1; }
    | show_statement { $$ = $1; }
    | scan_statement { $$ = $1; }
    | brace_block { $$ = $1; }
    | BREAK SEMICOLON { 
        const char *lbl = get_current_break_label();
        if (!lbl) { fprintf(stderr, "ERRO SEMÂNTICO: 'pare' fora de laço\n"); exit(1); }
        char *s = cat("    goto ", lbl, ";", "", "");
        $$ = createRecord(s, ""); free(s);
    }
    | CONTINUE SEMICOLON { 
        const char *lbl = get_current_continue_label();
        if (!lbl) { fprintf(stderr, "ERRO SEMÂNTICO: 'continue' fora de laço\n"); exit(1); }
        char *s = cat("    goto ", lbl, ";", "", "");
        $$ = createRecord(s, ""); free(s);
    }
    | SEMICOLON { $$ = createRecord("", ""); }
    ;

declaration_statement:
    type ID SEMICOLON {
        checkDuplicateVariable($2);
        char *s_p = cat("    ", $1->code, " ", $2, ";");
        char *s = cat(s_p, "", "", "", "");
        $$ = createRecord(s, ""); free(s_p); free(s);
        insertSymbol($2, $1->opt1); freeRecord($1); free($2);
    }
    | type ID ASSIGN expression SEMICOLON {
        checkDuplicateVariable($2); check_assignment_types($1->opt1, $4->opt1);
        char *s_p1 = cat("    ", $1->code, " ", $2, " = ");
        char *s_p2 = cat($4->code, ";", "", "", "");
        char *s = cat(s_p1, s_p2, "", "", "");
        $$ = createRecord(s, ""); free(s_p1); free(s_p2); free(s);
        insertSymbol($2, $1->opt1); freeRecord($1); free($2); freeRecord($4);
    }
    ;

expression_statement: expression SEMICOLON { char *s = cat("    ", $1->code, ";", "", ""); $$ = createRecord(s, ""); free(s); freeRecord($1); } ;

scan_statement: SCANF LPAREN expression RPAREN SEMICOLON {
        char *format_spec = "";
        const char* base = get_base_type_name($3->opt1);
        if (strcmp(base, "Int") == 0) format_spec = "%d";
        else if (strcmp(base, "Float") == 0) format_spec = "%lf";
        else if (strcmp(base, "String") == 0) format_spec = "%s";
        char *s;
        if (strncmp($3->opt1, "ref", 3) == 0) s = cat("    scanf(\"", format_spec, "\", ", $3->code, ");");
        else s = cat("    scanf(\"", format_spec, "\", &", $3->code, ");");
        $$ = createRecord(s, ""); free(s); freeRecord($3);
    } ;

do_statement: do_header_part optional_statement_list UNTIL LPAREN expression RPAREN SEMICOLON { 
    popScope(); pop_loop();
    struct DoHeader *dh = $1;
    char *l_start = cat(dh->l_start, ":", "", "", "");
    char *l_cond = cat(dh->l_cond, ":", "", "", "");
    char *l_end = cat(dh->l_end, ":", "", "", "");
    char *check = cat("    if (!(", $5->code, ")) goto ", dh->l_start, ";");
    char *s1 = cat("    ", l_start, "\n", $2->code, "\n");
    char *s2 = cat("    ", l_cond, "\n", check, "\n");
    char *s3 = cat("    ", l_end, "", "", "");
    char *fin = cat(s1, s2, s3, "", "");
    $$ = createRecord(fin, "");
    free(l_start); free(l_cond); free(l_end); free(check); free(s1); free(s2); free(s3);
    freeRecord($2); freeRecord($5); free(dh->l_start); free(dh->l_cond); free(dh->l_end); free(dh);
} ;

if_statement: IF LPAREN expression rparen_push optional_statement_list ENDIF { 
    popScope();
    char *le = new_label(); 
    char *c = cat("    if (!(", $3->code, ")) goto ", le, ";"); 
    char *l = cat(le, ":", "", "", ""); 
    char *s = cat(c, "\n", $5->code, "\n    ", l);
    $$ = createRecord(s, ""); free(le); free(c); free(l); free(s); freeRecord($3); freeRecord($4); freeRecord($5);
} 
| IF LPAREN expression rparen_push optional_statement_list ELSE optional_statement_list ENDIF { 
    popScope();
    char *lelse = new_label(); char *lend = new_label();
    char *c = cat("    if (!(", $3->code, ")) goto ", lelse, ";");
    char *g = cat("    goto ", lend, ";", "", ""); 
    char *le = cat(lelse, ":", "", "", ""); char *ln = cat(lend, ":", "", "", "");
    char *s1 = cat(c, "\n", $5->code, "\n", g);
    char *s2 = cat("\n    ", le, "\n", $7->code, "\n    ");
    char *s = cat(s1, s2, ln, "", "");
    $$ = createRecord(s, ""); free(lelse); free(lend); free(c); free(g); free(le); free(ln); free(s1); free(s2); free(s);
    freeRecord($3); freeRecord($4); freeRecord($5); freeRecord($7);
} ;

while_statement: while_header_part optional_statement_list ENDWHILE { 
    popScope(); pop_loop();
    struct WhileHeader *wh = $1;
    char *l_start = cat(wh->l_start, ":", "", "", "");
    char *l_end = cat(wh->l_end, ":", "", "", "");
    char *check = cat("    if (!(", wh->cond_rec->code, ")) goto ", wh->l_end, ";");
    char *loop_back = cat("    goto ", wh->l_start, ";", "", "");
    char *s1 = cat("    ", l_start, "\n", check, "\n");
    char *s2 = cat($2->code, "\n", loop_back, "", "\n");
    char *s3 = cat("    ", l_end, "", "", "");
    char *fin = cat(s1, s2, s3, "", "");
    $$ = createRecord(fin, "");
    free(l_start); free(l_end); free(check); free(loop_back); free(s1); free(s2); free(s3);
    freeRecord(wh->cond_rec); freeRecord($2); free(wh->l_start); free(wh->l_end); free(wh);
} ;

for_statement: for_header_part optional_statement_list ENDFOR { 
    popScope(); pop_loop();
    struct ForHeader *fh = $1;
    char *l_cond = cat(fh->l_cond, ":", "", "", "");
    char *l_incr = cat(fh->l_incr, ":", "", "", "");
    char *l_end = cat(fh->l_end, ":", "", "", "");
    char *check = cat("    if (!(", fh->cond_rec->code, ")) goto ", fh->l_end, ";");
    char *incr_code = cat("    ", fh->incr_rec->code, ";", "", "");
    char *loop_back = cat("    goto ", fh->l_cond, ";", "", "");
    char *s1 = cat("    ", fh->init_rec->code, ";\n    ", l_cond, "\n");
    char *s2 = cat(check, "\n", $2->code, "\n    ", l_incr);
    char *s3 = cat("\n", incr_code, "\n", loop_back, "\n    ");
    char *s4 = cat(l_end, "", "", "", "");
    char *inner = cat(s1, s2, s3, s4, "");
    char *fin = cat("{\n", inner, "\n}\n", "", "");
    $$ = createRecord(fin, "");
    free(l_cond); free(l_incr); free(l_end); free(check); free(incr_code); free(loop_back);
    free(s1); free(s2); free(s3); free(s4); free(inner);
    freeRecord(fh->init_rec); freeRecord(fh->cond_rec); freeRecord(fh->incr_rec); 
    free(fh->l_cond); free(fh->l_incr); free(fh->l_end); free(fh); freeRecord($2);
} ;

for_init: type ID ASSIGN expression { 
    checkDuplicateVariable($2); check_assignment_types($1->opt1, $4->opt1); 
    char *s = cat($1->code, " ", $2, " = ", $4->code); 
    $$ = createRecord(s, ""); free(s); 
    insertSymbol($2, $1->opt1); freeRecord($1); free($2); freeRecord($4); 
} 
| expression { $$ = $1; } ;

switch_statement: SWITCH LPAREN expression RPAREN case_list ENDSWITCH {
    char *s = cat("    switch(", $3->code, ") {\n", $5->code, "    }\n"); 
    $$ = createRecord(s, ""); free(s); freeRecord($3); freeRecord($5);
} 
| SWITCH LPAREN expression RPAREN case_list default_case ENDSWITCH {
    char *p1 = cat("    switch(", $3->code, ") {\n", $5->code, $6->code);
    char *s = cat(p1, "    }\n", "", "", "");
    $$ = createRecord(s, ""); free(p1); free(s); freeRecord($3); freeRecord($5); freeRecord($6);
} ;

case_list: case_item { $$ = $1; } 
| case_list case_item { char *s = cat($1->code, $2->code, "", "", ""); $$ = createRecord(s, ""); free(s); freeRecord($1); freeRecord($2); } ;

case_item: CASE expression colon_push optional_statement_list { 
    popScope(); 
    char *s = cat("    case ", $2->code, ":\n", $4->code, "\n      break;\n"); 
    $$ = createRecord(s, ""); free(s); freeRecord($2); freeRecord($3); freeRecord($4); 
} ;

default_case: DEFAULTCASE colon_push optional_statement_list { 
    popScope(); 
    char *s = cat("    default:\n", $3->code, "\n      break;\n", "", ""); 
    $$ = createRecord(s, ""); free(s); freeRecord($2); freeRecord($3); 
} ;

return_statement: RETURN expression SEMICOLON {
    if (current_function_return_type == NULL) { fprintf(stderr, "ERRO: retorne fora de função\n"); exit(1); }
    check_assignment_types(current_function_return_type, $2->opt1);
    char *s = cat("    return ", $2->code, ";", "", ""); $$ = createRecord(s, ""); free(s); freeRecord($2);
} ;

print_statement:
    PRINTF LPAREN expression RPAREN SEMICOLON {
        char* code = $3->code; char* type = $3->opt1; char* val = get_val_code($3); char* s;
        if (is_print_chain(type)) {
            char* args = strchr(type, ',');
            if (args == NULL) args = "";
            char* p1 = cat("    printf(", code, " \"\\n\"", args, ");");
            s = cat(p1, "", "", "", "");
            free(p1);
        }
        else if (is_numeric(type) || is_bool(type)) {
             char* fmt = (strcmp(get_base_type_name(type), "Int") == 0 || strcmp(get_base_type_name(type), "Bool") == 0) ? "%d\\n" : "%lf\\n";
             s = cat("    printf(\"", fmt, "\", ", val, ");");
        } else if (is_string(type)) s = cat("    printf(\"%s\\n\", ", code, ");", "", "");
        else s = cat("    printf(\"TIPO DESCONHECIDO\\n\");", "", "", "", "");
        $$ = createRecord(s, ""); free(s); if(val != code) free(val); freeRecord($3);
    }
    ;

show_statement:
    SHOW LPAREN expression RPAREN SEMICOLON {
        char* code = $3->code; char* type = $3->opt1; char* val = get_val_code($3); char* s;
        if (is_print_chain(type)) {
            char* args = strchr(type, ',');
            if (args == NULL) args = "";
            char* p1 = cat("    printf(", code, args, ");", "");
            s = cat(p1, "", "", "", "");
            free(p1);
        }
        else if (is_numeric(type) || is_bool(type)) {
             char* fmt = (strcmp(get_base_type_name(type), "Int") == 0 || strcmp(get_base_type_name(type), "Bool") == 0) ? "%d " : "%lf ";
             s = cat("    printf(\"", fmt, "\", ", val, ");");
        } else if (is_string(type)) s = cat("    printf(\"%s\", ", code, ");", "", "");
        else s = cat("    printf(\"TIPO DESCONHECIDO\");", "", "", "", "");
        $$ = createRecord(s, ""); free(s); if(val != code) free(val); freeRecord($3);
    }
    ;

lvalue: ID { checkUndeclaredVariable($1); const char *t = lookupSymbol($1); $$ = createRecord($1, strdup(t?t:"")); }
    | lvalue LBRACKET expression RBRACKET { char* s = cat($1->code, "[", $3->code, "]", ""); char* t = get_inner_type($1->opt1); $$ = createRecord(s, t); free(s); free(t); freeRecord($1); freeRecord($3); }
    | lvalue DOT ID { char* s = cat($1->code, "->", $3, "", ""); const char* t = get_field_type_from_table($1->opt1, $3); $$ = createRecord(s, strdup(t?t:"Int")); free(s); freeRecord($1); free($3); }
    ;

expression:
    INT_LIT { char b[32]; sprintf(b, "%d", $1); $$ = createRecord(strdup(b), "Int"); }
    | FLOAT_LIT { char b[32]; sprintf(b, "%f", $1); $$ = createRecord(strdup(b), "Float"); }
    | STRING_LIT { char* s = cat("\"", $1, "\"", "", ""); $$ = createRecord(s, "String"); free(s); free($1); }
    | lvalue { $$ = $1; }
    | expression PLUS expression { 
        const char* t1 = $1->opt1; const char* t2 = $3->opt1; char *rc = NULL, *rt = NULL;
        if (is_string(t1) || is_string(t2) || is_print_chain(t1)) { 
             if (is_string(t1) && is_string(t2)) { rc = cat($1->code, $3->code, "", "", ""); rt = strdup("String"); }
             else if (is_string(t1) && is_numeric(t2)) { 
                 char* fmt = (strcmp(get_base_type_name(t2), "Int")==0) ? "%d" : "%lf"; char* v = get_val_code($3);
                 char *str_content = strdup($1->code); str_content[strlen(str_content)-1] = '\0';
                 rc = cat(str_content, fmt, "\"", "", ""); rt = cat("PrintChain, ", v, "", "", ""); 
                 free(str_content); if(v!=$3->code) free(v);
             }
             else if (is_print_chain(t1) && is_string(t2)) { rc = cat($1->code, $3->code, "", "", ""); rt = strdup(t1); }
             else if (is_print_chain(t1) && is_numeric(t2)) {
                 char* fmt = (strcmp(get_base_type_name(t2), "Int")==0) ? "%d" : "%lf"; char* v = get_val_code($3);
                 char *str_content = strdup($1->code); str_content[strlen(str_content)-1] = '\0';
                 rc = cat(str_content, fmt, "\"", "", ""); rt = cat(t1, ", ", v, "", ""); 
                 free(str_content); if(v!=$3->code) free(v);
             }
        } else if (is_numeric(t1) && is_numeric(t2)) {
            char *v1 = get_val_code($1), *v2 = get_val_code($3);
            rc = cat("(", v1, " + ", v2, ")"); rt = strdup(get_result_type(t1, t2));
            if(v1!=$1->code) free(v1); if(v2!=$3->code) free(v2);
        } else { type_error("+", t1, t2); }
        $$ = createRecord(rc, rt); freeRecord($1); freeRecord($3);
    }
    | expression MINUS expression { char *v1=get_val_code($1), *v2=get_val_code($3); char *s = cat("(", v1, " - ", v2, ")"); $$ = createRecord(s, strdup(get_result_type($1->opt1, $3->opt1))); if(v1!=$1->code) free(v1); if(v2!=$3->code) free(v2); freeRecord($1); freeRecord($3); }
    | expression MUL expression { char *v1=get_val_code($1), *v2=get_val_code($3); char *s = cat("(", v1, " * ", v2, ")"); $$ = createRecord(s, strdup(get_result_type($1->opt1, $3->opt1))); if(v1!=$1->code) free(v1); if(v2!=$3->code) free(v2); freeRecord($1); freeRecord($3); }
    | expression DIV expression { char *v1=get_val_code($1), *v2=get_val_code($3); char *s = cat("(", v1, " / ", v2, ")"); $$ = createRecord(s, "Float"); if(v1!=$1->code) free(v1); if(v2!=$3->code) free(v2); freeRecord($1); freeRecord($3); }
    | expression MOD expression { char *v1=get_val_code($1), *v2=get_val_code($3); char *s = cat("(", v1, " % ", v2, ")"); $$ = createRecord(s, "Int"); if(v1!=$1->code) free(v1); if(v2!=$3->code) free(v2); freeRecord($1); freeRecord($3); }
    | expression LT expression { char *v1=get_val_code($1), *v2=get_val_code($3); char *s = cat("(", v1, " < ", v2, ")"); $$ = createRecord(s, "Bool"); if(v1!=$1->code) free(v1); if(v2!=$3->code) free(v2); freeRecord($1); freeRecord($3); }
    | expression GT expression { char *v1=get_val_code($1), *v2=get_val_code($3); char *s = cat("(", v1, " > ", v2, ")"); $$ = createRecord(s, "Bool"); if(v1!=$1->code) free(v1); if(v2!=$3->code) free(v2); freeRecord($1); freeRecord($3); }
    | expression LE expression { char *v1=get_val_code($1), *v2=get_val_code($3); char *s = cat("(", v1, " <= ", v2, ")"); $$ = createRecord(s, "Bool"); if(v1!=$1->code) free(v1); if(v2!=$3->code) free(v2); freeRecord($1); freeRecord($3); }
    | expression GE expression { char *v1=get_val_code($1), *v2=get_val_code($3); char *s = cat("(", v1, " >= ", v2, ")"); $$ = createRecord(s, "Bool"); if(v1!=$1->code) free(v1); if(v2!=$3->code) free(v2); freeRecord($1); freeRecord($3); }
    | expression EQ expression { char *v1=get_val_code($1), *v2=get_val_code($3); char *s = cat("(", v1, " == ", v2, ")"); $$ = createRecord(s, "Bool"); if(v1!=$1->code) free(v1); if(v2!=$3->code) free(v2); freeRecord($1); freeRecord($3); }
    | expression NE expression { char *v1=get_val_code($1), *v2=get_val_code($3); char *s = cat("(", v1, " != ", v2, ")"); $$ = createRecord(s, "Bool"); if(v1!=$1->code) free(v1); if(v2!=$3->code) free(v2); freeRecord($1); freeRecord($3); }
    
    | expression AND expression { char *v1 = get_val_code($1); char *v2 = get_val_code($3); char *s = cat("(", v1, " && ", v2, ")"); $$ = createRecord(s, "Bool"); if(v1 != $1->code) free(v1); if(v2 != $3->code) free(v2); freeRecord($1); freeRecord($3); }
    | expression OR expression { char *v1 = get_val_code($1); char *v2 = get_val_code($3); char *s = cat("(", v1, " || ", v2, ")"); $$ = createRecord(s, "Bool"); if(v1 != $1->code) free(v1); if(v2 != $3->code) free(v2); freeRecord($1); freeRecord($3); }
    | NOT expression { char *v = get_val_code($2); char *s = cat("(!", v, ")", "", ""); $$ = createRecord(s, "Bool"); if(v != $2->code) free(v); freeRecord($2); }
    | AMPERSAND ID { checkUndeclaredVariable($2); char *s = cat("&", $2, "", "", ""); const char *bt = lookupSymbol($2); char *rt = cat("ref", bt, "", "", ""); $$ = createRecord(s, rt); free(s); free(rt); free($2); }
    | PLUSPLUS lvalue { char *s = cat("++", $2->code, "", "", ""); $$ = createRecord(s, $2->opt1); free(s); freeRecord($2); }
    | MINUSMINUS lvalue { char *s = cat("--", $2->code, "", "", ""); $$ = createRecord(s, $2->opt1); free(s); freeRecord($2); }
    | lvalue PLUSPLUS { char *s = cat($1->code, "++", "", "", ""); $$ = createRecord(s, $1->opt1); free(s); freeRecord($1); }
    | lvalue MINUSMINUS { char *s = cat($1->code, "--", "", "", ""); $$ = createRecord(s, $1->opt1); free(s); freeRecord($1); }
    | lvalue ASSIGN expression {
        check_assignment_types($1->opt1, $3->opt1); char *lhs = $1->code; char *rhs = get_val_code($3); char *s;
        if (strncmp($1->opt1, "ref", 3) == 0) { char *d = cat("*", lhs, "", "", ""); s = cat(d, " = ", rhs, "", ""); free(d); }
        else s = cat(lhs, " = ", rhs, "", "");
        $$ = createRecord(s, $1->opt1); free(s); if(rhs!=$3->code) free(rhs); freeRecord($1); freeRecord($3);
    }
    | expression PLUS_ASSIGN expression { char *v1 = get_val_code($1); char *v2 = get_val_code($3); char *s = cat(v1, " += ", v2, "", ""); $$ = createRecord(s, $1->opt1); if(v1 != $1->code) free(v1); if(v2 != $3->code) free(v2); freeRecord($1); freeRecord($3); }
    | expression MINUS_ASSIGN expression { char *v1 = get_val_code($1); char *v2 = get_val_code($3); char *s = cat(v1, " -= ", v2, "", ""); $$ = createRecord(s, $1->opt1); if(v1 != $1->code) free(v1); if(v2 != $3->code) free(v2); freeRecord($1); freeRecord($3); }
    | expression MUL_ASSIGN expression { char *v1 = get_val_code($1); char *v2 = get_val_code($3); char *s = cat(v1, " *= ", v2, "", ""); $$ = createRecord(s, $1->opt1); if(v1 != $1->code) free(v1); if(v2 != $3->code) free(v2); freeRecord($1); freeRecord($3); }
    | expression DIV_ASSIGN expression { char *v1 = get_val_code($1); char *v2 = get_val_code($3); char *s = cat(v1, " /= ", v2, "", ""); $$ = createRecord(s, $1->opt1); if(v1 != $1->code) free(v1); if(v2 != $3->code) free(v2); freeRecord($1); freeRecord($3); }
    | LPAREN expression RPAREN { $$ = $2; }
    | ID LPAREN argument_list RPAREN { checkUndeclaredVariable($1); const char *ft = lookupSymbol($1); char *s = cat($1, "(", $3->code, ")", ""); $$ = createRecord(s, strdup(ft?ft:"Unit")); free(s); free($1); freeRecord($3); }
    | list_literal { $$ = $1; }
    | NEW type LPAREN expression RPAREN {
        const char *cbt = get_c_base_type($2->opt1);
        char *p1 = cat("( (", $2->code, ") malloc(sizeof(", cbt, "");
        char *p2 = cat(") * (", $4->code, ")) )", "", "");
        char *s = cat(p1, p2, "", "", "");
        $$ = createRecord(s, "Pointer"); free(p1); free(p2); free(s); freeRecord($2); freeRecord($4);
    }
    | NEW type LPAREN expression COMMA expression RPAREN {
        const char *cbt = get_c_base_type($2->opt1);
        char *sa = cat("alloc_matrix(", $4->code, ", ", $6->code, ", sizeof(");
        char *sf = cat(sa, cbt, "))", "", "");
        char *sc = cat("( (", $2->code, ") ", sf, ")");
        $$ = createRecord(sc, "Pointer"); free(sa); free(sf); free(sc); freeRecord($2); freeRecord($4); freeRecord($6);
    }
    | NEW type LPAREN RPAREN {
        char *s1 = cat("( (", $2->code, ") malloc(sizeof(struct ", $2->opt1, "");
        char *s = cat(s1, ")) )", "", "", "");
        $$ = createRecord(s, "Pointer"); free(s1); free(s); freeRecord($2);
    }
    | NULO { $$ = createRecord("NULL", "null"); }
    ;

list_literal: LBRACKET RBRACKET { $$ = createRecord("NULL", "List"); } | LBRACKET expression_list RBRACKET { $$ = $2; } ;
argument_list: { $$ = createRecord("", ""); } | expression_list { $$ = $1; } ;
expression_list: expression { $$ = $1; } | expression_list COMMA expression { char *s = cat($1->code, ", ", $3->code, "", ""); $$ = createRecord(s, ""); free(s); freeRecord($1); freeRecord($3); } ;

%%

void yyerror(const char *s) { fprintf(stderr, "Erro de Sintaxe na linha %d: %s (perto de '%s')\n", yylineno, s, yytext); }
char* cat(const char *s1, const char *s2, const char *s3, const char *s4, const char *s5) {
    size_t len = strlen(s1) + strlen(s2) + strlen(s3) + strlen(s4) + strlen(s5) + 1;
    char *o = malloc(len); if (!o) exit(1); sprintf(o, "%s%s%s%s%s", s1, s2, s3, s4, s5); return o;
}
const char* map_type(const char* o) {
    if (strcmp(o, "Int") == 0) return "int";
    if (strcmp(o, "Float") == 0) return "double";
    if (strcmp(o, "String") == 0) return "char*";
    if (strcmp(o, "Bool") == 0) return "int";
    return "void";
}
int main(int argc, char **argv) {
    if (argc != 3) { fprintf(stderr, "Uso: %s <in> <out>\n", argv[0]); return 1; }
    yyin = fopen(argv[1], "r"); if (!yyin) { perror("fopen in"); return 1; }
    yyout = fopen(argv[2], "w"); if (!yyout) { perror("fopen out"); fclose(yyin); return 1; }
    initSymbolTable(); initTypeTable(); yyparse();
    freeSymbolTable(); freeTypeTable(); fclose(yyin); fclose(yyout);
    return 0;
}