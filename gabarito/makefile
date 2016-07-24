all: mac

lex.yy.c: gabarito.lex
	lex gabarito.lex

y.tab.c: gabarito.y
	yacc gabarito.y

mac: lex.yy.c y.tab.c
	g++ -o gabarito y.tab.c -ll

linux: lex.yy.c y.tab.c
	g++ -o gabarito y.tab.c -lfl

clean:
	rm lex.yy.c
	rm y.tab.c
	rm gabarito
