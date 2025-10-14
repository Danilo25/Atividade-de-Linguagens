%{
#include <stdio.h>
%}

%%
"se"            { printf("IF "); }
"fimSe"         { printf("ENDIF "); }
"senao"         { printf("ELSE "); }
"fimSenao"      { printf("ENDELSE "); }
"para"          { printf("FOR "); }
"fimPara"       { printf("ENDFOR "); }
"escolha"       { printf("SWITCH "); }
"enquanto"      { printf("WHILE "); }
"retorne"       { printf("RETURN "); }
"escreva"       { printf("PRINTF "); }
"leia"          { printf("SCANF "); }
"constante"     { printf("CONST "); }
"pare"          { printf("BREAK "); }
"continue"      { printf("CONTINUE "); }
"caso"          { printf("CASE "); }
"tente"         { printf("TRY "); }
"pegue"         { printf("CATCH "); }
"entao"         { printf("FINALLY "); }
"repita"        { printf("DO "); }
"ate"           { printf("UNTIL "); }
"funcao"        { printf("FUNCTION "); }
"fimFuncao"     { printf("ENDFUNCTION "); }
"estrutura"     { printf("STRUCT "); }
"fimEstrutura"  { printf("ENDSTRUCT "); }
"enumerado"     { printf("ENUM "); }

"Inteiro"       { printf("TYPE_INT "); }
"Real"          { printf("TYPE_FLOAT "); }
"Texto"         { printf("TYPE_STRING "); }
"Booleano"      { printf("TYPE_BOOL "); }
"Lista"         { printf("TYPE_LIST "); }
"Cadeia"        { printf("TYPE_STRING "); }
"Int"           { printf("TYPE_INT "); }
"Flut"          { printf("TYPE_FLOAT "); }

"<-"            { printf("ASSIGN "); }
"=="            { printf("EQ "); }
"!="            { printf("NE "); }
"<="            { printf("LE "); }
">="            { printf("GE "); }
"<"             { printf("LT "); }
">"             { printf("GT "); }
"&&"            { printf("AND "); }
"||"            { printf("OR "); }
"!"             { printf("NOT "); }
"+="            { printf("PLUS_ASSIGN "); }
"-="            { printf("MINUS_ASSIGN "); }
"*="            { printf("MUL_ASSIGN "); }
"/="            { printf("DIV_ASSIGN "); }

";"             { printf("SEMICOLON "); }
","             { printf("COMMA "); }
"("             { printf("LPAREN "); }
")"             { printf("RPAREN "); }
"{"             { printf("LBRACE "); }
"}"             { printf("RBRACE "); }
"["             { printf("LBRACKET "); }
"]"             { printf("RBRACKET "); }
"."             { printf("DOT "); }

[a-zA-Z_][a-zA-Z0-9_]*  { printf("ID(%s) ", yytext); }
[0-9]+\.[0-9]+              { printf("FLOAT_LIT(%s) ", yytext); }
[0-9]+                      { printf("INT_LIT(%s) ", yytext); }
\"(\\.|[^"\\])*\"       { printf("STRING_LIT(%s) ", yytext); }

[ \t\r\n]+                  { /* Ignora espaços em branco */ }
\/\/.* { /* Ignora comentários de linha única */ }

.                           { printf("UNKNOWN(%s) ", yytext); }

%%

int main(int argc, char **argv) {
    yylex();
    return 0;
}