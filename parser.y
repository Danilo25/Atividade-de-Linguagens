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

%}

%union {
    int int_val;
    double float_val;
    char *str_val;
    struct record *rec;
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

%token ASSIGN EQ NE LE GE LT GT
%token AND OR NOT
%token PLUS_ASSIGN MINUS_ASSIGN MUL_ASSIGN DIV_ASSIGN
%token PLUS MINUS MUL DIV PLUSPLUS MINUSMINUS
%token SEMICOLON COLON COMMA LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET DOT

%type <rec> program declaration_list function_definition
%type <rec> statement_list statement declaration_statement
%type <rec> expression_statement if_statement while_statement for_statement return_statement
%type <rec> print_statement scan_statement
%type <rec> type simple_type
%type <rec> expression list_literal
%type <rec> parameter_list param_list_non_empty parameter
%type <rec> argument_list expression_list
%type <rec> brace_block
%type <rec> do_statement switch_statement
%type <rec> for_init
%type <rec> case_item case_list default_case

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
    ENDSTRUCT
    ;

member_list:
    | member_list member
    ;

member:
    type ID SEMICOLON
    ;

function_definition:
    FUNCTION type ID LPAREN parameter_list RPAREN
        statement_list
    ENDFUNCTION {
        const char *func_name = $3;
        const char *rt = $2->code;
        if (strcmp($3, "Main") == 0) {
            func_name = "main";
            rt = "int";
        }

        char *h = cat(rt, " ", func_name, "(", $5->code);
        char *b = cat(h, ") {\n", $7->code, "}\n", "");
        $$ = createRecord(b, ""); free(h); free(b);
        freeRecord($2); free($3); freeRecord($5); freeRecord($7);
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
        char *s = cat($1->code, " ", $2, "", "");
        $$ = createRecord(s, $1->opt1);
        insertSymbol($2, $1->opt1);
        free(s); freeRecord($1); free($2);
    }
    ;

type:
    simple_type { $$ = $1; }
    | TYPE_LIST LT type GT {
        $$ = createRecord("/*LISTA*/", "List");
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
    LBRACE statement_list RBRACE { $$ = $2; }
    ;

statement_list:
      { $$ = createRecord("", ""); }
    | statement_list statement {
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
        char *s_p = cat("    ", $1->code, " ", $2, ";");
        char *s = cat(s_p, "", "", "", "");
        $$ = createRecord(s, ""); free(s_p); free(s);
        insertSymbol($2, $1->opt1);
        freeRecord($1); free($2);
    }
    | type ID ASSIGN expression SEMICOLON {
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
    DO statement_list UNTIL LPAREN expression RPAREN SEMICOLON {
        char *l_begin = new_label();
        char *label_begin = cat(l_begin, ":", "", "", "");
        char *c_p = cat("    if (!(", $5->code, ")) goto ", l_begin, ";");
        char *cond = cat(c_p, "", "", "", "");
        char *s1 = cat("    ", label_begin, "\n", $2->code, "\n");
        char *code = cat(s1, cond, "\n", "", "");
        $$ = createRecord(code, "");
        free(l_begin); free(label_begin); free(c_p); free(cond); free(s1); free(code);
        freeRecord($2); freeRecord($5);
    }
    ;

if_statement:
    IF LPAREN expression RPAREN statement_list ENDIF {
        char *lend = new_label();
        char *c_p = cat("    if (!(", $3->code, ")) goto ", lend, ";");
        char *cond = cat(c_p, "", "", "", "");
        char *body = $5->code;
        char *label = cat(lend, ":", "", "", "");
        char *s1 = cat(cond, "\n", body, "\n    ", label);
        char *code = cat(s1, "\n", "", "", "");
        $$ = createRecord(code, "");
        free(lend); free(c_p); free(cond); free(label); free(s1); free(code);
        freeRecord($3); freeRecord($5);
    }
    | IF LPAREN expression RPAREN statement_list ELSE statement_list ENDIF {
        char *l_else = new_label();
        char *l_end = new_label();
        char *c_p = cat("    if (!(", $3->code, ")) goto ", l_else, ";");
        char *cond = cat(c_p, "", "", "", "");
        char *body_if = $5->code;
        char *goto_end = cat("    goto ", l_end, ";", "", "");
        char *label_else = cat(l_else, ":", "", "", "");
        char *body_else = $7->code;
        char *label_end = cat(l_end, ":", "", "", "");

        char *s1 = cat(cond, "\n", body_if, "\n", goto_end);
        char *s2_p = cat("\n", "    ", label_else, "\n", body_else);
        char *s2 = cat(s2_p, "\n    ", label_end, "\n", "");
        char *code = cat(s1, s2, "", "", "");
        
        $$ = createRecord(code, "");
        free(l_else); free(l_end); free(c_p); free(cond); free(goto_end); free(label_else);
        free(label_end); free(s1); free(s2_p); free(s2); free(code);
        freeRecord($3); freeRecord($5); freeRecord($7);
    }
    ;

case_item:
    CASE expression COLON statement_list {
        char* s_p = cat("    case ", $2->code, ":\n", $4->code, "\n      break;\n");
        char* s = cat(s_p, "", "", "", "");
        $$ = createRecord(s, ""); free(s_p); free(s);
        freeRecord($2); freeRecord($4);
    }
    ;

default_case:
    DEFAULTCASE COLON statement_list {
        char* s = cat("    default:\n", $3->code, "\n      break;\n", "", "");
        $$ = createRecord(s, ""); free(s);
        freeRecord($3);
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
    WHILE LPAREN expression RPAREN statement_list ENDWHILE {
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
        freeRecord($3); freeRecord($5);
    }
    ;

for_statement:
    FOR LPAREN for_init SEMICOLON expression SEMICOLON expression RPAREN
        statement_list
    ENDFOR {
        char *l_begin = new_label();
        char *l_end = new_label();
        char *label_begin = cat(l_begin, ":", "", "", "");
        char *c_p = cat("    if (!(", $5->code, ")) goto ", l_end, ";");
        char *cond = cat(c_p, "", "", "", "");
        char *body = $9->code;
        char *increment = cat("    ", $7->code, ";", "", "");
        char *goto_begin = cat("    goto ", l_begin, ";", "", "");
        char *label_end = cat(l_end, ":", "", "", "");

        char *s1 = cat("    ", $3->code, ";\n", "    ", label_begin);
        char *s2 = cat("\n", cond, "\n", body, "\n");
        char *s3 = cat(increment, "\n", goto_begin, "\n", "    ");
        char *s4 = cat(label_end, "\n", "", "", "");
        char *code_p1 = cat(s1, s2, "", "", "");
        char *code_p2 = cat(s3, s4, "", "", "");
        char *code = cat(code_p1, code_p2, "", "", "");


        $$ = createRecord(code, "");
        free(l_begin); free(l_end); free(label_begin); free(c_p); free(cond);
        free(increment); free(goto_begin); free(label_end);
        free(s1); free(s2); free(s3); free(s4); free(code_p1); free(code_p2); free(code);
        freeRecord($3); freeRecord($5); freeRecord($7); freeRecord($9);
    }
    ;

for_init:
    type ID ASSIGN expression {
        char* s = cat($1->code, " ", $2, " = ", $4->code);
        $$ = createRecord(s, ""); free(s);
        insertSymbol($2, $1->opt1);
        freeRecord($1); free($2); freeRecord($4);
    }
    | expression { $$ = $1; }
    ;

return_statement:
    RETURN expression SEMICOLON {
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
                s = cat("    printf(\"%d\\n\", ", code_to_print, ");", "", "");
            }
        }
        
        $$ = createRecord(s, ""); free(s);
        freeRecord($3);
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
    | ID {
        const char *type = lookupSymbol($1);
        $$ = createRecord($1, strdup(type ? type : ""));
    }
    | expression PLUS expression {
        if (strcmp($1->opt1, "String") == 0) {
            char* type_plus_code = cat($3->opt1, "|", $3->code, "", "");
            $$ = createRecord(strdup($1->code), type_plus_code);
            free(type_plus_code);
            freeRecord($1); freeRecord($3);
        } else {
            char *s = cat("(", $1->code, " + ", $3->code, ")");
            const char *res_type = (strcmp($1->opt1, "Float") == 0 || strcmp($3->opt1, "Float") == 0) ? "Float" : "Int";
            $$ = createRecord(s, strdup(res_type));
            free(s); freeRecord($1); freeRecord($3);
        }
    }
    | expression MINUS expression {
        char *s = cat("(", $1->code, " - ", $3->code, ")");
        const char *res_type = (strcmp($1->opt1, "Float") == 0 || strcmp($3->opt1, "Float") == 0) ? "Float" : "Int";
        $$ = createRecord(s, strdup(res_type));
        free(s); freeRecord($1); freeRecord($3);
    }
    | expression MUL expression {
        char *s = cat("(", $1->code, " * ", $3->code, ")");
        const char *res_type = (strcmp($1->opt1, "Float") == 0 || strcmp($3->opt1, "Float") == 0) ? "Float" : "Int";
        $$ = createRecord(s, strdup(res_type));
        free(s); freeRecord($1); freeRecord($3);
    }
    | expression DIV expression {
        char *s = cat("(", $1->code, " / ", $3->code, ")");
        $$ = createRecord(s, "Float");
        free(s); freeRecord($1); freeRecord($3);
    }
    | expression LT expression {
        char *s = cat("(", $1->code, " < ", $3->code, ")");
        $$ = createRecord(s, "Int"); free(s);
        freeRecord($1); freeRecord($3);
    }
    | expression GT expression {
        char *s = cat("(", $1->code, " > ", $3->code, ")");
        $$ = createRecord(s, "Int"); free(s);
        freeRecord($1); freeRecord($3);
    }
    | expression LE expression {
        char *s = cat("(", $1->code, " <= ", $3->code, ")");
        $$ = createRecord(s, "Int"); free(s);
        freeRecord($1); freeRecord($3);
    }
    | expression GE expression {
        char *s = cat("(", $1->code, " >= ", $3->code, ")");
        $$ = createRecord(s, "Int"); free(s);
        freeRecord($1); freeRecord($3);
    }
    | expression EQ expression {
        char *s = cat("(", $1->code, " == ", $3->code, ")");
        $$ = createRecord(s, "Int"); free(s);
        freeRecord($1); freeRecord($3);
    }
    | expression NE expression {
        char *s = cat("(", $1->code, " != ", $3->code, ")");
        $$ = createRecord(s, "Int"); free(s);
        freeRecord($1); freeRecord($3);
    }
    | expression AND expression {
        char *s = cat("(", $1->code, " && ", $3->code, ")");
        $$ = createRecord(s, "Int"); free(s);
        freeRecord($1); freeRecord($3);
    }
    | expression OR expression {
        char *s = cat("(", $1->code, " || ", $3->code, ")");
        $$ = createRecord(s, "Int"); free(s);
        freeRecord($1); freeRecord($3);
    }
    | NOT expression {
        char *s = cat("!(", $2->code, ")", "", "");
        $$ = createRecord(s, "Int"); free(s);
        freeRecord($2);
    }
    | expression PLUSPLUS {
        char *s = cat($1->code, "++", "", "", "");
        $$ = createRecord(s, $1->opt1); free(s);
        freeRecord($1);
    }
    | expression MINUSMINUS {
        char *s = cat($1->code, "--", "", "", "");
        $$ = createRecord(s, $1->opt1); free(s);
        freeRecord($1);
    }
    | expression ASSIGN expression {
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
        char *s = cat($1, "(", $3->code, ")", "");
        $$ = createRecord(s, "Unit");
        free(s); free($1); freeRecord($3);
    }
    | expression DOT ID
    | expression DOT ID LPAREN argument_list RPAREN
    | expression LBRACKET expression RBRACKET
    | list_literal
    | NEW simple_type LPAREN argument_list RPAREN { $$ = createRecord("", ""); }
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