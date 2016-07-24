%{
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <map>
#include <vector>

//#define __DEBUG__

#ifdef __DEBUG__ 
#define DEBUG(x) x
#else
#define DEBUG(x)
#endif

using namespace std;

struct Range {
  int inicio, fim;
};

struct Tipo {
  string nome;  // O nome na sua linguagem
  string decl;  // A declaração correspondente em c-assembly
  string fmt;   // O formato para "printf"
  bool isParam;
  vector<Range> dim;
};

Tipo Integer = { "integer", "int", "d", false };
Tipo Float =   { "float", "float", "f", false };
Tipo Double =  { "double", "double", "lf", false };
Tipo Boolean = { "boolean", "int", "d", false };
Tipo String =  { "string", "char", "s", false };
Tipo Char =    { "char", "char", "c", false };

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

typedef map<string,Tipo> TabelaSimbolos;

map< string, map< string, Tipo > > tro; // tipo_resultado_operacao;
map<string,int> temp_global;
map< string, int > nlabel;

vector< TabelaSimbolos > symbol_table_stack;

ostream& operator << ( ostream& o, const vector<string>& st ) {
  o << "[ ";
  for( vector<string>::const_iterator itr = st.begin();
       itr != st.end(); ++itr )
    o << *itr << " "; 
       
  o << "]";
  return o;     
}

ostream& operator << ( ostream& o, const Tipo& st ) {
  o << "Tipo{";
  o << "nome = " << st.nome;
  o << ", decl = " << st.decl;
  o << ", fmt = " << st.fmt;
  o << "}";
  return o;     
}

ostream& operator << ( ostream& o, const Atributo& st ) {
  o << "Atributo{";
  o << "v = " << st.v;
  o << ", c = " << st.c;
  o << ", t = " << st.t;
  o << "}";
  return o;
}

ostream& operator << (ostream& o, const vector<TabelaSimbolos> stack) {
  o << "Pilha tabela de simbolos: ";
  for (int i = 0; i < stack.size(); i++) {
    o << "Tabela (" << i << ")";
  }
  return o;
}

string toString(int n) {
  char buff[256];
  sprintf(buff,"%d",n);
  return (string) buff;
}

string gera_nome_variavel(Tipo t, int n) {
  return "t_" + t.nome + "_" + toString(n);
}

string gera_nome_variavel(Tipo t) {
  return gera_nome_variavel(t,++temp_global[t.nome]);
}

string gera_nome_label( string cmd ) {
  return "L_" + cmd + "_" + toString( ++nlabel[cmd] );
}

string trata_dimensoes_decl_var( Tipo t ) {
  string aux;
  
  for( int i = 0; i < t.dim.size(); i++ )
    aux += "[" + toString( t.dim[i].fim - t.dim[i].inicio + 1 )+ "]";
           
  return aux;         
}

string declara_nvar_temp( Tipo t, int n) {
  string aux = "";
  for (int i = 0; i < n; i++) {
    aux = aux + t.decl + " " + gera_nome_variavel(t,i+1) + trata_dimensoes_decl_var( t ) + ";\n";
  }
  return aux;
}

string declara_var_temp ( map<string,int> &temp_map) {
  string decl = declara_nvar_temp(Integer, temp_map[Integer.nome]) + 
                declara_nvar_temp(String, temp_map[String.nome]) + 
                declara_nvar_temp(Boolean, temp_map[Boolean.nome]);
  temp_map.clear();
  return decl;
}

void gera_cmd_if( Atributo& ss, 
                  const Atributo& exp, 
                  const Atributo& cmd_then, 
                  const Atributo& cmd_else ) { 
  string lbl_then = gera_nome_label( "then" );
  string lbl_end_if = gera_nome_label( "end_if" );
  
  if( exp.t.nome != Boolean.nome )
    erro( "A expressão do IF deve ser booleana!" );
    
  ss.c = exp.c + 
         "\nif( " + exp.v + " ) goto " + lbl_then + ";\n" +
         cmd_else.c + "  goto " + lbl_end_if + ";\n\n" +
         lbl_then + ":;\n" + 
         cmd_then.c + "\n" +
         lbl_end_if + ":;\n"; 
}

void gera_cmd_for( Atributo& ss,
                  const Atributo& decl,
                  const Atributo& exp,
                  const Atributo& cmd,
                  const Atributo& blk) {

  string lbl_teste = gera_nome_label("teste_for");
  string lbl_bloco = gera_nome_label("bloco_for");
  string lbl_fim = gera_nome_label("fim_for");

  //if (exp.t.nome != Boolean.nome)
 //   erro("A expressão do for deve ser booleana!");

  DEBUG(cout << "Exp:" << endl);
  DEBUG(cout << exp << endl);

  ss.c = decl.c +
        "\n" + lbl_teste + ":;" + 
        "\n" + exp.c + 
        "\n if(" + exp.v + ") goto " + lbl_bloco + ";" +
        "\n goto " + lbl_fim + ";" +
        "\n" + lbl_bloco + ":;" +
        "\n " + blk.c +
        "\n " + cmd.c +
        "\n goto " + lbl_teste + ";" +
        "\n" + lbl_fim + ":;"; 

}

void gera_cmd_while( Atributo& ss, 
                  const Atributo& exp, 
                  const Atributo& blk) { 
  string lbl_teste = gera_nome_label("teste_while");
  string lbl_bloco = gera_nome_label("bloco_while");
  string lbl_fim = gera_nome_label("fim_while");
  
  if( exp.t.nome != Boolean.nome )
    erro( "A expressão do WHILE deve ser booleana!" );
    
  ss.c = lbl_teste + ":;\n" + exp.c + 
         "\nif( " + exp.v + " ) goto " + lbl_bloco + ";\n" +
         "  goto " + lbl_fim + ";\n\n" +
         lbl_bloco + ":;\n" + 
         blk.c + "\n" +
         "  goto " + lbl_teste + ";\n" +
         lbl_fim + ":;\n";
}

// 'Atributo&': o '&' siginifica passar por referência (modifica).
void declara_variavel( Atributo& ss, 
                       const Atributo& s1, const Atributo& s2, const int tipo ) {
  ss.c = "";
  TabelaSimbolos ts = symbol_table_stack.back();
  for( int i = 0; i < s2.lst.size(); i++ ) {
    if( ts.find( s2.lst[i] ) != ts.end() ) 
      erro( "Variável já declarada: " + s2.lst[i] );
    else {

      ts[ s2.lst[i] ] = s1.t;
      ts[ s2.lst[i] ].isParam = tipo == 2;

      // Salvando nova tabela de simbolos na pilha
      symbol_table_stack.pop_back();
      symbol_table_stack.push_back(ts); 

      if (tipo == 2) {
        ss.c += s1.t.decl + " " + s2.lst[i];
      }
    }
  }
}

void busca_tipo_da_variavel( Atributo& ss, const Atributo& s1 ) {
  int found = 0;
  for (vector<TabelaSimbolos>::reverse_iterator it = symbol_table_stack.rbegin(); it != symbol_table_stack.rend(); it++) {
    TabelaSimbolos ts = (*it);
    if ( ts.find( s1.v ) != ts.end() ) {
      ss.t = ts[ s1.v ];
      ss.v = s1.v;
      found = 1;
      break;
    }
  }
  if (found == 0) {
    erro("Variável não declarada: " + s1.v);
  }
}

void gera_codigo_atribuicao( Atributo& ss, 
                             const Atributo& s1, 
                             const Atributo& s3 ) {
  if( s1.t.nome == s3.t.nome || 
      (s1.t.nome == Float.nome && s3.t.nome == Integer.nome ) ) {
    if (s1.t.nome == "string") {
      ss.c = s1.c + s3.c + " " + " strncpy( " + s1.v + ", " + s3.v + ", " + toString(s1.t.dim[0].fim) + " );\n";
    } else {
      ss.c = s1.c + s3.c + " " + s1.v + " = " + s3.v + ";\n";
    }
  }
}

string par( Tipo a, Tipo b ) {
  return a.nome + "," + b.nome;  
}

void gera_codigo_operador( Atributo& ss, 
                           const Atributo& esq, 
                           const Atributo& op, 
                           const Atributo& dir ) {

  DEBUG(cout << "Gera Codigo operador:" << endl);
  DEBUG(cout << "  " << esq << endl);
  DEBUG(cout << "  " << op << endl);
  DEBUG(cout << "  " << dir << endl);

  if( tro.find( op.v ) != tro.end() ) {
    if( tro[op.v].find( par( esq.t, dir.t ) ) != tro[op.v].end() ) {
      ss.t =  tro[op.v][par( esq.t, dir.t )];
      ss.v = gera_nome_variavel(ss.t); // Precisa gerar um nome de variável temporária.
      if (ss.t.nome == "string") {
        ss.c = esq.c + dir.c + " " + "strncat( " + ss.v + ", " + esq.v + ", " + toString(esq.t.dim[0].fim) + " );\n";
        ss.c = ss.c + "strncat(" + ss.v + ", " + dir.v + ", " + toString(dir.t.dim[0].fim) + ");\n";
      } else {
        ss.c = esq.c + dir.c + "  " + ss.v + " = " + esq.v + op.v + dir.v + ";\n";
      }

      DEBUG(cout << "  " << ss << endl);
    }
    else
      erro( "O operador '" + op.v + "' não está definido para os tipos " + esq.t.nome + " e " + dir.t.nome + "." );
  }
  else
    erro( "Operador '" + op.v + "' não definido." );
}

string gera_declaracao_variaveis( ) {
  string decls = "";
  TabelaSimbolos ts = symbol_table_stack.back();
  for (TabelaSimbolos::iterator it = ts.begin(); it != ts.end(); it ++ ) {
    if (it->second.isParam == false)
      decls += it->second.decl + " " + it->first + trata_dimensoes_decl_var(it->second) + ";\n";
  }
  return decls;
}

%}

