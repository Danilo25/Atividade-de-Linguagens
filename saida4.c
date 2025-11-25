#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void** alloc_matrix(int r, int c, size_t size) {
    void** m = malloc(r * sizeof(void*));
    for(int i=0; i<r; i++) m[i] = malloc(c * size);
    return m;
}


typedef struct Rational Rational;
struct Rational {
    int num;
    int den;
};

Rational* criar(int a, int b) {
    Rational* r = ( (Rational*) malloc(sizeof(struct Rational)) );    r->num = a;
    r->den = b;
    return r;
}

int iguais(Rational* r1, Rational* r2) {
    if (!(((r1->num * r2->den) == (r2->num * r1->den)))) goto L0;
    return 1;
    goto L1;
    L0:
    return 0;
    L1:}

Rational* somar(Rational* r1, Rational* r2) {
    int n = ((r1->num * r2->den) + (r2->num * r1->den));    int d = (r1->den * r2->den);
    return criar(n, d);
}

Rational* subtrair(Rational* r1, Rational* r2) {
    int n = ((r1->num * r2->den) - (r2->num * r1->den));    int d = (r1->den * r2->den);
    return criar(n, d);
}

Rational* multiplicar(Rational* r1, Rational* r2) {
    return criar((r1->num * r2->num), (r1->den * r2->den));}

Rational* dividir(Rational* r1, Rational* r2) {
    return criar((r1->num * r2->den), (r1->den * r2->num));}

int imprimirRacional(Rational* r) {
    printf("Racional: %d""/%d" "\n", r->num, r->den);    return 0;
}

int main() {
    printf("%s\n", "=== PROBLEMA 4: Calculadora Racional ===");    int n1;
    int d1;
    int n2;
    int d2;
    printf("%s\n", "");
    printf("%s\n", "--- Primeiro Numero ---");
    printf("%s\n", "Digite o numerador:");
    scanf("%d", &n1);
    printf("%s\n", "Digite o denominador (diferente de 0):");
    scanf("%d", &d1);
    Rational* r1 = criar(n1, d1);
    printf("%s\n", "");
    printf("%s\n", "--- Segundo Numero ---");
    printf("%s\n", "Digite o numerador:");
    scanf("%d", &n2);
    printf("%s\n", "Digite o denominador (diferente de 0):");
    scanf("%d", &d2);
    Rational* r2 = criar(n2, d2);
    printf("%s\n", "");
    printf("%s\n", "--- Resultados ---");
    printf("%s\n", "Soma:");
    imprimirRacional(somar(r1, r2));
    printf("%s\n", "Subtracao:");
    imprimirRacional(subtrair(r1, r2));
    printf("%s\n", "Multiplicacao:");
    imprimirRacional(multiplicar(r1, r2));
    printf("%s\n", "Divisao:");
    imprimirRacional(dividir(r1, r2));
    printf("%s\n", "Verificacao de Igualdade:");
    if (!(iguais(r1, r2))) goto L2;
    printf("%s\n", "Os numeros sao IGUAIS.");
    goto L3;
    L2:
    printf("%s\n", "Os numeros sao DIFERENTES.");
    L3:
    return 0;
}

