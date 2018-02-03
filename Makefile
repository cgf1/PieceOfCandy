.PHONY: all ctags install clean install-gotham install-norton tags
modified := $(shell git status | awk '/modified: .*\.lua/{print $$2 ".ok"}')
allfiles := $(shell { echo POC.txt; egrep -v '^[ 	]*(;|\#|$$)' POC.txt; } | sort)
# allfiles := $(shell ( echo POC.txt ; egrep -v '^[ 	]*[;#]|$$' POC.txt; } | sort )
all: ${modified}

.PHONY: FORCE
FORCE:

%.lua.ok: %.lua
	unexpand -I $?
	esolua $?
	@touch $@

tags ctags:
	@ctags --language-force=lua **/*.lua

install: install-gotham install-norton

install-gotham: | all clean
	@rm -rf /smb/c/Users/cgf/Documents/Elder\ Scrolls\ Online/live/AddOns/POC/*
	/usr/bin/rsync -aR --delete --force ${allfiles} /smb/c/Users/cgf/Documents/Elder\ Scrolls\ Online/live/AddOns/POC
	
install-norton: | all clean
	@rm -rf /smb1/c/Users/cgf/Documents/Elder\ Scrolls\ Online/live/AddOns/POC/*
	/usr/bin/rsync -aR --delete --force ${allfiles} /smb1/c/Users/cgf/Documents/Elder\ Scrolls\ Online/live/AddOns/POC

clean:
	@/share/bin/devoclean
