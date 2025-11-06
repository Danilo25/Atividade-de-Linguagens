# DataLang - Analisador Léxico e Sintático

![Flex Badge](https://img.shields.io/badge/flex-2.6.4-blue)
![Bison Badge](https://img.shields.io/badge/bison-3.8.2-blue)
![GCC Badge](https://img.shields.io/badge/gcc-13.3.0-blue)

Este guia descreve os passos necessários para gerar, compilar e executar o analisador léxico e sintático da linguagem **DataLang** utilizando **Flex**, **Bison** e **GCC**.

## Requisitos

Certifique-se de ter os seguintes pacotes instalados em seu sistema:

- [Flex](https://github.com/westes/flex)
- [Bison](https://www.gnu.org/software/bison/)
- [GCC](https://gcc.gnu.org/)

Caso ainda não tenha os pacotes acima, você pode facilmente instalá-los:

```bash
# Linux (Ubuntu/Debian)
$ sudo apt install flex bison gcc
```

## Exemplos

O projeto inclui arquivos de exemplo na pasta `src/` para demonstrar diferentes aspectos da linguagem:

- **`src/demo.dtlang`**, com um exemplo de implementação de merge e mergeSort de listas numéricas.
- **`src/erro.dtlang`**, com um exemplo de erro de sintaxe.
- **`src/escolha.dtlang`**, com um exemplo do statement `escolha`.

## Passo a Passo (justfile)

O **justfile** automatiza todos os comandos utilizados o processo de build e execução do compilador. Para usá-lo, instale o `just`:

```bash
# Linux (Ubuntu/Debian)
$ sudo apt install just
```

### 1. Gere automaticamente o compilador com Flex, Bison e GCC

Este comando executa automaticamente todos os passos necessários para construir o compilador, incluindo a criação da pasta de build, geração do scanner e parser, e compilação final.

```bash
$ just build 
```

### 2. Execute um dos arquivos de teste com o compilador

Compila e executa um arquivo fonte DataLang, processando sua sintaxe e exibindo o resultado da análise.
```bash
$ just compile src/demo.dtlang
```

## Passo a Passo (manual)

Caso prefira não usar o **justfile**, você pode executar manualmente os comandos abaixo. Todos os passos funcionam da mesma forma, apenas requerem execução individual de cada comando.

### 1. Crie um diretório de build

Cria um diretório separado para organizar todos os arquivos intermediários e o executável final, mantendo o projeto limpo.

```bash
$ mkdir -p build
```

### 2. Gere o código C do scanner com Flex

O Flex processa o arquivo `scanner.l` (definição de tokens e regras léxicas) e gera o código C do analisador léxico, responsável por identificar tokens no código fonte.

```bash
$ flex -o build/scanner.yy.c scanner.l
```

### 3. Gere o código C do parser com Bison

O Bison processa o arquivo `parser.y` (gramática e regras sintáticas) e gera o código C do analisador sintático, que verifica se a sequência de tokens segue a estrutura gramatical da linguagem. As flags `-d`, `-v` e `-g` geram arquivos auxiliares (cabeçalhos, relatórios e grafos).

```bash
$ bison -o build/parser.tab.c -d -v -g parser.y
```

### 4. Gere o compilador com GCC

Compila os arquivos C gerados pelo Flex e Bison em um único executável, criando o compilador final da linguagem DataLang.

```bash
$ gcc build/scanner.yy.c build/parser.tab.c -o build/compiler
```

### 5. Execute um dos arquivos de teste com o compilador

Executa o compilador gerado, fornecendo um arquivo fonte DataLang como entrada para realizar a análise léxica e sintática do código.

```bash
$ ./build/compiler < src/demo.dtlang
```