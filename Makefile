.PHONY: all test

all: test

test:
	MIX_ENV=test mix do deps.get, test
