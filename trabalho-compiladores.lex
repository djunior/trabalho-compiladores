%{
int yyrowno = 1;
void trata_folha();
%}
WS      [\t ]
BR		"\n"
DIGITO  [0-9]
LETRA   [A-Za-z_]
ID      {LETRA}({LETRA}|{DIGITO})*
COMMENT "#"[^\n]*

PROGRAM 	program
WRITELN		writeln
WRITE		write
INTEGER		integer
STRING		string
VAR			var
IF			if
ELSE		else
FOR			for
FUNCTION	functions
GLOBAL		global
GLOBALS 	globals
LOCAL		local
LOCALS 		locals
WHILE		while
MAIN        main

CTE_STRING	"\""([^\"\n]|"\"\"")*"\""
CTE_INTEGER {DIGITO}+

%%

void trata_folha();

{COMMENT} {yylineno++; yyrowno = 1;}
{WS} { yyrowno += 1; }
{BR} { yylineno++; yyrowno = 1; }


{PROGRAM} 	{ trata_folha(); return _PROGRAM; }
{WRITELN} 	{ trata_folha(); return _WRITELN; }
{WRITE} 	{ trata_folha(); return _WRITE; }
{STRING} 	{ trata_folha(); return _STRING; }
{INTEGER} 	{ trata_folha(); return _INTEGER; }
{VAR} 		{ trata_folha(); return _VAR; }
{IF} 		{ trata_folha(); return _IF; }
{ELSE} 		{ trata_folha(); return _ELSE; }
{FOR} 		{ trata_folha(); return _FOR; }
{MAIN}      { trata_folha(); return _MAIN; }
{FUNCTION}  { trata_folha(); return _FUNCTION; }
{GLOBAL}	{ trata_folha(); return _GLOBAL; }
{GLOBALS}	{ trata_folha(); return _GLOBALS; }
{LOCAL}		{ trata_folha(); return _LOCAL; }
{LOCALS}	{ trata_folha(); return _LOCALS; }
{WHILE}		{ trata_folha(); return _WHILE; }

{CTE_STRING} 	{ trata_folha(); return _CTE_STRING; }
{CTE_INTEGER} 	{ trata_folha(); return _CTE_INTEGER; }

"<="		{ trata_folha(); return _RETURN; }
"="			{ trata_folha(); return _ATRIB; }

{ID}  { trata_folha(); return _ID; }

.     { trata_folha(); return yytext[0]; }

%%

void trata_folha() {
  yylval.v = yytext;
  yylval.t.nome = "";
  yylval.t.decl = "";
  yylval.t.fmt = "";
  yylval.c = "";
  yylval.lst.clear();
  
  yyrowno += strlen( yytext );

}

 


