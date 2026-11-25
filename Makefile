STAGES = lexer parser ast codegen interpreter
INPUT ?= examples/sum.txt

all:
	@for s in $(STAGES); do $(MAKE) -C $$s || exit 1; done

run: all
	@for s in $(STAGES); do echo "== $$s"; ./$$s/$$s $(INPUT); echo; done

wasm:
	./web/build-wasm.sh

clean:
	@for s in $(STAGES); do $(MAKE) -C $$s clean; done

.PHONY: all run wasm clean
