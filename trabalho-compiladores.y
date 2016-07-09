%{
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>

using namespace std;

struct Atributos{
string c, t, v;
};

#define YYSTYPE Atributos

int yylex();
int yyparse();
void yyerror(const char *);

%}

%token _ID _PROGRAM _MAIN _WRITELN _WRITE _VAR _IF _ELSE _WHILE
%token _FOR _ATRIB _RETURN _FUNCTION _GLOBAL _GLOBALS _LOCAL _LOCALS
%token _INTEGER _STRING

%token _CTE_STRING _CTE_INTEGER

%nonassoc '>' '<' '='
%left '+' '-'
%left '*' '/'

%start S

%%

S : NAME BODY_BLOCK MAIN 
  { cout << $1.c << $3.c << endl; }
  ;
   
NAME : _PROGRAM _ID ';' 
       { $$.c = "#include <stdlib.h>\n"
                "#include <stdio.h>\n\n";
       }              
     ;   
BODY_BLOCK : BODY_ELEMENT BODY_BLOCK 
         { $$.c = $1.c + $2.c; }
       | { $$.c = ""; }
       ;
       
BODY_ELEMENT : GLOBAL_BLOCK 
      | FUNCTION 
      ;

GLOBAL_BLOCK : _GLOBALS '{' DECLARATIONS '}' {$$.c = $3.c;}
			 | _GLOBAL DECLARATION ';' {$$ = $2;}
	   		 ;

LOCAL_BLOCK : _LOCALS '{' DECLARATIONS '}'
			| _LOCAL DECLARATION ';' {$$.c = $2.c + ";\n";}
			;

FUNCTION : _ID PARAMETERS ':' TYPE BLOCK
		 | _ID PARAMETERS ':' BLOCK
		 | _ID ':' TYPE BLOCK
		 | _ID ':' BLOCK

PARAMETERS : DECLARATION ',' PARAMETERS
		   | DECLARATION
		   ;

DECLARATIONS : DECLARATION ';' DECLARATIONS {$$.c = $1.c +";\n" + $3.c;}
			 | {$$.c = "";}
			 ;

DECLARATION : TYPE _ID {$$.c = $1.c + " " + $2.v;}
			| TYPE CMD_ATTRIBUTION {$$.c = $1.c + $2.c;}
			;

TYPE : _STRING {$$.c = "string ";}
	 | _INTEGER {$$.c = "int ";}
	 ;

MAIN : _MAIN ':' '{' CMDS '}'
            { $$.c = "int main() {\n" + $4.c + "}\n"; }

BLOCK : '{' CMDS '}'
	  | CMD
	  ;

CMDS : CMD CMDS { $$.c = $1.c + $2.c; }
	 | { $$.c = ""; }
	 ;

CMD : CMD_ATTRIBUTION ';' {$$ = $1; }
	| CMD_RETURN ';'
	| CMD_IF
	| CMD_WHILE
	| CMD_FOR
	| PRINT ';'
	| LOCAL_BLOCK
	| GLOBAL_BLOCK
	;

PRINT : _WRITE '(' EXPRESSION ')'
        { $$.c = "  printf( \"%"+ $3.t + "\", " + $3.v + " );\n"; }
      | _WRITELN '(' EXPRESSION ')'
        { $$.c = "  printf( \"%"+ $3.t + "\\n\", " + $3.v + " );\n"; }
      ;

EXPRESSION : EXPRESSION '+' EXPRESSION {$$.c = $1.v + '+' + $3.v;}
		   | EXPRESSION '-' EXPRESSION {$$.c = $1.v + '-' + $3.v;}
		   | EXPRESSION '*' EXPRESSION {$$.c = $1.v + '*' + $3.v;}
		   | EXPRESSION '/' EXPRESSION {$$.c = $1.v + '/' + $3.v;}
		   | EXPRESSION '>' EXPRESSION {$$.c = $1.v + '>' + $3.v;}
		   | EXPRESSION '<' EXPRESSION {$$.c = $1.v + '<' + $3.v;}
		   | F { $$ = $1; }
		   ; 

F : _ID {$$ = $1; $$.t = "s";}
  | _CTE_STRING { $$ = $1; $$.t = "s"; }
  | _CTE_INTEGER { $$ = $1; $$.t = "d"; }
  ;

CMD_ATTRIBUTION : _ID _ATRIB EXPRESSION {$$.c = $1.v + " " + $2.v + " " + $3.v;}
				;

CMD_RETURN : _RETURN EXPRESSION
	   	   ;

CMD_IF : _IF EXPRESSION ':' BLOCK {$$.c = "  if(" + $2.c + ")\n" + $4.c;}
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
