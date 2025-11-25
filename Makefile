.PHONY: build compile run

# make build
build:
	mkdir -p build
	bison -o build/parser.tab.c -d -v -g parser.y
	flex -o build/scanner.yy.c scanner.l
	gcc -o build/compiler -I. -Ibuild -Ilib \
		build/parser.tab.c build/scanner.yy.c \
		lib/record.c lib/symbol_table.c lib/type_table.c \
		-lfl

# make compile file=src/demo.dtlang
compile:
	mkdir -p out/$(dir $(file))
	./build/compiler $(file) out/$(basename $(file)).c

# make run file=src/demo.dtlang
run:
	gcc -o out/$(basename $(file)) out/$(basename $(file)).c
	./out/$(basename $(file))
