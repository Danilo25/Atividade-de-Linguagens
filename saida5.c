#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void** alloc_matrix(int r, int c, size_t size) {
    void** m = malloc(r * sizeof(void*));
    for(int i=0; i<r; i++) m[i] = malloc(c * size);
    return m;
}


int mdc(int n, int m, int* r) {
    if (!(((m % n) == 0))) goto L4;
    *r = n;
    goto L5;
    L4:
    if (!(((n % m) == 0))) goto L2;
    *r = m;
    goto L3;
    L2:
    if (!((n < m))) goto L0;
    mdc(n, (m % n), r);
    goto L1;
    L0:
    mdc(m, (n % m), r);
    L1:
    L3:
    L5:    return 0;
}

int main() {
    printf("%s\n", "=== PROBLEMA 5: MDC Recursivo ===");    int n1;
    int n2;
    int resultado = 0;
    printf("%s\n", "Digite o primeiro numero: ");
    scanf("%d", &n1);
    printf("%s\n", "Digite o segundo numero: ");
    scanf("%d", &n2);
    printf("%s\n", "Calculando MDC...");
    mdc(n1, n2, &resultado);
    printf("%s\n", "MDC encontrado: ");
    printf("%d\n", resultado);
    return 0;
}

