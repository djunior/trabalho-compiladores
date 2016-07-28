all: helloworld

clean:
	rm -f lex.yy.c
	rm -f y.tab.c
	rm -f y.output
	rm -f trabalho-compiladores
	rm exemploMDC
	rm exemploString
	rm exemploFatorial
	rm exemploMatriz
	rm helloWorld
	rm *.cc

mdc: trabalho-compiladores-linux exemploMDC.dm
	./trabalho-compiladores < exemploMDC.dm > exemploMDC.cc
	g++ -o exemploMDC exemploMDC.cc
	./exemploMDC

string: trabalho-compiladores-linux exemploString.dm
	./trabalho-compiladores < exemploString.dm > exemploString.cc
	g++ -o exemploString exemploString.cc
	./exemploString

fatorial: trabalho-compiladores-linux exemploFatorial.dm
	./trabalho-compiladores < exemploFatorial.dm > exemploFatorial.cc
	g++ -o exemploFatorial exemploFatorial.cc
	./exemploFatorial

matriz: trabalho-compiladores-linux exemploMatriz.dm
	./trabalho-compiladores < exemploMatriz.dm > exemploMatriz.cc
	g++ -o exemploMatriz exemploMatriz.cc
	./exemploMatriz

helloworld: trabalho-compiladores-linux helloWorld.dm
	./trabalho-compiladores < helloWorld.dm > helloWorld.cc
	g++ -o helloWorld helloWorld.cc
	./helloWorld

mac: trabalho-compiladores-mac entrada.txt
	./trabalho-compiladores < matriz.dm > saida.cc
	g++ -o saida saida.cc
	./saida

mac-debug: trabalho-compiladores-mac-debug entrada.txt
	./trabalho-compiladores < entrada.txt > saida.cc
	cat saida.cc

linux: trabalho-compiladores-linux
	./trabalho-compiladores < entrada.txt > saida.cc

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