%token _ID _PROGRAM _MAIN _WRITELN _WRITE _VAR _IF _ELSE _WHILE
%token _FOR _ATRIB _RETURN _FUNCTION _GLOBAL _GLOBALS _LOCAL _LOCALS
%token _INTEGER _STRING _BOOLEAN

%token _CTE_STRING _CTE_INTEGER _CTE_TRUE _CTE_FALSE

%nonassoc '>' '<' '='
%left '+' '-'
%left '*' '/'

%start S

%%

S : NAME BODY_BLOCK MAIN 
    { 
      cout << $1.c << declara_var_temp(temp_global) << gera_declaracao_variaveis()
      << $2.c << $3.c << endl; 
    }
  ;
   
NAME : _PROGRAM _ID ';' 
       { $$.c = "#include <stdlib.h>\n"
                "#include <string.h>\n"
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

FUNCTION_NAME : _ID { 
                      TabelaSimbolos ts;
                      symbol_table_stack.push_back(ts); 
                      $$ = $1;
                    }
              ;

FUNCTION : FUNCTION_NAME PARAMETERS ':' TYPE BLOCK  { 
                                                      $$.c = $4.t.decl + " " + $1.v + "(" + $2.c + ")" + "\n{\n" + gera_declaracao_variaveis() + $5.c + "\n}\n"; 
                                                      symbol_table_stack.pop_back();
                                                    }
		 | FUNCTION_NAME PARAMETERS ':' BLOCK { symbol_table_stack.pop_back(); $$.c = "void " + $1.v + "(" + $2.c + ")" + "\n{\n" + $4.c + "\n}\n"; }
		 | _ID ':' TYPE BLOCK { $$.c = $3.t.decl + " " + $1.v + "( )" + "\n{\n" + $4.c + "\n}\n"; }
		 | _ID ':' BLOCK { $$.c = "void " + $1.v + "( )" + "\n{\n" + $3.c + "\n}\n"; }
     ;

PARAMETERS : PARAMETER ',' PARAMETERS {
                                        $$.c = $1.c + ", " + $3.c;
                                      }
		   | PARAMETER 
		   ;
		   
PARAMETER : TYPE IDS { declara_variavel( $$, $1, $2, 2 ); } 
		  | TYPE CMD_ATTRIBUTION {$$.c = $1.c + $2.c;}
		  ;

DECLARATIONS : DECLARATION ';' DECLARATIONS {$$.c = $1.c + $3.c;}
			 | DECLARATION ';'
			 ;

DECLARATION : TYPE IDS _ATRIB CTE_VAL 
                { 
                  declara_variavel($$, $1, $2, 1); 
                  $2.t = $$.t;
                  string aux = $$.c;
                  gera_codigo_atribuicao($$,$2,$4);
                  $$.c = aux + $$.c;
                }
            | TYPE IDS { declara_variavel( $$, $1, $2, 1 ); } 
			      ;

TYPE : _STRING  { $$.t = String; }
	 | _INTEGER { $$.t = Integer; }
   | _BOOLEAN { $$.t = Boolean; }
	 ;

IDS : _ID { $$.lst.push_back( $1.v ); } //Quando usamos mais de um ID (regra comentada abaixo), ficamos com mais um conflito de shift/reduce
    ;  

/*
IDS : _ID ',' IDS { $$.lst = $1.lst; $$.lst.push_back( $3.v ); }
    | _ID         { $$.lst.push_back( $1.v ); }
    ;  
*/
MAIN : _MAIN ':' BLOCK
            { $$.c = "int main() \n{" + $3.c + "\n}"; }

OPEN_BLOCK : '{'  { 
                    // TabelaSimbolos ts;
                    // symbol_table_stack.push_back(ts); 
                  }
           ;

CLOSE_BLOCK : '}' { 
                    // gera_declaracao_variaveis($$);
                    // symbol_table_stack.pop_back();
                  }
            ;

BLOCK : OPEN_BLOCK CMDS CLOSE_BLOCK { $$.c = $3.c + $2.c + "\n";}//{ $$.c = "\n{\n" + $2.c + "\n}\n";}
	  | CMD //{ $$.c = "{\n" + $1.c + "\n}\n";}
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
		   | EXPRESSION '>' EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		   | EXPRESSION '<' EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		   | F { $$ = $1; }
		   ; 

CTE_VAL : _CTE_STRING { $$ = $1; $$.t = String; }
        | _CTE_INTEGER { $$ = $1; $$.t = Integer; }
        | _CTE_TRUE { $$ = $1; $$.t = Boolean; }
        | _CTE_FALSE { $$ = $1; $$.t = Boolean; }
        ;

F : _ID                   { busca_tipo_da_variavel( $$, $1 ); }
  | CTE_VAL               { $$ = $1; }
  | '(' EXPRESSION ')'    { $$ = $2; }
  ;

CMD_ATTRIBUTION : LVALUE _ATRIB EXPRESSION { gera_codigo_atribuicao( $$, $1, $3 ); }
				;
            
LVALUE : _ID { busca_tipo_da_variavel( $$, $1 ); }
       ; 

CMD_RETURN : _RETURN EXPRESSION { $$.c = $2.c + "  return " + $2.v + ";"; }
	   	   ;

CMD_IF : _IF EXPRESSION ':' BLOCK {Atributo dummy; gera_cmd_if( $$, $2, $4, dummy );}
	   | _IF EXPRESSION ':' BLOCK _ELSE BLOCK {gera_cmd_if( $$, $2, $4, $6 ); }
	   ;

CMD_WHILE : _WHILE EXPRESSION ':' BLOCK { gera_cmd_while($$, $2, $4); }
		  ;

CMD_FOR : _FOR DECLARATION ',' EXPRESSION ',' CMD_ATTRIBUTION ':' BLOCK { gera_cmd_for($$, $2, $4, $6, $8);}
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
  
  //r.erase(r.begin(),r.end());
  r.clear();
  
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
  tro[ ">" ] = r; 
  
}

void inicializa_tipos() {
  Range r = { 0, 255 };
  
  String.dim.push_back( r );
}

int main( int argc, char* argv[] )
{
  TabelaSimbolos ts;
  symbol_table_stack.push_back(ts);
  inicializa_tipos();
  inicializa_tabela_de_resultado_de_operacoes();
  yyparse();
}
