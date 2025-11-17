.PHONY: build compile

build:
	mkdir -p build
	flex -o build/scanner.yy.c scanner.l
	bison -o build/parser.tab.c -d -v -g parser.y
	gcc -Ilib build/scanner.yy.c build/parser.tab.c -o build/compiler

compile:
	./build/compiler < $(file)