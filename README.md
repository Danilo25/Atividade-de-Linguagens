# Como Testar o Projeto - Analisador Léxico

Este guia descreve os passos necessários para gerar, compilar e executar o analisador léxico utilizando **Flex** e **GCC**.

## Requisitos

Certifique-se de ter os seguintes pacotes instalados em seu sistema:

- [Flex](https://github.com/westes/flex)
- [GCC](https://gcc.gnu.org/)

## Passo a Passo

### 1. Gere o Código C com o Flex

Utilize o Flex para gerar o código-fonte C a partir do arquivo de definição léxica `scanner.l`:

```bash
flex scanner.l
```

### 2. Compile o Analisador Léxico com o GCC

Compile o arquivo gerado com o GCC, garantindo que a biblioteca do Flex seja vinculada com a flag -lfl:

```bash
gcc lex.yy.c -o scanner -lfl
```

### 3. Execute o Analisador Léxico

Execute o analisador direcionando a entrada a partir de um arquivo. Substitua `showcaselang.txt` pelo nome do seu arquivo de entrada, se for diferente:

```bash
./scanner < demostracao.txt
```
"# Atividade-de-Linguagens" 
