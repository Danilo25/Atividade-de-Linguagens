/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_YY_PARSER_TAB_H_INCLUDED
# define YY_YY_PARSER_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    ID = 258,                      /* ID  */
    INT_LIT = 259,                 /* INT_LIT  */
    FLOAT_LIT = 260,               /* FLOAT_LIT  */
    STRING_LIT = 261,              /* STRING_LIT  */
    IF = 262,                      /* IF  */
    ENDIF = 263,                   /* ENDIF  */
    ELSE = 264,                    /* ELSE  */
    FOR = 265,                     /* FOR  */
    ENDFOR = 266,                  /* ENDFOR  */
    SWITCH = 267,                  /* SWITCH  */
    WHILE = 268,                   /* WHILE  */
    ENDWHILE = 269,                /* ENDWHILE  */
    RETURN = 270,                  /* RETURN  */
    PRINTF = 271,                  /* PRINTF  */
    SCANF = 272,                   /* SCANF  */
    CONST = 273,                   /* CONST  */
    BREAK = 274,                   /* BREAK  */
    CONTINUE = 275,                /* CONTINUE  */
    CASE = 276,                    /* CASE  */
    TRY = 277,                     /* TRY  */
    CATCH = 278,                   /* CATCH  */
    FINALLY = 279,                 /* FINALLY  */
    DO = 280,                      /* DO  */
    UNTIL = 281,                   /* UNTIL  */
    FUNCTION = 282,                /* FUNCTION  */
    ENDFUNCTION = 283,             /* ENDFUNCTION  */
    STRUCT = 284,                  /* STRUCT  */
    ENDSTRUCT = 285,               /* ENDSTRUCT  */
    ENUM = 286,                    /* ENUM  */
    TYPE_INT = 287,                /* TYPE_INT  */
    TYPE_FLOAT = 288,              /* TYPE_FLOAT  */
    TYPE_STRING = 289,             /* TYPE_STRING  */
    TYPE_BOOL = 290,               /* TYPE_BOOL  */
    TYPE_LIST = 291,               /* TYPE_LIST  */
    ASSIGN = 292,                  /* ASSIGN  */
    EQ = 293,                      /* EQ  */
    NE = 294,                      /* NE  */
    LE = 295,                      /* LE  */
    GE = 296,                      /* GE  */
    LT = 297,                      /* LT  */
    GT = 298,                      /* GT  */
    AND = 299,                     /* AND  */
    OR = 300,                      /* OR  */
    NOT = 301,                     /* NOT  */
    PLUS_ASSIGN = 302,             /* PLUS_ASSIGN  */
    MINUS_ASSIGN = 303,            /* MINUS_ASSIGN  */
    MUL_ASSIGN = 304,              /* MUL_ASSIGN  */
    DIV_ASSIGN = 305,              /* DIV_ASSIGN  */
    PLUS = 306,                    /* PLUS  */
    MINUS = 307,                   /* MINUS  */
    MUL = 308,                     /* MUL  */
    DIV = 309,                     /* DIV  */
    PLUSPLUS = 310,                /* PLUSPLUS  */
    MINUSMINUS = 311,              /* MINUSMINUS  */
    SEMICOLON = 312,               /* SEMICOLON  */
    COMMA = 313,                   /* COMMA  */
    LPAREN = 314,                  /* LPAREN  */
    RPAREN = 315,                  /* RPAREN  */
    LBRACE = 316,                  /* LBRACE  */
    RBRACE = 317,                  /* RBRACE  */
    LBRACKET = 318,                /* LBRACKET  */
    RBRACKET = 319,                /* RBRACKET  */
    DOT = 320                      /* DOT  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 12 "parser.y"

    char *sval;

#line 133 "parser.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;


int yyparse (void);


#endif /* !YY_YY_PARSER_TAB_H_INCLUDED  */
