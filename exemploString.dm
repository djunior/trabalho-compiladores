program Entrada;

globals {
	string a;
}

imprime_str string msg, string m: {
	write(msg);
	writeln(m);
}


main : {
	
	write("Digite um texto: ");
	read(a);
	imprime_str(msg = "Voce digitou = ", m = a);
	 a = a + a;
	imprime_str(msg = "texto + texto = ", m = a);

}
