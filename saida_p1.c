#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void** alloc_matrix(int r, int c, size_t size) {
    void** m = malloc(r * sizeof(void*));
    for(int i=0; i<r; i++) m[i] = malloc(c * size);
    return m;
}


int main() {
    printf("%s\n", "=== PROBLEMA 1: Avaliação de Expressão ===");    printf("%s\n", "Calcula: x^2 - y + c");
    printf("%s\n", "");
    double x;
    double y;
    int c;
    printf("%s\n", "Digite o valor de x (Real):");
    scanf("%lf", &x);
    printf("%s\n", "Digite o valor de y (Real):");
    scanf("%lf", &y);
    printf("%s\n", "Digite o valor de c (Inteiro):");
    scanf("%d", &c);
    double resultado = (((x * x) - y) + c);
    printf("%s\n", "");
    printf("%s\n", "--- Resultado ---");
    printf("x:  %lf\n", x);
    printf("y:  %lf\n", y);
    printf("c:  %d\n", c);
    printf("Resultado final:  %lf\n", resultado);
    return 0;
}

