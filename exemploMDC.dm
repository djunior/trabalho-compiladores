program ExemploMDC;

mdc integer a, integer b: integer
{
  local integer resto;
  while b > 0 :
  {
    resto = a % b;
    a = b;
    b = resto;
  }
  <= a;
}

imprime_int string msg, integer i: {
	write(msg);
	writeln(i);
}

main : {

	locals {
		integer x;
		integer y;
		integer z;
	}

    writeln("Insira um numero inteiro:");
    readln(x);
    
    writeln("Insira outro numero inteiro:");
    readln(y);

    z = mdc(a = x,b = y);

    imprime_int(msg = "O MDC dos dois numeros e: ",i = z);

}
