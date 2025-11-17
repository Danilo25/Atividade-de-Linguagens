#include <stdio.h>
#include <stdlib.h>
#include <string.h>


int main() {
    printf("%s\n", "=== CLASSIFICADOR DE NÚMEROS POR INTERVALOS ===");    printf("%s\n", "Este programa classifica números nos seguintes intervalos:");
    printf("%s\n", "[0-25], [26-50], [51-75], [76-100]");
    printf("%s\n", "");
    printf("%s\n", "Digite números positivos (ENTER após cada um)");
    printf("%s\n", "Para finalizar, digite qualquer número negativo");
    printf("%s\n", "");
    int contador_0_25 = 0;
    int contador_26_50 = 0;
    int contador_51_75 = 0;
    int contador_76_100 = 0;
    double numero_atual = 0.000000;
    int programa_ativo = 1;
    int numero_entrada = 0;
    L11:
    if (!((programa_ativo == 1))) goto L12;
    printf("%s\n", "Digite um número (negativo para sair):");    scanf("%lf", &numero_atual);
    if (!((numero_atual < 0.000000))) goto L0;
    programa_ativo = 0;    printf("%s\n", "Número negativo detectado. Encerrando programa...");

    L0:

    if (!((programa_ativo == 1))) goto L10;
    numero_entrada = (numero_entrada + 1);    if (!((numero_atual >= 0.000000))) goto L2;
    if (!((numero_atual <= 25.000000))) goto L1;
    contador_0_25 = (contador_0_25 + 1);    printf("%s\n", "-> Classificado no intervalo [0-25]");

    L1:

    L2:

    if (!((numero_atual >= 26.000000))) goto L4;
    if (!((numero_atual <= 50.000000))) goto L3;
    contador_26_50 = (contador_26_50 + 1);    printf("%s\n", "-> Classificado no intervalo [26-50]");

    L3:

    L4:

    if (!((numero_atual >= 51.000000))) goto L6;
    if (!((numero_atual <= 75.000000))) goto L5;
    contador_51_75 = (contador_51_75 + 1);    printf("%s\n", "-> Classificado no intervalo [51-75]");

    L5:

    L6:

    if (!((numero_atual >= 76.000000))) goto L8;
    if (!((numero_atual <= 100.000000))) goto L7;
    contador_76_100 = (contador_76_100 + 1);    printf("%s\n", "-> Classificado no intervalo [76-100]");

    L7:

    L8:

    if (!((numero_atual > 100.000000))) goto L9;
    printf("%s\n", "-> AVISO: Número fora dos intervalos monitorados (>100)");
    L9:

    printf("%s\n", "");

    L10:


        goto L11;
    L12:

    printf("%s\n", "");
    printf("%s\n", "========== RELATÓRIO FINAL ==========");
    printf("%s\n", "Total de números processados:");
    printf("%d\n", numero_entrada);
    printf("%s\n", "");
    printf("%s\n", "Distribuição por intervalos:");
    printf("%s\n", "Intervalo [0-25]:");
    printf("%d\n", contador_0_25);
    printf("%s\n", "Intervalo [26-50]:");
    printf("%d\n", contador_26_50);
    printf("%s\n", "Intervalo [51-75]:");
    printf("%d\n", contador_51_75);
    printf("%s\n", "Intervalo [76-100]:");
    printf("%d\n", contador_76_100);
    printf("%s\n", "");
    printf("%s\n", "Programa finalizado com sucesso!");
    return 0;
}

