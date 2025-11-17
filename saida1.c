#include <stdio.h>
#include <stdlib.h>
#include <string.h>


int main() {
    printf("%s\n", "=== CALCULADORA DE EXPRESSÃO ARITMÉTICA ===");
    printf("%s\n", "Este programa calcula: x² - y + c");
    printf("%s\n", "Onde x e y são números decimais (Real) e c é um inteiro (Inteiro)");
    printf("%s\n", "");
    double x = 10.500000;
    double y = 5.200000;
    int c = 7;
    double resultado;
    printf("%s\n", "=== VALORES UTILIZADOS (fixos) ===");
    printf("%s\n", "x (Real) =");
    printf("%lf\n", x);
    printf("%s\n", "y (Real) =");
    printf("%lf\n", y);
    printf("%s\n", "c (Inteiro) =");
    printf("%d\n", c);
    printf("%s\n", "");
    printf("%s\n", "=== CÁLCULO DA EXPRESSÃO ===");
    printf("%s\n", "Calculando: x² - y + c");
    printf("%s\n", "Substituindo os valores...");
    resultado = (((x * x) - y) + c);
    printf("%s\n", "");
    printf("%s\n", "=== RESULTADO FINAL ===");
    printf("%s\n", "x² - y + c =");
    printf("%lf\n", resultado);
    printf("%s\n", "");
    printf("%s\n", "Cálculo realizado com sucesso!");
    return 0;
}

