WS      [\t ]
BR		"\n"
DIGITO  [0-9]
LETRA   [A-Za-z_]
ID      {LETRA}({LETRA}|{DIGITO})*

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

CTE_STRING	"'"([^'\n]|"''")*"'"
CTE_INTEGER {DIGITO}+

%%

{WS} {}
{BR} { yylineno++; }


{PROGRAM} 	{ yylval = yytext; return _PROGRAM; }
{WRITELN} 	{ yylval = yytext; return _WRITELN; }
{WRITE} 	{ yylval = yytext; return _WRITE; }
{STRING} 	{ yylval = yytext; return _STRING; }
{INTEGER} 	{ yylval = yytext; return _INTEGER; }
{VAR} 		{ yylval = yytext; return _VAR; }
{IF} 		{ yylval = yytext; return _IF; }
{ELSE} 		{ yylval = yytext; return _ELSE; }
{FOR} 		{ yylval = yytext; return _FOR; }
{FUNCTION}  { yylval = yytext; return _FUNCTION; }
{GLOBAL}	{ yylval = yytext; return _GLOBAL; }
{GLOBALS}	{ yylval = yytext; return _GLOBALS; }
{LOCAL}		{ yylval = yytext; return _LOCAL; }
{LOCALS}	{ yylval = yytext; return _LOCALS; }
{WHILE}		{ yylval = yytext; return _WHILE; }

{CTE_STRING} 	{ yylval = yytext; return _CTE_STRING; }
{CTE_INTEGER} 	{ yylval = yytext; return _CTE_INTEGER; }

"<="		{ yylval = yytext; return _RETURN; }
"="			{ yylval = yytext; return _ATRIB; }

{ID}  { yylval = yytext; return _ID; }

.     { yylval = yytext; return yytext[0]; }

%%

 


