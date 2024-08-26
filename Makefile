PREFIX?=/usr/local
INSTALL_NAME = xcode-frameworks

build:
	swift package update
	swift build -c release

install: build
	mkdir -p $(PREFIX)/bin
	mv .build/release/xcode-frameworks .build/release/$(INSTALL_NAME)
	install .build/release/$(INSTALL_NAME) $(PREFIX)/bin

uninstall:
	rm -f $(PREFIX)/bin/$(INSTALL_NAME)