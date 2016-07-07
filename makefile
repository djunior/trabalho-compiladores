all: trabalho-compiladores entrada.txt
	./trabalho-compiladores < entrada.txt

clean:
	rm -f lex.yy.c
	rm -f y.tab.c
	rm -f y.output
	rm -f trabalho-compiladores

lex.yy.c: trabalho-compiladores.lex
	lex trabalho-compiladores.lex

y.tab.c: trabalho-compiladores.y
	yacc -v trabalho-compiladores.y

trabalho-compiladores: lex.yy.c y.tab.c
	g++ -o trabalho-compiladores y.tab.c -ll

.PHONY: clean
