VENDORED_ELIXIR=${PWD}/vendor/elixir/bin/elixir
VENDORED_MIX=${PWD}/vendor/elixir/bin/mix
RUN_VENDORED_MIX=${VENDORED_ELIXIR} ${VENDORED_MIX}
VERSION := $(strip $(shell cat VERSION))
STABLE_ELIXIR_VERSION = 0.12.2

.PHONY: all test

all: clean test

clean:
	mix clean

test:
	MIX_ENV=test mix do deps.get, clean, compile, amrita

docs:
	MIX_ENV=dev mix deps.get
	git checkout gh-pages && git pull --rebase && git rm -rf docs && git commit -m "remove old docs"
	git checkout master
	mix docs
	elixir -pa ebin deps/ex_doc/bin/ex_doc "Amrita" "${VERSION}" -u "https://github.com/josephwilk/amrita"
	git checkout gh-pages && git add docs && git commit -m "adding new docs" && git push origin gh-pages
	git checkout master

ci: ci_${STABLE_ELIXIR_VERSION} ci_master

vendor/${STABLE_ELIXIR_VERSION}:
	@rm -rf vendor/*
	@mkdir -p vendor/elixir
	@wget --no-clobber -q https://github.com/elixir-lang/elixir/releases/download/v${STABLE_ELIXIR_VERSION}/v${STABLE_ELIXIR_VERSION}.zip && unzip -qq v${STABLE_ELIXIR_VERSION}.zip -d vendor/elixir

vendor/master:
	@rm -rf vendor/*
	@mkdir -p vendor/elixir
	git clone --quiet https://github.com/elixir-lang/elixir.git vendor/elixir
	make --quiet -C vendor/elixir > /dev/null 2>&1

ci_master: vendor/master
	@${VENDORED_ELIXIR} --version
	@MIX_ENV=test ${RUN_VENDORED_MIX} do clean, deps.get, compile, amrita

ci_$(STABLE_ELIXIR_VERSION): vendor/${STABLE_ELIXIR_VERSION}
	@${VENDORED_ELIXIR} --version
	@MIX_ENV=test ${RUN_VENDORED_MIX} do clean, deps.get, compile, amrita

test_vendored:
	@${VENDORED_ELIXIR} --version
	@${RUN_VENDORED_MIX} clean
	@MIX_ENV=test ${RUN_VENDORED_MIX} do clean, deps.get, compile, amrita
