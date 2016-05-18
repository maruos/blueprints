NAME=maru
VERSION=0.1
PKG_VERSION=1
ARCH=armhf
PKG=$(NAME)_$(VERSION)-$(PKG_VERSION)_$(ARCH).deb

pkg:
	fakeroot dpkg-deb --build debpkg/
	mv debpkg.deb $(PKG)

lint: pkg
	lintian $(PKG)

clean:
	rm $(PKG)
