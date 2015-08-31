NAME=maru
VERSION=0.1
PKG_VERSION=1
ARCH=all
PKG=$(NAME)_$(VERSION)-$(PKG_VERSION)_$(ARCH).deb

pkg:
	dpkg-deb --build debpkg/
	mv debpkg.deb $(PKG)

lint: pkg
	lintian $(PKG)

clean:
	rm $(PKG)
