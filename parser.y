%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex(void);
extern char *yytext;
extern int yylineno;
extern int get_lex_error_count();

void yyerror(const char *s);

int syntax_error_count = 0;
%}

%union {
    int int_val;
    double float_val;
    char *str_val;
}

%token <str_val> ID
%token <int_val> INT_LIT
%token <float_val> FLOAT_LIT
%token <str_val> STRING_LIT

%token IF ENDIF ELSE FOR ENDFOR SWITCH ENDSWITCH WHILE ENDWHILE
%token RETURN PRINTF SCANF CONST BREAK CONTINUE CASE DEFAULTCASE TRY CATCH FINALLY
%token DO UNTIL FUNCTION ENDFUNCTION STRUCT ENDSTRUCT ENUM
%token TYPE_INT TYPE_FLOAT TYPE_STRING TYPE_BOOL TYPE_LIST

%token ASSIGN EQ NE LE GE LT GT
%token AND OR NOT
%token PLUS_ASSIGN MINUS_ASSIGN MUL_ASSIGN DIV_ASSIGN

%token PLUS MINUS MUL DIV PLUSPLUS MINUSMINUS

%token SEMICOLON COLON COMMA LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET DOT

%right ASSIGN PLUS_ASSIGN MINUS_ASSIGN MUL_ASSIGN DIV_ASSIGN
%left OR
%left AND
%left EQ NE
%left LT LE GT GE
%left PLUS MINUS
%left MUL DIV
%right NOT PLUSPLUS MINUSMINUS
%left DOT
%left LPAREN RPAREN LBRACKET RBRACKET

%%

program:
    declaration_list
    ;

declaration_list:
    | declaration_list function_definition
    | declaration_list struct_definition
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
    ENDFUNCTION
    ;

parameter_list:
    | param_list_non_empty
    ;

param_list_non_empty:
    parameter
    | param_list_non_empty COMMA parameter
    ;

parameter:
    type ID
    ;

type:
    simple_type
    | TYPE_LIST LT type GT
    ;

simple_type:
    TYPE_INT
    | TYPE_FLOAT
    | TYPE_STRING
    | TYPE_BOOL
    | ID
    ;

brace_block:
    LBRACE statement_list RBRACE
    ;

statement_list:
    | statement_list statement
    ;

statement:
    expression_statement
    | declaration_statement
    | do_statement
    | if_statement
    | switch_statement
    | while_statement
    | for_statement
    | return_statement
    | print_statement
    | brace_block
    | SEMICOLON
    ;

declaration_statement:
    type ID SEMICOLON
    | type ID ASSIGN expression SEMICOLON
    ;

expression_statement:
    expression SEMICOLON
    ;

do_statement:
    DO DOT 
    | statement_list 
    UNTIL LPAREN expression RPAREN SEMICOLON
    |
    ;

if_statement:
    IF LPAREN expression RPAREN statement_list ENDIF
    | IF LPAREN expression RPAREN statement_list ELSE statement_list ENDIF
    ;

case_item:
    CASE expression COLON
        statement_list
    ;
    
default_case:
    DEFAULTCASE COLON
        statement_list
    ;

case_list:
    case_item
    | case_list case_item
    ;

switch_statement:
    SWITCH LPAREN expression RPAREN case_list ENDSWITCH
    | SWITCH LPAREN expression RPAREN case_list default_case ENDSWITCH
    ;

while_statement:
    WHILE LPAREN expression RPAREN statement_list ENDWHILE
    ;

for_statement:
    FOR LPAREN for_init SEMICOLON expression SEMICOLON expression RPAREN
        statement_list
    ENDFOR
    ;

for_init:
    type ID ASSIGN expression
    | expression
    ;

return_statement:
    RETURN expression SEMICOLON
    ;

print_statement:
    PRINTF LPAREN expression RPAREN SEMICOLON
    ;

expression:
    INT_LIT
    | FLOAT_LIT
    | STRING_LIT
    | ID
    | expression PLUS expression
    | expression MINUS expression
    | expression MUL expression
    | expression DIV expression
    | expression LT expression
    | expression GT expression
    | expression LE expression
    | expression GE expression
    | expression EQ expression
    | expression NE expression
    | expression AND expression
    | expression OR expression
    | NOT expression
    | expression PLUSPLUS
    | expression MINUSMINUS
    | expression ASSIGN expression
    | expression PLUS_ASSIGN expression
    | expression MINUS_ASSIGN expression
    | expression MUL_ASSIGN expression
    | expression DIV_ASSIGN expression
    | LPAREN expression RPAREN
    | ID LPAREN argument_list RPAREN
    | expression DOT ID
    | expression DOT ID LPAREN argument_list RPAREN
    | expression LBRACKET expression RBRACKET
    | list_literal
    ;

list_literal:
    LBRACKET RBRACKET
    | LBRACKET expression_list RBRACKET
    ;

argument_list:
    | expression_list
    ;

expression_list:
    expression
    | expression_list COMMA expression
    ;

%%

int main(int argc, char **argv) {
    int parse_result = yyparse();
    int lex_errors = get_lex_error_count();

    if (parse_result == 0 && lex_errors == 0 && syntax_error_count == 0) {
        printf("Parsing concluído com sucesso!\n");
        return 0;
    } else {
        fprintf(stderr, "Parsing falhou.\n");
        return 1;
    }
}

void yyerror(const char *s) {
    fprintf(stderr, "Erro de Sintaxe na linha %d: %s (perto de '%s')\n", yylineno, s, yytext);
    syntax_error_count++;
}