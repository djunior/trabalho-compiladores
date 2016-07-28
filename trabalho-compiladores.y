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
  vector<Range> dim; // Dimensões do array
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
  vector<string> lst; // Usado em acesso a arrays
  vector<string> params; // Usando em FUNCTION_CALL
  vector<string> params_temp; // Usado em FUNCTION_CALL
}; 

#define YYSTYPE Atributo

int yylex();
int yyparse();
void yyerror(const char *);
void erro( string );

typedef map<string,Tipo> TabelaSimbolos;

struct Funcao {
  string nome;
  Tipo t;
  map<string,Tipo> params;
  map<string,int> ordemParams;
};

map< string, map< string, Tipo > > tro; // tipo_resultado_operacao;
map< string, int > temp_global; // tabela de geração de nome de vars temporárias globais
map< string, int > temp_local;  // tabela de geração de nome de vars temporárias locais
map< string, int > nlabel;  // tabela de geração de nome de labels
map< string, Funcao > tf; // tabela de funções

bool escopo_local = false;

vector< TabelaSimbolos > symbol_table_stack;

ostream& operator << ( ostream& o, const vector<string>& st ) {
  o << "{ ";
  for( vector<string>::const_iterator itr = st.begin();
       itr != st.end(); ++itr )
    o << *itr << " "; 
       
  o << "}";
  return o;     
}

ostream& operator << ( ostream& o, const vector<Range>& r ) {
  for ( vector<Range>::const_iterator it = r.begin(); it != r.end(); it++ ) {
    o << "[";
    o << (*it).inicio;
    o << ",";
    o << (*it).fim;
    o << "]";
  }
  return o;
}

ostream& operator << ( ostream& o, const Tipo& st ) {
  o << "Tipo(" << (&st) << ")";
  o << "{";
  o << "nome = " << st.nome;
  o << ", decl = " << st.decl;
  o << ", fmt = " << st.fmt;
  o << ", dim = " << st.dim;
  o << "}";
  return o;     
}

