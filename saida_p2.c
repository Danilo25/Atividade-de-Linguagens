#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void** alloc_matrix(int r, int c, size_t size) {
    void** m = malloc(r * sizeof(void*));
    for(int i=0; i<r; i++) m[i] = malloc(c * size);
    return m;
}


int main() {
    printf("%s\n", "=== PROBLEMA 2: Classificação de Intervalos ===");    int c1 = 0;
    int c2 = 0;
    int c3 = 0;
    int c4 = 0;
    double num = 0.000000;
    int lendo = 1;
    printf("%s\n", "Digite números (negativo para encerrar):");
    L9:
    if (!((lendo == 1))) goto L10;
    scanf("%lf", &num);    if (!((num < 0.000000))) goto L7;
    lendo = 0;
    goto L8;
    L7:
    if (!(((num >= 0.000000) && (num <= 25.000000)))) goto L5;
    c1 = (c1 + 1);
    goto L6;
    L5:
    if (!(((num >= 26.000000) && (num <= 50.000000)))) goto L3;
    c2 = (c2 + 1);
    goto L4;
    L3:
    if (!(((num >= 51.000000) && (num <= 75.000000)))) goto L1;
    c3 = (c3 + 1);
    goto L2;
    L1:
    if (!(((num >= 76.000000) && (num <= 100.000000)))) goto L0;
    c4 = (c4 + 1);
    L0:

    L2:

    L4:

    L6:

    L8:


        goto L9;
    L10:

    printf("%s\n", "Resultados:");
    printf("Intervalo [0, 25]:  %d\n", c1);
    printf("Intervalo [26, 50]:  %d\n", c2);
    printf("Intervalo [51, 75]:  %d\n", c3);
    printf("Intervalo [76, 100]:  %d\n", c4);
    return 0;
}

