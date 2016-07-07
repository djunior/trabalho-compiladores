all: mac

clean:
	rm -f lex.yy.c
	rm -f y.tab.c
	rm -f y.output
	rm -f trabalho-compiladores

mac: trabalho-compiladores-mac entrada.txt
	./trabalho-compiladores < entrada.txt

linux: trabalho-compiladores-linux entrada.txt
	./trabalho-compiladores < entrada.txt

lex.yy.c: trabalho-compiladores.lex
	lex trabalho-compiladores.lex

y.tab.c: trabalho-compiladores.y
	yacc -v trabalho-compiladores.y

trabalho-compiladores-mac: lex.yy.c y.tab.c
	g++ -o trabalho-compiladores y.tab.c -ll

trabalho-compiladores-linux: lex.yy.c y.tab.c
	g++ -o trabalho-compiladores y.tab.c -lfl

.PHONY: clean
