#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void** alloc_matrix(int r, int c, size_t size) {
    void** m = malloc(r * sizeof(void*));
    for(int i=0; i<r; i++) m[i] = malloc(c * size);
    return m;
}


typedef struct No No;
struct No {
    int chave;
    No* esq;
    No* dir;
};

No* novoNo(int val) {
    No* n = ( (No*) malloc(sizeof(struct No)) );    n->chave = val;
    n->esq = NULL;
    n->dir = NULL;
    return n;
}

No* inserir(No* raiz, int val) {
    if (!((raiz == NULL))) goto L0;
    return novoNo(val);
    L0:    if (!((val < raiz->chave))) goto L1;
    raiz->esq = inserir(raiz->esq, val);
    goto L2;
    L1:
    raiz->dir = inserir(raiz->dir, val);
    L2:
    return raiz;
}

int altura(No* n) {
    if (!((n == NULL))) goto L3;
    return 0;
    L3:    int esqH = altura(n->esq);
    int dirH = altura(n->dir);
    if (!((esqH > dirH))) goto L4;
    return (esqH + 1);
    goto L5;
    L4:
    return (dirH + 1);
    L5:
}

int imprimirNivel(No* n, int nivelAtual, int nivelAlvo) {
    if (!((n == NULL))) goto L6;
    return 0;
    L6:    if (!((nivelAtual == nivelAlvo))) goto L7;
    printf("%d ", n->chave);
    goto L8;
    L7:
    imprimirNivel(n->esq, (nivelAtual + 1), nivelAlvo);    imprimirNivel(n->dir, (nivelAtual + 1), nivelAlvo);

    L8:
    return 0;
}

int imprimirArvorePorNiveis(No* raiz) {
    int h = altura(raiz);    int i;
{
    i = 0;
    L9:
    if (!((i < h))) goto L10;
    printf("Nivel %d"": ", i);    imprimirNivel(raiz, 0, i);
    printf("%s\n", "");

    i += 1;
    goto L9;
    L10:
}

    return 0;
}

int encontrarMinimo(No* n, int nivel) {
    if (!((n == NULL))) goto L11;
    printf("%s\n", "Arvore vazia");    return 0;

    L11:    if (!((n->esq == NULL))) goto L12;
    printf("Minimo: %d"" no nivel: %d" "\n", n->chave, nivel);    return n->chave;

    goto L13;
    L12:
    return encontrarMinimo(n->esq, (nivel + 1));
    L13:
}

int encontrarMaximo(No* n, int nivel) {
    if (!((n == NULL))) goto L14;
    printf("%s\n", "Arvore vazia");    return 0;

    L14:    if (!((n->dir == NULL))) goto L15;
    printf("Maximo: %d"" no nivel: %d" "\n", n->chave, nivel);    return n->chave;

    goto L16;
    L15:
    return encontrarMaximo(n->dir, (nivel + 1));
    L16:
}

int main() {
    printf("%s\n", "=== PROBLEMA 6: Arvore Binaria de Busca ===");    No* raiz = NULL;
    int qtd;
    int valor_temp;
    int i;
    printf("%s\n", "Digite a quantidade de nos:");
    scanf("%d", &qtd);
{
    i = 0;
    L17:
    if (!((i < qtd))) goto L18;
    printf("Digite o valor do no %d"":" "\n", (i + 1));    scanf("%d", &valor_temp);
    raiz = inserir(raiz, valor_temp);

    i += 1;
    goto L17;
    L18:
}

    printf("%s\n", "");
    printf("%s\n", "--- Impressao da Arvore ---");
    imprimirArvorePorNiveis(raiz);
    printf("%s\n", "");
    printf("%s\n", "--- Extremos ---");
    encontrarMinimo(raiz, 0);
    encontrarMaximo(raiz, 0);
    return 0;
}

