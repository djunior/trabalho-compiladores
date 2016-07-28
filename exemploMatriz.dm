program Matriz;

main : {

	locals {
		integer i;
		integer j;
		integer k;

		float[3][4][5] fonte;
		float[3][4][5] dest;
	}

	# Inicializando a matriz fonte
	for i = 0, i < 3, i = i + 1: {
		for j = 0, j < 4, j = j + 1: {
			for k = 0, k < 5, k = k + 1: {
				fonte[i][j][k] = i + j + k;
			}
		}
	}

	# Calculando os valores para a matriz dest
	for i = 0, i < 3, i = i + 1: {
		for j = 0, j < 4, j = j + 1: {
			for k = 0, k < 5, k = k + 1: {
				dest[i][j][k] = fonte[i][j][k] / 7 ;
			}
		}
	}

	#Imprimindo os valores
	for i = 0, i < 3, i = i + 1: {
		for j = 0, j < 4, j = j + 1: {
			for k = 0, k < 5, k = k + 1: {
				write("fonte[");
				write(i);
				write("][");
				write(j);
				write("][");
				write(k);
				write("] = ");
				write(fonte[i][j][k]);

				write(", dest[");
				write(i);
				write("][");
				write(j);
				write("][");
				write(k);
				write("] = ");
				writeln(dest[i][j][k]);
			}
		}
	}
}