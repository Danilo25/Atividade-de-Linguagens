#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void** alloc_matrix(int r, int c, size_t size) {
    void** m = malloc(r * sizeof(void*));
    for(int i=0; i<r; i++) m[i] = malloc(c * size);
    return m;
}


double** SomarMatrizes(double** A, double** B, int linhas, int colunas) {
    double** resultado = ( (double**) alloc_matrix(linhas, colunas, sizeof(double)));{
    int i = 0;
    L2:
    if (!((i < linhas))) goto L3;
{
    int j = 0;
    L0:
    if (!((j < colunas))) goto L1;
    resultado[i][j] = (A[i][j] + B[i][j]);
    j++;
    goto L0;
    L1:
}

    i++;
    goto L2;
    L3:
}

    return resultado;
}

double** MultiplicarMatrizes(double** A, double** B, int linA, int colA, int colB) {
    double** resultado = ( (double**) alloc_matrix(linA, colB, sizeof(double)));{
    int i = 0;
    L8:
    if (!((i < linA))) goto L9;
{
    int j = 0;
    L6:
    if (!((j < colB))) goto L7;
    resultado[i][j] = 0.000000;{
    int k = 0;
    L4:
    if (!((k < colA))) goto L5;
    resultado[i][j] = (resultado[i][j] + (A[i][k] * B[k][j]));
    k++;
    goto L4;
    L5:
}


    j++;
    goto L6;
    L7:
}

    i++;
    goto L8;
    L9:
}

    return resultado;
}

int ImprimirMatriz(double** M, int linhas, int colunas) {
{
    int i = 0;
    L12:
    if (!((i < linhas))) goto L13;
{
    int j = 0;
    L10:
    if (!((j < colunas))) goto L11;
    printf("%lf\n", M[i][j]);
    j++;
    goto L10;
    L11:
}

    i++;
    goto L12;
    L13:
}
    return 0;
}

int main() {
    printf("%s\n", "=== PROBLEMA 3: Matrizes com Funções ===");    int la;
    int ca;
    printf("%s\n", "Matriz A - Linhas:");
    scanf("%d", &la);
    printf("%s\n", "Matriz A - Colunas:");
    scanf("%d", &ca);
    double** mA = ( (double**) alloc_matrix(la, ca, sizeof(double)));
    int lb;
    int cb;
    printf("%s\n", "Matriz B - Linhas:");
    scanf("%d", &lb);
    printf("%s\n", "Matriz B - Colunas:");
    scanf("%d", &cb);
    double** mB = ( (double**) alloc_matrix(lb, cb, sizeof(double)));
    printf("%s\n", "Digite os elementos da Matriz A:");
{
    int i = 0;
    L16:
    if (!((i < la))) goto L17;
{
    int j = 0;
    L14:
    if (!((j < ca))) goto L15;
    scanf("%lf", &mA[i][j]);
    j++;
    goto L14;
    L15:
}

    i++;
    goto L16;
    L17:
}

    printf("%s\n", "Digite os elementos da Matriz B:");
{
    int i = 0;
    L20:
    if (!((i < lb))) goto L21;
{
    int j = 0;
    L18:
    if (!((j < cb))) goto L19;
    scanf("%lf", &mB[i][j]);
    j++;
    goto L18;
    L19:
}

    i++;
    goto L20;
    L21:
}

    if (!(((la == lb) && (ca == cb)))) goto L22;
    printf("%s\n", "--- Soma (A + B) ---");    double** resSoma = SomarMatrizes(mA, mB, la, ca);
    ImprimirMatriz(resSoma, la, ca);

    goto L23;
    L22:
    printf("%s\n", "Impossível somar: Dimensões diferentes.");
    L23:

    if (!((ca == lb))) goto L24;
    printf("%s\n", "--- Produto (A * B) ---");    double** resProd = MultiplicarMatrizes(mA, mB, la, ca, cb);
    ImprimirMatriz(resProd, la, cb);

    goto L25;
    L24:
    printf("%s\n", "Impossível multiplicar: Colunas de A != Linhas de B.");
    L25:

    return 0;
}

