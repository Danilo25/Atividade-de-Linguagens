%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"
int error_count = 0;
%}
%option yylineno
%option noyywrap
%x COMMENT
%%
"se"             { return IF; }
"fimSe"          { return ENDIF; }
"senao"          { return ELSE; }
"para"           { return FOR; }
"fimPara"        { return ENDFOR; }
"escolha"        { return SWITCH; }
"fimEscolha"     { return ENDSWITCH; }
"enquanto"       { return WHILE; }
"fimEnquanto"    { return ENDWHILE; }
"retorne"        { return RETURN; }
"escreva"        { return PRINTF; }
"leia"           { return SCANF; }
"constante"      { return CONST; }
"pare"           { return BREAK; }
"continue"       { return CONTINUE; }
"caso"           { return CASE; }
"casoPadrao"     { return DEFAULTCASE; }
"tente"          { return TRY; }
"pegue"          { return CATCH; }
"entao"          { return FINALLY; }
"repita"         { return DO; }
"ate"            { return UNTIL; }
"funcao"         { return FUNCTION; }
"fimFuncao"      { return ENDFUNCTION; }
"estrutura"      { return STRUCT; }
"fimEstrutura"   { return ENDSTRUCT; }
"enumerado"      { return ENUM; }
"Inteiro"        { return TYPE_INT; }
"Real"           { return TYPE_FLOAT; }
"Texto"          { return TYPE_STRING; }
"Booleano"       { return TYPE_BOOL; }
"Lista"          { return TYPE_LIST; }
"Cadeia"         { return TYPE_STRING; }
"Int"            { return TYPE_INT; }
"Flut"           { return TYPE_FLOAT; }
"ref"            { return REF; }
"novo"           { return NEW; }
"nulo"           { return NULO; }
"<-"             { return ASSIGN; }
"=="             { return EQ; }
"!="             { return NE; }
"<="             { return LE; }
">="             { return GE; }
"<"              { return LT; }
">"              { return GT; }
"&&"             { return AND; }
"||"             { return OR; }
"!"              { return NOT; }
"+="             { return PLUS_ASSIGN; }
"-="             { return MINUS_ASSIGN; }
"*="             { return MUL_ASSIGN; }
"/="             { return DIV_ASSIGN; }
"++"             { return PLUSPLUS; }
"--"             { return MINUSMINUS; }
"+"              { return PLUS; }
"-"              { return MINUS; }
"*"              { return MUL; }
"/"              { return DIV; }
";"              { return SEMICOLON; }
":"              { return COLON; }
","              { return COMMA; }
"("              { return LPAREN; }
")"              { return RPAREN; }
"{"              { return LBRACE; }
"}"              { return RBRACE; }
"["              { return LBRACKET; }
"]"              { return RBRACKET; }
"."              { return DOT; }
[a-zA-Z_][a-zA-Z0-9_]* { 
    yylval.str_val = strdup(yytext); 
    return ID;
}
[0-9]+\.[0-9]+ { 
    yylval.float_val = atof(yytext); 
    return FLOAT_LIT; 
}
[0-9]+ { 
    yylval.int_val = atoi(yytext);
    return INT_LIT; 
}
\"(\\.|[^"\\])*\" { 
    char *str = strdup(yytext + 1);
    str[strlen(str) - 1] = '\0';
    yylval.str_val = str;
    return STRING_LIT; 
}
[ \t\r\n]+ { }
"//".* { }
"/*"           { BEGIN(COMMENT); }
<COMMENT>"*/"  { BEGIN(INITIAL); }
<COMMENT>.     { }
<COMMENT>\n    { }
\"(\\.|[^"\\])*$ { 
    fprintf(stderr, "ERRO LÉXICO: string não terminada na linha %d\n", yylineno); 
    error_count++;
    exit(1); 
}
[0-9]+[a-zA-Z_]+ { 
    fprintf(stderr, "ERRO LÉXICO: identificador inválido '%s' na linha %d (não pode começar com número)\n", yytext, yylineno); 
    error_count++;
    exit(1); 
}
. { 
    fprintf(stderr, "ERRO LÉXICO: Caractere inválido '%s' na linha %d\n", yytext, yylineno); 
    error_count++;
    exit(1);
}
%%
int get_lex_error_count() {
    return error_count;
}