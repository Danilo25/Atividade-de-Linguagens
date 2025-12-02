# DataLang - Linguagem de Programação

![Flex Badge](https://img.shields.io/badge/flex-2.6.4-blue)
![Bison Badge](https://img.shields.io/badge/bison-3.8.2-blue)
![GCC Badge](https://img.shields.io/badge/gcc-13.3.0-blue)

DataLang é uma linguagem de programação voltada à ciência de dados, desenvolvida utilizando Flex, Bison e C.

Ela implementa:

- Analisador Léxico
- Analisador Sintático (parser LR)
- Analisador Semântico
- Tabela de Símbolos & Tabela de Tipos
- Geração de Código C
- Execução do programa compilado

O objetivo é demonstrar o pipeline completo de construção de uma linguagem de programação.

## Estrutura do Projeto

```bash
/
├── docs/
│   ├── documentation.pdf
├── lib/
│   ├── record.c
│   ├── symbol_table.c
│   └── type_table.c
├── src/
├── Makefile
├── parser.y
└── scanner.l
```

## Requisitos

Certifique-se de ter os seguintes pacotes instalados em seu sistema:

- [Flex](https://github.com/westes/flex)
- [Bison](https://www.gnu.org/software/bison/)
- [GCC](https://gcc.gnu.org/)
- [Make](https://www.gnu.org/software/make/)

Caso ainda não tenha os pacotes acima, você pode facilmente instalá-los:

```bash
# Linux (Ubuntu/Debian)
$ sudo apt install flex bison gcc make
```

## Passo a Passo

### 1. Construir o compilador

```bash
$ make build
```

### 2. Compilar um programa

```bash
$ make compile file=src/demo.dtlang
```

### 3. Executar um programa

```bash
$ make run file=src/demo.dtlang
```
