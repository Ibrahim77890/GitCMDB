SHELL := /usr/bin/env bash

.PHONY: lint fmt test ci release

lint:
	shellcheck bin/* lib/*.sh scripts/*.sh tests/*.sh install.sh

fmt:
	shfmt -w -i 2 -ci -sr .

test:
	./tests/test-install.sh
	./tests/test-write.sh
	./tests/test-query.sh

ci: lint test

release:
	./scripts/build-release.sh
