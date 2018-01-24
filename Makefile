.PHONY: all ctags install clean install-gotham install-norton tags
modified := $(shell git status | awk '/modified: .*\.lua/{print $$2}')
all: ${modified}

.PHONY: FORCE
FORCE:

%.lua: FORCE
	@echo /usr/bin/lua $@
	@cat eso.lua $@ | /usr/bin/lua /dev/stdin

tags ctags:
	@ctags --language-force=lua **/*.lua

install: install-gotham install-norton

install-gotham: all clean
	/usr/bin/rsync -a --delete --force /usr/src/POC/ /smb/c/Users/cgf/Documents/Elder\ Scrolls\ Online/live/AddOns/POC
	
install-norton: all clean
	/usr/bin/rsync -a --delete --force /usr/src/POC/ /smb1/c/Users/cgf/Documents/Elder\ Scrolls\ Online/live/AddOns/POC

clean:
	@/share/bin/devoclean
