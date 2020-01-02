default:
	opam install . --deps-only
	make build

build:
	make pre-build
	dune build

install:
	eval $(opam config env)
	opam install --yes . --deps-only
	eval $(opam env)
	opam update

lint:
	make clean
	make pre-build
	dune build @lint
	dune build @fmt
	
test:
	make clean
	make pre-build
	dune runtest 
	scripts/run_e2e_tests.sh

.SILENT: clean
clean:
	dune clean
	@git clean -dfX
	rm -rf docs/

doc:
	make pre-build
	dune build @doc
	mkdir docs/
	cp	-r ./_build/default/_doc/_html/* docs/

format:
	make pre-build
	dune build @fmt --auto-promote

hook:
	cp ./hooks/* .git/hooks

coverage:
	make clean
	make pre-build
	BISECT_ENABLE=yes dune build
	scripts/run_test_coverage.sh	
	bisect-ppx-report html
	bisect-ppx-report summary

.SILENT: pre-build
pre-build:
	# hack: create opam files so libraries can be exposed publicly
	cp bolt.opam ast.opam
	cp bolt.opam parsing.opam
	cp bolt.opam typing.opam
	cp bolt.opam desugaring.opam