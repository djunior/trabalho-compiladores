program ExemploFatorial;

fat integer x: integer {
	if x == 1:
		<= 1;

	<= x*fat(x = x - 1);
}

main : {

	locals {
	    integer i;
		integer n;
	}
	
	write("Digite um numero inteiro: ");
	read(n);

	for i = 1, i < n+1, i = i + 1: {
	    write(i);
	    write("! = ");
		writeln(fat(x = i));
	}

}
