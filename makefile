all: mac

clean:
	rm -f lex.yy.c
	rm -f y.tab.c
	rm -f y.output
	rm -f trabalho-compiladores

mac: gabarito-mac trabalho-compiladores-mac entrada.txt
	./trabalho-compiladores < entrada.txt > saida.cc
	gabarito/gabarito < saida.cc
	g++ -o saida saida.cc
	./saida

mac-debug: trabalho-compiladores-mac-debug entrada.txt
	./trabalho-compiladores < entrada.txt > saida.cc
	cat saida.cc

gabarito-mac:
	cd gabarito && make mac

gabarito-linux:
	cd gabarito && make linux

linux: trabalho-compiladores-linux entrada.txt
	./trabalho-compiladores < entrada.txt

linux-debug: trabalho-compiladores-linux-debug entrada.txt
	./trabalho-compiladores < entrada.txt

lex.yy.c: trabalho-compiladores.lex
	lex trabalho-compiladores.lex

y.tab.c: trabalho-compiladores.y
	yacc -v trabalho-compiladores.y

trabalho-compiladores-mac: lex.yy.c y.tab.c
	g++ -o trabalho-compiladores y.tab.c -ll

trabalho-compiladores-mac-debug: lex.yy.c y.tab.c
	g++ -o trabalho-compiladores y.tab.c -ll -D__DEBUG__

trabalho-compiladores-linux: lex.yy.c y.tab.c
	g++ -o trabalho-compiladores y.tab.c -lfl

trabalho-compiladores-linux-debug: lex.yy.c y.tab.c
	g++ -o trabalho-compiladores y.tab.c -lfl -D__DEBUG__

.PHONY: clean