ostream& operator << ( ostream& o, const Atributo& st ) {
  o << "Atributo{";
  o << "v = " << st.v;
  o << ", c = " << st.c;
  o << ", lst = " << st.lst;
  o << ", params = " << st.params;
  o << ", lst_temp = " << st.params_temp;
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

int toInt(string s) {
  return atoi(s.c_str());
}

string gera_nome_variavel(Tipo t, int n) {
  return "t_" + t.nome + "_" + toString(n);
}

string gera_nome_variavel(Tipo t) {
  return gera_nome_variavel(t,++(escopo_local ? temp_local : temp_global)[t.nome]);
}

string gera_nome_label( string cmd ) {
  return "L_" + cmd + "_" + toString( ++nlabel[cmd] );
}

string trata_dimensoes_decl_var( Tipo t ) {
  string aux;
  int totalSize = 1;

  if (t.dim.size() == 0)
    return "";

  for( int i = 0; i < t.dim.size(); i++ ) {
    int size = t.dim[i].fim - t.dim[i].inicio + 1;
    totalSize *= size;
  }

  aux = "[" + toString(totalSize) + "]";

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
                declara_nvar_temp(Float, temp_map[Float.nome]) +
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

  if (exp.t.nome != Boolean.nome)
    erro("A expressão do for deve ser booleana!");

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


void busca_tipo_da_variavel( Atributo& ss, const string nome ) {
  DEBUG(cout << "busca_tipo_da_variavel" << endl);
  DEBUG(cout << "   " << ss << endl);
  DEBUG(cout << "   " << nome << endl);
  int found = 0;
  for (vector<TabelaSimbolos>::reverse_iterator it = symbol_table_stack.rbegin(); it != symbol_table_stack.rend(); it++) {
    TabelaSimbolos ts = (*it);
    if ( ts.find( nome ) != ts.end() ) {
      ss.t = ts[ nome ];
      ss.v = nome;
      found = 1;
      break;
    }
  }
  if (found == 0) {
    erro("Variável não declarada: " + nome);
  }
}

void gera_codigo_acesso_array(Atributo& ss, const Atributo& array) {

    ss.c = array.c;

    string temp = gera_nome_variavel(Integer);
    string calculo_indice = temp + " = 0;\n";
    for (int i = 0; i < array.lst.size(); i++) {
      int multiplicador = 1;
      for (int j = i+1; j < ss.t.dim.size(); j++) {
        int size = ss.t.dim[j].fim - ss.t.dim[j].inicio + 1;
        multiplicador *= size;
      }
      string temp_mult = gera_nome_variavel(Integer);
      string mult = temp_mult + " = " + array.lst[i] + " * " + toString(multiplicador);
      string sum = temp + " = " + temp + " + " + temp_mult; 
      calculo_indice += mult + ";\n" + sum + ";\n";
    }
    ss.c += calculo_indice;
    ss.v += "[" + temp + "]";
}

void gera_codigo_atribuicao( Atributo& ss, 
                             const Atributo& esq, 
                             const Atributo& dir ) {
  if( esq.t.nome == dir.t.nome || 
      (esq.t.nome == Float.nome && dir.t.nome == Integer.nome ) ) {
    if (esq.t.nome == "string") {
      ss.c = esq.c + dir.c + " " + " strncpy( " + esq.v + ", " + dir.v + ", " + toString(esq.t.dim[0].fim) + " );\n";
    } else {
      ss.c = esq.c + dir.c + " " + esq.v + " = " + dir.v + ";\n";
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
  DEBUG(cout << "  esq = " << esq << endl);
  DEBUG(cout << "  op = " << op << endl);
  DEBUG(cout << "  dir = " << dir << endl);

  if( tro.find( op.v ) != tro.end() ) {
    if( tro[op.v].find( par( esq.t, dir.t ) ) != tro[op.v].end() ) {
      
      ss.t =  tro[op.v][par( esq.t, dir.t )];
      ss.v = gera_nome_variavel(ss.t); // Precisa gerar um nome de variável temporária.

      if (ss.t.nome == "string") {
      
        ss.c = esq.c + dir.c + " " + "strncat( " + ss.v + ", " + esq.v + ", " + toString(esq.t.dim[0].fim) + " );\n";
        ss.c = ss.c + "strncat(" + ss.v + ", " + dir.v + ", " + toString(dir.t.dim[0].fim) + ");\n";
      
      } else {

        Atributo t1 = esq;
        Atributo t2 = dir;
        if (esq.lst.size() > 0)
          gera_codigo_acesso_array(t1,esq);

        if (dir.lst.size() > 0)
          gera_codigo_acesso_array(t2,dir);          

        ss.c = t1.c + t2.c + "  " + ss.v + " = " + t1.v + " " + op.v + " " + t2.v + ";\n";

      }

      DEBUG(cout << "  saida = " << ss << endl);
    }
    else
      erro( "O operador '" + op.v + "' não está definido para os tipos " + esq.t.nome + " e " + dir.t.nome + "." );
  }
  else
    erro( "Operador '" + op.v + "' não definido." );
}

string gera_declaracao_variaveis( ) {
  DEBUG(cout << "gera_declaracao_variaveis" << endl);
  string decls = "";
  TabelaSimbolos ts = symbol_table_stack.back();
  for (TabelaSimbolos::iterator it = ts.begin(); it != ts.end(); it ++ ) {
    if (it->second.isParam == false) {
      DEBUG(cout << "Variavel: " << it->first << ", Tipo = " << it->second << endl);
      decls += it->second.decl + " " + it->first + trata_dimensoes_decl_var(it->second) + ";\n";
    }
  }
  return decls;
}

void copia_delimitadores_array( Atributo& ss,
                                const Atributo& array) {
  for (int i = 0; i < array.t.dim.size(); i++)
    ss.t.dim.push_back(array.t.dim[i]);
}

%}

%token _ID _PROGRAM _MAIN _WRITELN _WRITE _READLN _READ _VAR _IF _ELSE _WHILE
%token _FOR _ATRIB _RETURN _FUNCTION _GLOBAL _GLOBALS _LOCAL _LOCALS
//%token _DIFF _EQUAL
%token _INTEGER _STRING _BOOLEAN _FLOAT

%token _CTE_STRING _CTE_INTEGER _CTE_TRUE _CTE_FALSE _CTE_FLOAT

%nonassoc '>' '<' '=' _NEQUAL _EQUAL _AND _OR
%left '+' '-'
%left '*' '/' '%'

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
                      escopo_local = true;
                      TabelaSimbolos ts;
                      symbol_table_stack.push_back(ts); 
                      $$ = $1;

                      Funcao f;
                      f.nome = $1.v;
                      tf[$1.v] = f;
                    }
              ;

FUNCTION : FUNCTION_NAME 
            PARAMETERS ':' T { tf[$1.v].t = $4.t; } BLOCK { 
                                        DEBUG(cout << "FUNCTION -> FUNCTION_NAME PARAMETERS : TYPE BLOCK" << endl);
                                        for (int i = 0; i < $2.lst.size(); i++) {
                                          Atributo a;
                                          busca_tipo_da_variavel(a,$2.v);
                                          tf[$1.v].params[$2.lst[i]] = a.t;
                                          tf[$1.v].ordemParams[$2.lst[i]] = i;
                                        }

                                        $$.c = $4.t.decl + " " + $1.v + "(" + $2.c + ")" + "\n{\n" + declara_var_temp(temp_local) + gera_declaracao_variaveis() + $6.c + "\n}\n"; 
                                        symbol_table_stack.pop_back();
                                        escopo_local = false;
                                      }   
	       | FUNCTION_NAME PARAMETERS ':' BLOCK { 
                                                DEBUG(cout << "FUNCTION -> FUNCTION_NAME PARAMETERS : BLOCK" << endl);
                                                for (int i = 0; i < $2.lst.size(); i++) {
                                                  Atributo a;
                                                  busca_tipo_da_variavel(a,$2.v);
                                                  tf[$1.v].params[$2.lst[i]] = a.t;
                                                  tf[$1.v].ordemParams[$2.lst[i]] = i;
                                                }
                                                symbol_table_stack.pop_back(); 
                                                escopo_local = false; 
                                                $$.c = "void " + $1.v + "(" + $2.c + ")" + "\n{\n" + declara_var_temp(temp_local) + gera_declaracao_variaveis() + $4.c + "\n}\n"; 
                                              }
		     | FUNCTION_NAME ':' T { tf[$1.v].t = $3.t; } BLOCK { escopo_local = false; symbol_table_stack.pop_back(); $$.c = $3.t.decl + " " + $1.v + "( )" + "\n{\n" + declara_var_temp(temp_local) + gera_declaracao_variaveis() + $5.c + "\n}\n"; }
		     | FUNCTION_NAME ':' BLOCK { escopo_local = false; symbol_table_stack.pop_back(); $$.c = "void " + $1.v + "( )" + "\n{\n" + declara_var_temp(temp_local) + gera_declaracao_variaveis() + $3.c + "\n}\n"; }
         ;

PARAMETERS : PARAMETERS ',' PARAMETER {
                                        DEBUG(cout << "PARAMETERS -> PARAMETERS , PARAMETER" << endl);
                                        DEBUG(cout << "   " << $1 << endl);
                                        DEBUG(cout << "   " << $3 << endl);
                                        $$.c = $1.c + ", " + $3.c;
//<<<<<<< HEAD
                                        if ($3.t.dim.size() > 0) {
                                          $$.c += "[]";
                                        }

                                        $1.lst.push_back($3.v);
                                        $$.lst = $1.lst;
                                      }
		       | PARAMETER  { $$ = $1; if ($1.t.dim.size() > 0) $$.c += "[]"; $$.lst.push_back($1.v);  }
/*
=======
                                        $1.lst.push_back($3.v);
                                        $$.lst = $1.lst;
                                      }
		       | PARAMETER  { 
                          DEBUG(cout << "PARAMETERS -> PARAMETER" << endl);
                          DEBUG(cout << "   " << $1 << endl);
                          $$ = $1; $$.lst.push_back($1.v); 
                        }
>>>>>>> chamada_funcao_atrib
*/
		       ;
		   
PARAMETER : TYPE IDS { 
                        DEBUG(cout << "PARAMETER -> TYPE IDS" << endl);
                        DEBUG(cout << "   " << $1 << endl);
                        DEBUG(cout << "   " << $2 << endl);
                        $$.v = $2.v; declara_variavel( $$, $1, $2, 2 ); } 
		      | TYPE CMD_ATTRIBUTION  {
                                    DEBUG(cout << "PARAMETER -> TYPE CMD_ATTRIBUTION" << endl);
                                    DEBUG(cout << "   " << $1 << endl);
                                    DEBUG(cout << "   " << $2 << endl);
                                    $$.v = $2.v; $$.c = $1.c + $2.c;
                                  }
		      ;

DECLARATIONS : DECLARATIONS DECLARATION ';' {$$.c = $1.c + $2.c;}
			       | DECLARATION ';'
			       ;

DECLARATION : TYPE IDS _ATRIB CTE_VAL 
                { 
                  DEBUG(cout << "DECLARATION -> TYPE IDS _ATRIB CTE_VAL" << endl);
                  DEBUG(cout << "   " << $1 << endl);
                  DEBUG(cout << "   " << $2 << endl);
                  DEBUG(cout << "   " << $3 << endl);
                  DEBUG(cout << "   " << $4 << endl);
                  declara_variavel($$, $1, $2, 1); 
                  $2.t = $$.t;
                  string aux = $$.c;
                  gera_codigo_atribuicao($$,$2,$4);
                  $$.c = aux + $$.c;
                }
            | TYPE IDS  {
                          DEBUG(cout << "DECLARATION -> TYPE IDS" << endl);
                          DEBUG(cout << "   " << $1 << endl);
                          DEBUG(cout << "   " << $2 << endl); 
                          declara_variavel( $$, $1, $2, 1 ); 
                        } 
			      ;

ACCESS_ARRAYS : ACCESS_ARRAYS ACCESS_ARRAY  {
                                              $$.c = $1.c + $2.c;
                                              $1.lst.push_back($2.v);
                                              $$.lst = $1.lst;
                                            }
              |
              ;

ACCESS_ARRAY : '[' EXPRESSION ']' {
                                    $$.c = $2.c;
                                    $$.v = $2.v;
                                  }
             ;

DECL_ARRAYS : DECL_ARRAYS DECL_ARRAY { 
                        DEBUG(cout << "ARRAYS -> ARRAYS ARRAY" << endl);
                        copia_delimitadores_array($1,$2);
                        $$.t.dim = $1.t.dim;                     
                      }
       |  { 
            DEBUG(cout << "ARRAYS -> Empty" << endl);
            // ??????
            // Não sei porque, mas isso resolve um problema da última
            // declaração de array "vazar" para a próxima variável
            // Ex: O código abaixo
            //
            // local integer[2][3][4] x;
            // local integer y;
            //
            // gerava um código C-Assembly assim:
            //
            // int x[30]; -> Correto
            // int y[4]; -> A ultima declaração de array ([4]) vazou para cá
            //                                                                         
            // A linha abaixo corrige esse problema, mas não sei ainda porque ¯\_(ツ)_/¯
            $$.t.dim.clear();
          }
       ;

DECL_ARRAY : '[' _CTE_INTEGER ']' 
            { 
              DEBUG(cout << "ARRAY -> [ _CTE_INTEGER ]" << endl);
              DEBUG(cout << "   VALUE = " << $2.v << endl);
              Range r = {0, toInt($2.v)-1 };
              $$.t.dim.push_back(r);
            }
/*      | '[' EXPRESSION ']' {
                              $$.c = $2.c;
                              $$.v = $2.v;
                           }
*/
      ;

TYPE : T DECL_ARRAYS 
          {
            DEBUG(cout << "TYPE -> T ARRAYS " << endl);
            DEBUG(cout << " BEFORE:" << endl);
            DEBUG(cout << "   T = " << $1 << endl);
            DEBUG(cout << "   ARRAYS = " << $2 << endl);
            DEBUG(cout << "   SAIDA = " << $$ << endl);

            $$ = $1;
            copia_delimitadores_array($$,$2);
            
            DEBUG(cout << " AFTER:" << endl);
            DEBUG(cout << "   T = " << $1 << endl);
            DEBUG(cout << "   ARRAYS = " << $2 << endl);
            DEBUG(cout << "   SAIDA = " << $$ << endl);
          }
     ;

T : _STRING { $$.t = String; }
  | _INTEGER { $$.t = Integer; }
  | _FLOAT { $$.t = Float; }
  | _BOOLEAN { $$.t = Boolean; } 
	;

IDS : _ID { $$.lst.push_back( $1.v ); } //Quando usamos mais de um ID (regra comentada abaixo), ficamos com mais um conflito de shift/reduce
    ;  

/*
IDS : _ID ',' IDS { $$.lst = $1.lst; $$.lst.push_back( $3.v ); }
    | _ID         { $$.lst.push_back( $1.v ); }
    ;  
*/
MAIN : _MAIN { symbol_table_stack.push_back(TabelaSimbolos()); escopo_local = true;} ':' BLOCK
            { $$.c = "int main() \n{" + declara_var_temp(temp_local) + gera_declaracao_variaveis()+ $4.c + "\n}"; symbol_table_stack.pop_back(); escopo_local = false; }

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

CMDS : CMDS CMD { $$.c = $1.c + $2.c; }
     | { $$.c = ""; }
     ;

CMD : CMD_ATTRIBUTION ';' {$$ = $1; }
	  | CMD_RETURN ';'
	  | CMD_IF
	  | CMD_WHILE
	  | CMD_FOR
	  | PRINT ';'
	  | SCAN ';'
	  | LOCAL_BLOCK
	  | GLOBAL_BLOCK
    | FUNCTION_CALL ';'
	  ;

PRINT : _WRITE '(' EXPRESSION ')'
        { 
          DEBUG(cout << "PRINT -> _WRITE ( EXPRESSION )" << endl);
          DEBUG(cout << "  E = " << $3 << endl);
          $$.c = "  " + $3.c + "\n  printf( \"%" + $3.t.fmt + "\", " + $3.v + " );\n"; 
        }
      | _WRITELN '(' EXPRESSION ')'
        { 
          DEBUG(cout << "PRINTLN -> _WRITELN ( EXPRESSION )" << endl);
          DEBUG(cout << "  E = " << $3 << endl);
          $$.c = "  " + $3.c + "\n  printf( \"%" + $3.t.fmt + "\\n\", " + $3.v + " );\n"; 
        }
      ;
      
SCAN    : _READLN '(' _ID ')'  
          { 
            DEBUG(cout << "SCAN -> _READLN ( LVALUE )" << endl);
            busca_tipo_da_variavel($3,$3.v);
            $$.c = "  scanf( \"%"+ $3.t.fmt + "\", &"+ $3.v + " );\n"; 
          }
        | _READ '(' _ID ')'  
          { 
            DEBUG(cout << "SCAN -> _READ ( LVALUE )" << endl);
            busca_tipo_da_variavel($3,$3.v);
            $$.c = "  scanf( \"%"+ $3.t.fmt + "\", &"+ $3.v + " );\n"; 
          }
        ;   

EXPRESSION : EXPRESSION '+' EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		       | EXPRESSION '-' EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		       | EXPRESSION '*' EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		       | EXPRESSION '/' EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		       | EXPRESSION '>'  EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		       | EXPRESSION '<' EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		       | EXPRESSION '%' EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		       | EXPRESSION _NEQUAL EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		       | EXPRESSION _EQUAL EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		       | EXPRESSION _AND EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		       | EXPRESSION _OR EXPRESSION { gera_codigo_operador( $$, $1, $2, $3 ); }
		       | F { $$ = $1; }
		       ; 


CTE_VAL : _CTE_STRING  { $$ = $1; $$.t = String;  }
        | _CTE_INTEGER { $$ = $1; $$.t = Integer; }
        | _CTE_FLOAT   { $$ = $1; $$.t = Float;   }
        | _CTE_TRUE    { $$ = $1; $$.t = Boolean; }
        | _CTE_FALSE   { $$ = $1; $$.t = Boolean; }
        ;

FUNC_PARAMS : FUNC_PARAMS ',' FUNC_PARAM { 
                                            DEBUG(cout << "FUNC_PARAMS -> FUNC_PARAMS , FUNC_PARAM" << endl);
                                            DEBUG(cout << "   $1 = " << $1 << endl);
                                            DEBUG(cout << "   $3 = " << $3 << endl);
                                            $$.c = $1.c + $3.c; 
                                            $1.params.push_back($3.v);
                                            $1.params_temp.push_back($3.params_temp.back());
                                            $$.params = $1.params;
                                            $$.params_temp = $1.params_temp;
                                          }
            | FUNC_PARAM  { 
                            DEBUG(cout << "FUNC_PARAMS -> FUNC_PARAM" << endl);
                            DEBUG(cout << "   " << $1 << endl);
                            $$.c = $1.c; 
                            $$.params.push_back($1.v); 
                            DEBUG(cout << "   saida = " << $$ << endl);
                          }
            ;

FUNC_PARAM : _ID _ATRIB EXPRESSION  {

                                      DEBUG(cout << "FUNC_PARAM -> _ID _ATRIB EXPRESSION" << endl);
                                      DEBUG(cout << "   " << $1 << endl);
                                      DEBUG(cout << "   " << $3 << endl);

                                      string temp_name = gera_nome_variavel($3.t);
                                      if ($3.t.nome == String.nome) {
                                        $$.c = $3.c + "  strncpy(" + temp_name + ", " + $3.v + ", " + toString($3.t.dim[0].fim) + ");\n";
                                      } else {
                                        $$.c = $3.c + "  " + temp_name + " = " + $3.v + ";\n"; 
                                      }
                                      $$.v = $1.v;
                                      $$.params_temp.push_back(temp_name);

                                      DEBUG(cout << "   saida = " << $$ << endl);
                                    }
           ;

FUNCTION_CALL : _ID '(' FUNC_PARAMS ')' { 
                                            DEBUG(cout << "FUNCTION_CALL -> _ID ( FUNC_PARAMS )" << endl);
                                            DEBUG(cout << "   " << $1 << endl);
                                            DEBUG(cout << "   " << $3 << endl);

                                            string p = "";
                                            vector<string> params_ordered($3.params.size());
                                            
                                            for (int i = 0; i < $3.params.size(); i++) {
                                              int indice = tf[$1.v].ordemParams[$3.params[i]];
                                              params_ordered[indice] = $3.params_temp[i];
                                            }

                                            for (int i = 0; i < $3.params.size(); i++) {
                                              p += (p == "" ? "" : ",") + params_ordered[i];
                                            }
                                            
                                            $$.c = $3.c + "  ";
                                            string str_return = "";
                                            if (tf[$1.v].t.nome != "") {
                                              $$.v = gera_nome_variavel( tf[$1.v].t );
                                              $$.t = tf[$1.v].t; 

                                              if ($$.t.nome == String.nome) {
                                                str_return = "" ;
                                              } else {
                                                str_return = $$.v + " = ";
                                              }
                                              
                                            }

                                            if ($$.t.nome == String.nome) {
                                              $$.c += "strcpy(" + $$.v + ", " + $1.v + "( " + p + " )" + ");\n";
                                            } else {
                                              $$.c += $1.v + "( " + p + " );\n";
                                            }
                                         }
              | _ID '(' ')' {
                              if (tf[$1.v].t.nome != "") {
                                $$.v = gera_nome_variavel( tf[$1.v].t );
                                $$.c += $$.v + " = ";
                                $$.t = tf[$1.v].t; 
                              }
                              $$.c = $1.v + "( );\n";
                            }
              ;

F : _ID ACCESS_ARRAYS     { 
                            DEBUG(cout << "F -> _ID ACCESS_ARRAYS" << endl);
                            DEBUG(cout << "   " << $1 << endl); 
                            DEBUG(cout << "   " << $2 << endl); 
                            

                            busca_tipo_da_variavel( $$, $1.v );
                            $1.t = $$.t;

                            DEBUG(cout << "   " << $$ << endl);

                            if ($2.lst.size() > 0)
                              gera_codigo_acesso_array($1,$2);

                            $$.c = $1.c;

                            string temp = gera_nome_variavel($$.t);
                            if ($$.t.nome == String.nome) {

                              $$.c += "strncpy(" + temp + ", " + $1.v + ", " + toString($$.t.dim[0].fim) + ");\n";
                            } else {
                              $$.c += temp + " = " + $1.v + ";\n";
                            }
                            $$.v = temp;
                          }
  | CTE_VAL               { $$ = $1; }
  | '(' EXPRESSION ')'    { $$ = $2; }
  | FUNCTION_CALL         { $$ = $1; }
  ;

CMD_ATTRIBUTION : LVALUE ACCESS_ARRAYS _ATRIB EXPRESSION   { 
                                                      DEBUG(cout << "CMD_ATTRIBUTION -> LVALUE ACCESS_ARRAYS _ATRIB EXPRESION" << endl); 
                                                      DEBUG(cout << "   " << $1 << endl);
                                                      DEBUG(cout << "   " << $2 << endl);
                                                      DEBUG(cout << "   " << $4 << endl);

                                                      if ($2.lst.size() > 0)
                                                        gera_codigo_acesso_array($1,$2);

                                                      $$.v = $1.v;
                                                      gera_codigo_atribuicao( $$, $1, $4 ); 
                                                    }
				        ;
            
LVALUE : _ID  { 
                DEBUG(cout << "LVALUE -> _ID" << endl);
                DEBUG(cout << "   " << $1 << endl);
                busca_tipo_da_variavel( $$, $1.v ); 
              }
       ; 

CMD_RETURN : _RETURN EXPRESSION { $$.c = $2.c + "  return " + $2.v + ";"; }
	   	     ;

CMD_IF : _IF EXPRESSION ':' BLOCK {Atributo dummy; gera_cmd_if( $$, $2, $4, dummy );}
	     | _IF EXPRESSION ':' BLOCK _ELSE BLOCK {gera_cmd_if( $$, $2, $4, $6 ); }
	     ;

CMD_WHILE : _WHILE EXPRESSION ':' BLOCK { gera_cmd_while($$, $2, $4); }
		      ;

CMD_FOR : _FOR DECLARATION ',' EXPRESSION ',' CMD_ATTRIBUTION ':' BLOCK { gera_cmd_for($$, $2, $4, $6, $8);}
        | _FOR CMD_ATTRIBUTION ',' EXPRESSION ',' CMD_ATTRIBUTION ':' BLOCK { gera_cmd_for($$, $2, $4, $6, $8);}
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
  tro[ "%" ] = r; 
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
  tro[ "!=" ] = r; 
  tro[ "==" ] = r; 

  r.clear();
  r[par(Boolean,Boolean)] = Boolean;


  tro[ "&&" ] = r;
  tro[ "||" ] = r;

  r.clear();
  
}

void inicializa_tipos() {
  Range r = { 0, 255 };
  
  String.dim.push_back( r );

  DEBUG(cout << "Integer: " << Integer << endl);
  DEBUG(cout << "String: " << String << endl);
  DEBUG(cout << "Float: " << Float << endl);
  DEBUG(cout << "Boolean: " << Boolean << endl);
}

int main( int argc, char* argv[] )
{
  TabelaSimbolos ts;
  symbol_table_stack.push_back(ts);
  inicializa_tipos();
  inicializa_tabela_de_resultado_de_operacoes();
  yyparse();
}
