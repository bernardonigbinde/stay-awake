PREFIX ?= /usr/local

build:
	swift build -c release

install: build
	install -d $(PREFIX)/bin
	install .build/release/stay-awake $(PREFIX)/bin/stay-awake

clean:
	rm -rf .build

.PHONY: build install clean
