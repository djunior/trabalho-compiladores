Componentes do trabalho:
David Estevam de Britto Junior
Marcos Paulo Moraes

============================

Breve explicação da sintaxe:

Comentários são iniciados por #

A estrutura de um programa é:

program Nome;

#definições de variáveis globais e funções

main : {
	# corpo do main
}

Palavras reservadas: 

program main integer float boolean string write writeln
read readln globals global locals local for while if else
and or true false

Estruturas:

Funções: 
 nome lista de parametros : tipo de retorno bloco

 Parâmetros são definidos por tipo nome do parâmetro

 Se a função não receber parâmetros ou retornar algum valor,
 os respectivo campos ficam vazios.

 O retorno da função é dado pelo simbolo <=.

Bloco:
 Um bloco é definido por { comandos }, ou apenas um comando.

Comandos:
 Os comandos podem ser if, while, for, atribuições, declarações de variáveis ou chamadas de funções.

If:
 if expressão: bloco

While:
 while expressão: bloco

For:
 for declaração, expressão, atribuição: bloco

Chamada de funções:
 As funções são chamadas passando parâmetros nomeados, da seguinte forma:

 # Declaração
 sum integer a, integer b: integer <= a + b;

 # Chamada
 sum( b = x, a = y);

Atribuição:
 nome da variavel = expressão

Expressões:
 soma: a + b
 subtração: a - b
 multiplicação: a * b
 divisão: a / b
 módulo: a % b
 igualdade: a == b
 desigualdade: a != b
 maior que: a > b
 menor que: a < b
 e: a and b
 ou: a or b

Matrizes:
 Declaração: integer[tamanho] nome da matriz;
 Acesso: nome da matriz[indice]

Escopo de variáveis:
 Exemplo de escopo local
 local integer x;
 locals { integer x; integer y; }

 Exemplo de escopo global: 
 global integer x;
 globals { string a; string b; }

