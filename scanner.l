%{
#include <stdio.h>
#include <string.h>
#include "parser.tab.h"
%}

%%

"se"            { return IF; }
"fimSe"         { return ENDIF; }
"senao"         { return ELSE; }
"para"          { return FOR; }
"fimPara"       { return ENDFOR; }
"escolha"       { return SWITCH; }
"enquanto"      { return WHILE; }
"fimEnquanto"   { return ENDWHILE; }
"retorne"       { return RETURN; }
"escreva"       { return PRINTF; }
"leia"          { return SCANF; }
"constante"     { return CONST; }
"pare"          { return BREAK; }
"continue"      { return CONTINUE; }
"caso"          { return CASE; }
"tente"         { return TRY; }
"pegue"         { return CATCH; }
"entao"         { return FINALLY; }
"repita"        { return DO; }
"ate"           { return UNTIL; }
"funcao"        { return FUNCTION; }
"fimFuncao"     { return ENDFUNCTION; }
"estrutura"     { return STRUCT; }
"fimEstrutura"  { return ENDSTRUCT; }
"enumerado"     { return ENUM; }

"Inteiro"       { return TYPE_INT; }
"Real"          { return TYPE_FLOAT; }
"Texto"         { return TYPE_STRING; }
"Booleano"      { return TYPE_BOOL; }
"Lista"         { return TYPE_LIST; }
"Cadeia"        { return TYPE_STRING; }
"Int"           { return TYPE_INT; }
"Flut"          { return TYPE_FLOAT; }

"<-"            { return ASSIGN; }
"=="            { return EQ; }
"!="            { return NE; }
"<="            { return LE; }
">="            { return GE; }
"<"             { return LT; }
">"             { return GT; }
"&&"            { return AND; }
"||"            { return OR; }
"!"             { return NOT; }

"+="            { return PLUS_ASSIGN; }
"-="            { return MINUS_ASSIGN; }
"*="            { return MUL_ASSIGN; }
"/="            { return DIV_ASSIGN; }

"++"            { return PLUSPLUS; }
"--"            { return MINUSMINUS; }
"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MUL; }
"/"             { return DIV; }


";"             { return SEMICOLON; }
","             { return COMMA; }
"("             { return LPAREN; }
")"             { return RPAREN; }
"{"             { return LBRACE; }
"}"             { return RBRACE; }
"["             { return LBRACKET; }
"]"             { return RBRACKET; }
"."             { return DOT; }

[a-zA-Z_][a-zA-Z0-9_]* { 
    yylval.sval = strdup(yytext); 
    return ID; 
}
[0-9]+\.[0-9]+              { 
    yylval.sval = strdup(yytext); 
    return FLOAT_LIT; 
}
[0-9]+                      { 
    yylval.sval = strdup(yytext); 
    return INT_LIT; 
}
\"(\\.|[^"\\])*\"       { 
    /* Remove as aspas do literal de string */
    char *str = strdup(yytext + 1);
    str[strlen(str) - 1] = '\0';
    yylval.sval = str;
    return STRING_LIT; 
}

[ \t\r]+                  { /* Ignora espaços em branco */ }
\n    { yylineno += 1; }
\/\/.* { /* Ignora comentários de linha única */ }

.                           { printf("CARACTERE DESCONHECIDO: %s\n", yytext); }

%%

int yywrap() {
    return 1;
}