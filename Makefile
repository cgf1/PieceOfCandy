.PHONY: all install clean install-gotham install-norton
all:
	@/usr/bin/lua eso.lua `/usr/bin/find . -name '*.lua' | sort`

install: install-gotham install-norton

install-gotham: all clean
	/usr/bin/rsync -a --delete --force /usr/src/POC/ /smb/c/Users/cgf/Documents/Elder\ Scrolls\ Online/live/AddOns/POC
	
install-norton: all clean
	/usr/bin/rsync -a --delete --force /usr/src/POC/ /smb1/c/Users/cgf/Documents/Elder\ Scrolls\ Online/live/AddOns/POC

clean:
	@/share/bin/devoclean
