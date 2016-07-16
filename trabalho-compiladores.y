%{
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <map>
#include <vector>

using namespace std;

struct Tipo {
  string nome;  // O nome na sua linguagem
  string decl;  // A declaração correspondente em c-assembly
  string fmt;   // O formato para "printf"
};

Tipo Integer = { "integer", "int", "d" };
Tipo Float =   { "float", "float", "f" };
Tipo Double =  { "double", "double", "lf" };
Tipo Boolean = { "boolean", "int", "d" };
Tipo String =  { "string", "char[256]", "s" };
Tipo Char =    { "char", "char", "c" };

struct Atributo {
  string v, c;
  Tipo t;
  vector<string> lst;
}; 

#define YYSTYPE Atributo

int yylex();
int yyparse();
void yyerror(const char *);
void erro( string );

map<string,Tipo> ts;
map< string, map< string, Tipo > > tro; // tipo_resultado_operacao;

ostream& operator << ( ostream& o, const vector<string>& st ) {
  cout << "[ ";
  for( vector<string>::const_iterator itr = st.begin();
       itr != st.end(); ++itr )
    cout << *itr << " "; 
       
  cout << "]";
  return o;     
}


// 'Atributo&': o '&' siginifica passar por referência (modifica).
void declara_variavel( Atributo& ss, 
                       const Atributo& s1, const Atributo& s2, int tipo ) {
  ss.c = "";
  for( int i = 0; i < s2.lst.size(); i++ ) {
    if( ts.find( s2.lst[i] ) != ts.end() ) 
      erro( "Variável já declarada: " + s2.lst[i] );
    else {
      ts[ s2.lst[i] ] = s1.t;
      if (tipo == 1)
          ss.c += s1.t.decl + " " + s2.lst[i] + ";\n"; 
      else
          ss.c += s1.t.decl + " " + s2.lst[i];
    }  
  }
}

void busca_tipo_da_variavel( Atributo& ss, const Atributo& s1 ) {
  if( ts.find( s1.v ) == ts.end() )
        erro( "Variável não declarada: " + s1.v );
  else {
    ss.t = ts[ s1.v ];
    ss.v = s1.v;
  }
}

void gera_codigo_atribuicao( Atributo& ss, 
                             const Atributo& s1, 
                             const Atributo& s3 ) {
  if( s1.t.nome == s3.t.nome || 
      (s1.t.nome == Float.nome && s3.t.nome == Integer.nome ) ) {
    ss.c = s1.c + s3.c + "  " + s1.v + " = " + s3.v + ";\n";
  }
}

string par( Tipo a, Tipo b ) {
  return a.nome + "," + b.nome;  
}

void gera_codigo_operador( Atributo& ss, 
                           const Atributo& s1, 
                           const Atributo& s2, 
                           const Atributo& s3 ) {
  if( tro.find( s2.v ) != tro.end() ) {
    if( tro[s2.v].find( par( s1.t, s3.t ) ) != tro[s2.v].end() ) {
      ss.v = "t1"; // Precisa gerar um nome de variável temporária.
      ss.t =  tro[s2.v][par( s1.t, s3.t )];
      ss.c = s1.c + s3.c + "  " + ss.v + " = " + s1.v + s2.v + s3.v + ";\n";
    }
    else
      erro( "O operador '" + s2.v + "' não está definido para os tipos " + s1.t.nome + " e " + s3.t.nome + "." );
  }
  else
    erro( "Operador '" + s2.v + "' não definido." );
}

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
  { cout << $1.c << $2.c << $3.c << endl; }
  ;
   
NAME : _PROGRAM _ID ';' 
       { $$.c = "#include <stdlib.h>\n"
                "#include <stdio.h>\n\n";
       }              
     ;   
BODY_BLOCK : BODY_ELEMENT BODY_BLOCK { $$.c = $1.c + $2.c; }
       | { $$.c = ""; }
       ;
       
BODY_ELEMENT : GLOBAL_BLOCK 
      | FUNCTION 
      ;

GLOBAL_BLOCK : _GLOBALS '{' DECLARATIONS '}' { $$.c = $3.c + "\n"; }
			 | _GLOBAL DECLARATION ';' { $$ = $2; }
	   		 ;

LOCAL_BLOCK : _LOCALS '{' DECLARATIONS '}' {$$.c = $3.c;}
			| _LOCAL DECLARATION ';' {$$.c = $2.c;}
			;

FUNCTION : _ID PARAMETERS ':' TYPE BLOCK { $$.c = $4.t.decl + " " + $1.v + "(" + $2.c + ")" + $5.c + "\n"; }
		 | _ID PARAMETERS ':' BLOCK
		 | _ID ':' TYPE BLOCK
		 | _ID ':' BLOCK

PARAMETERS : PARAMETER ',' PARAMETERS {$$.c = $1.c + ", " + $3.c;}
		   | PARAMETER
		   ;
		   
PARAMETER : TYPE IDS { declara_variavel( $$, $1, $2, 2 ); } 
		  | TYPE CMD_ATTRIBUTION {$$.c = $1.c + $2.c;}
		  ;

DECLARATIONS : DECLARATION ';' DECLARATIONS {$$.c = $1.c + $3.c;}
			 | DECLARATION ';'
			 ;

DECLARATION : TYPE IDS { declara_variavel( $$, $1, $2, 1 ); } 
			| TYPE CMD_ATTRIBUTION {$$.c = $1.c + $2.c;}
			;

TYPE : _STRING  { $$.t = String; }
	 | _INTEGER { $$.t = Integer; }
	 ;

IDS : _ID { $$.lst.push_back( $1.v ); } //Quando usamos mais de um ID (regra comentada abaixo), ficamos com mais um conflito de shift/reduce
    ;  

/*
IDS : _ID ',' IDS { $$.lst = $1.lst; $$.lst.push_back( $3.v ); }
    | _ID         { $$.lst.push_back( $1.v ); }
    ;  
*/
MAIN : _MAIN ':' '{' CMDS '}'
            { $$.c = "int main() {\n" + $4.c + "}\n"; }

BLOCK : '{' CMDS '}' { $$.c = "\n{\n" + $2.c + "\n}\n";}
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
        { $$.c = "  printf( \"%"+ $3.t.fmt + "\", " + $3.v + " );\n"; }
      | _WRITELN '(' EXPRESSION ')'
        { $$.c = "  printf( \"%"+ $3.t.fmt + "\\n\", " + $3.v + " );\n"; }
      ;

EXPRESSION : EXPRESSION '+' EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		   | EXPRESSION '-' EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		   | EXPRESSION '*' EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		   | EXPRESSION '/' EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		   | EXPRESSION '>' EXPRESSION { $$.c = $1.v + '>' + $3.v; }
		   | EXPRESSION '<' EXPRESSION { $$.c = $1.v + '<' + $3.v; }
		   | F { $$ = $1; }
		   ; 

F : _ID          { busca_tipo_da_variavel( $$, $1 ); }
  | _CTE_STRING  { $$ = $1; $$.t = String; }
  | _CTE_INTEGER { $$ = $1; $$.t = Integer; }
  | '(' EXPRESSION ')'    { $$ = $2; }
  ;

CMD_ATTRIBUTION : LVALUE _ATRIB EXPRESSION { gera_codigo_atribuicao( $$, $1, $3 ); }
				;
            
LVALUE : _ID { busca_tipo_da_variavel( $$, $1 ); }
       ; 

CMD_RETURN : _RETURN EXPRESSION { $$.c = "return " + $2.v + ";";}
	   	   ;

CMD_IF : _IF EXPRESSION ':' BLOCK {$$.c = "  if(" + $2.c + ")\n" + $4.c;}
	   | _IF EXPRESSION ':' BLOCK _ELSE BLOCK {$$.c = "  if(" + $2.c + ")\n" + $4.c + "\n  else\n" + $6.c;}
	   ;

CMD_WHILE : _WHILE EXPRESSION ':' BLOCK
		  ;

CMD_FOR : _FOR DECLARATION ',' EXPRESSION ',' CMD_ATTRIBUTION ':' BLOCK
		;

%%

#include "lex.yy.c"


void erro( string st ) {
  yyerror( st.c_str() );
  exit( 1 );
}

void yyerror( const char* st )
{
   if( strlen( yytext ) == 0 )
     printf( "%s\nNo final do arquivo\n", st );
   else  
     printf( "%s\nProximo a: %s\nlinha/coluna: %d/%d\n", st, 
              yytext, yylineno, yyrowno - (int) strlen( yytext ) );
}

void inicializa_tabela_de_resultado_de_operacoes() {
  map< string, Tipo > r;
  
  // OBS: a ordem é muito importante!!  
  r[par(Integer, Integer)] = Integer;    
  r[par(Integer, Float)] = Float;    
  r[par(Integer, Double)] = Double;    
  r[par(Float, Integer)] = Float;    
  r[par(Float, Float)] = Float;    
  r[par(Float, Double)] = Double;    
  r[par(Double, Integer)] = Double;    
  r[par(Double, Float)] = Double;    
  r[par(Double, Double)] = Double;    

  tro[ "-" ] = r; 
  tro[ "*" ] = r; 
  tro[ "/" ] = r; 

  r[par(Char, Char)] = String;      
  r[par(String, Char)] = String;      
  r[par(Char, String)] = String;    
  r[par(String, String)] = String;    
  tro[ "+" ] = r; 
  
  r.erase(r.begin(),r.end());
  
  r[par(Integer, Integer)] = Boolean;    
  r[par(Integer, Float)] = Boolean;    
  r[par(Integer, Double)] = Boolean;    
  r[par(Float, Integer)] = Boolean;    
  r[par(Float, Float)] = Boolean;    
  r[par(Float, Double)] = Boolean;    
  r[par(Double, Integer)] = Boolean;    
  r[par(Double, Float)] = Boolean;    
  r[par(Double, Double)] = Boolean;    
  r[par(Boolean, Boolean)] = Boolean;
  
  tro[ "<" ] = r; 
  
}

int main( int argc, char* argv[] )
{
  inicializa_tabela_de_resultado_de_operacoes();
  yyparse();
}
