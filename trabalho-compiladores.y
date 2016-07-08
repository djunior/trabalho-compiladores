%{
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>

using namespace std;

#define YYSTYPE string

int yylex();
int yyparse();
void yyerror(const char *);

%}

%token _ID _PROGRAM _WRITELN _WRITE _VAR _IF _ELSE _WHILE
%token _FOR _ATRIB _RETURN _FUNCTION _GLOBAL _GLOBALS _LOCAL _LOCALS
%token _INTEGER _STRING

%token _CTE_STRING _CTE_INTEGER

%nonassoc '>' '<' '='
%left '+' '-'
%left '*' '/'

%start S

%%

S : NAME BODY_BLOCK { cout << "Aceito" << endl; }

NAME: _PROGRAM _ID ';'

BODY_BLOCK : BODY_ELEMENT BODY_BLOCK 
		   | 
		   ;

BODY_ELEMENT : FUNCTION
			 | GLOBAL_BLOCK
			 | LOCAL_BLOCK
			 ;

GLOBAL_BLOCK : _GLOBALS '{' DECLARATIONS '}'
			 | _GLOBAL DECLARATION ';'
	   		 ;

LOCAL_BLOCK : _LOCALS '{' DECLARATIONS '}'
			| _LOCAL DECLARATION ';'
			;

FUNCTION : _ID PARAMETERS ':' TYPE BLOCK
		 | _ID PARAMETERS ':' BLOCK
		 | _ID ':' TYPE BLOCK
		 | _ID ':' BLOCK

PARAMETERS : DECLARATION ',' PARAMETERS
		   | DECLARATION
		   ;

DECLARATIONS : DECLARATION ';' DECLARATIONS
			 | 
			 ;

DECLARATION : TYPE _ID
			| TYPE CMD_ATTRIBUTION
			;

TYPE : _STRING
	 | _INTEGER
	 ;

BLOCK : '{' CMDS '}'
	  | CMD
	  ;

CMDS : CMD CMDS
	 |
	 ;

CMD : CMD_ATTRIBUTION ';'
	| CMD_RETURN ';'
	| CMD_IF
	| CMD_WHILE
	| CMD_FOR
	| LOCAL_BLOCK
	| GLOBAL_BLOCK
	;

EXPRESSION : EXPRESSION '+' EXPRESSION
		   | EXPRESSION '-' EXPRESSION
		   | EXPRESSION '*' EXPRESSION
		   | EXPRESSION '/' EXPRESSION
		   | EXPRESSION '>' EXPRESSION
		   | EXPRESSION '<' EXPRESSION
		   | F
		   ;

F : _ID
  | _CTE_STRING
  | _CTE_INTEGER
  ;

CMD_ATTRIBUTION : _ID _ATRIB EXPRESSION
				;

CMD_RETURN : _RETURN EXPRESSION
	   	   ;

CMD_IF : _IF EXPRESSION ':' BLOCK
	   | _IF EXPRESSION ':' BLOCK _ELSE BLOCK
	   ;

CMD_WHILE : _WHILE EXPRESSION ':' BLOCK
		  ;

CMD_FOR : _FOR DECLARATION ',' EXPRESSION ',' CMD_ATTRIBUTION ':' BLOCK
		;

%%

#include "lex.yy.c"

void yyerror( const char* st )
{
   if( strlen( yytext ) == 0 )
     printf( "%s\nNo final do arquivo\n", st );
   else  
     printf( "%s\nProximo a: %s\nlinha: %d\n", st, yytext, yylineno );
}

int main( int argc, char* argv[] )
{
  yyparse();
}