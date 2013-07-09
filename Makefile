VENDORED_ELIXIR=${PWD}/vendor/elixir/bin/elixir
VENDORED_MIX=${PWD}/vendor/elixir/bin/mix
RUN_VENDORED_MIX=${VENDORED_ELIXIR} ${VENDORED_MIX}

.PHONY: all test

all: clean test

clean:
	mix clean

test:
	MIX_ENV=test mix do deps.get, test

docs:
	MIX_ENV=dev mix deps.get
	git checkout gh-pages && git pull --rebase && git rm -rf docs && git commit -m "remove old docs"
	git checkout master
	elixir -pa ebin deps/ex_doc/bin/ex_doc "Amrita" "0.1.3" -u "https://github.com/josephwilk/amrita"
	git checkout gh-pages && git add docs && git commit -m "adding new docs" && git push origin gh-pages
	git checkout master

ci: ci_0_9_3 ci_master

ci_0_9_3:
	rm -rf vendor/*
	mkdir -p vendor/elixir
	wget --no-clobber -q http://dl.dropbox.com/u/4934685/elixir/v0.9.3.zip && unzip -qq v0.9.3.zip -d vendor/elixir
	${VENDORED_ELIXIR} --version
	MIX_ENV=test ${RUN_VENDORED_MIX} do deps.get, test

ci_master:
	rm -rf vendor/*
	mkdir -p vendor/elixir
	cd vendor && git clone https://github.com/elixir-lang/elixir.git
	cd vendor/elixir && make
	${VENDORED_ELIXIR} --version
	MIX_ENV=test ${RUN_VENDORED_MIX} do deps.get, test

test_vendored:
	${VENDORED_ELIXIR} --version
	MIX_ENV=test ${RUN_VENDORED_MIX} do deps.get, test
