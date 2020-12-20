.PHONY: all ctags install clean install-gotham install-norton tags
modified := $(shell git status -uno | awk '/(new file|modified): .*\.lua/{print $$NF ".ok"}' | sort)
allfiles := $(shell { echo POC.txt; egrep -v '^[ 	]*(;|\#|$$)' POC.txt; } | sort)
FORCE := false

r:=/home/cgf/.local/share/Steam/steamapps/compatdata/3938056110/pfx/drive_c/users/steamuser/My?Documents/Elder?Scrolls?Online/live/AddOns/POC
s:=/home/cgf/.local/share/Steam/steamapps/compatdata/306130/pfx/drive_c/users/steamuser/My?Documents/Elder?Scrolls?Online/live/AddOns/POC
t:=/home/cgf/.local/share/Steam/steamapps/compatdata/306130/pfx/drive_c/users/steamuser/My?Documents/Elder?Scrolls?Online/pts/AddOns/POC
e:=/c/Users/cgf/Documents/Elder\ Scrolls\ Online/live/AddOns/POC
f:=/c/Users/cgf/Documents/Elder\ Scrolls\ Online/pts/AddOns/POC
# allfiles := $(shell ( echo POC.txt ; egrep -v '^[ 	]*[;#]|$$' POC.txt; } | sort )
all: ${modified} | gotham-mounted

.PHONY: FORCE
FORCE:

%.lua.ok: %.lua
	@unexpand -a -I $?
	esolua $?
	@touch $@

.PHONY: tags ctags
tags ctags:
	@ctags --language-force=lua **/*.lua

.PHONY: install
install: install-gotham install-ednor1 install-ednor2

.PHONY: install-gotham
install-gotham: | all clean
	@echo Rsyncing to gotham live...
	@/usr/bin/rsync -aR --delete --force ${allfiles} /smb$e
	@echo Rsyncing to gotham PTS...
	@/usr/bin/rsync -aR --delete --force ${allfiles} /smb$f
	@touch /smb$e/POC.txt

.PHONY: install-ednor1
install-ednor1: | all clean
	@echo Rsyncing to ednor steam live...
	@/usr/bin/rsync -aR --delete --force ${allfiles} $s
	@echo Rsyncing to ednor steam PTS...
	@/usr/bin/rsync -aR --delete --force ${allfiles} $t
	@touch $s/POC.txt

.PHONY: install-ednor2
install-ednor2: | all clean
	@echo Rsyncing to ednor non-steam live...
	@/usr/bin/rsync -aR --delete --force ${allfiles} $r
	@touch $r/POC.txt

.PHONY: install-norton
install-norton: norton-mounted | all clean
	@rm -rf /smb1$e/*
	@echo Rsyncing to norton live...
	@/usr/bin/rsync -aR --delete --force ${allfiles} /smb1$e
	@echo Rsyncing to norton PTS...
	@/usr/bin/rsync -aR --delete --force ${allfiles} /smb1$f
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
