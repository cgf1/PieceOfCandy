.PHONY: all ctags install clean install-gotham install-norton tags
modified := $(shell git status | awk '/(new file|modified): .*\.lua/{print $$NF ".ok"}' | sort)
allfiles := $(shell { echo POC.txt; egrep -v '^[ 	]*(;|\#|$$)' POC.txt; } | sort)
FORCE := false

e:=/c/Users/cgf/Documents/Elder\ Scrolls\ Online/live/AddOns/POC
# allfiles := $(shell ( echo POC.txt ; egrep -v '^[ 	]*[;#]|$$' POC.txt; } | sort )
all: ${modified}

.PHONY: FORCE
FORCE:

%.lua.ok: %.lua
	@unexpand -I $?
	esolua $?
	@touch $@

.PHONY: tags ctags
tags ctags:
	@ctags --language-force=lua **/*.lua

.PHONY: install
install: install-gotham install-norton

.PHONY: install-gotham
install-gotham: gotham-mounted | all clean
	@rm -rf /smb$e/*
	@echo Rsyncing to gotham...
	@/usr/bin/rsync -aR --delete --force ${allfiles} /smb$e
	@touch /smb$e/POC.txt

.PHONY: install-norton
install-norton: norton-mounted | all clean
	@rm -rf /smb1$e/*
	@echo Rsyncing to norton...
	@/usr/bin/rsync -aR --delete --force ${allfiles} /smb1$e
	@touch /smb1$e/POC.txt

.PHONY: clean
clean:
	@/share/bin/devoclean

.PHONY: distclean
distclean: clean
	@find . -name '*.ok' -exec rm {} +

.PHONY: gotham-mounted
gotham-mounted:
	@[ -d /smb/c/tmp ] || /usr/local/bin/r bmount gotham

.PHONY: norton-mounted
norton-mounted:
	@[ -d /smb1/c/tmp ] || /usr/local/bin/r bmount norton
