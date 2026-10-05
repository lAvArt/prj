PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man/man1

.PHONY: install uninstall test lint

install:
	mkdir -p $(DESTDIR)$(BINDIR) $(DESTDIR)$(MANDIR)
	install -m 755 prj $(DESTDIR)$(BINDIR)/prj
	install -m 644 prj.1 $(DESTDIR)$(MANDIR)/prj.1

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/prj $(DESTDIR)$(MANDIR)/prj.1

test:
	./tests/run.sh

lint:
	shellcheck -x prj install.sh tests/run.sh
