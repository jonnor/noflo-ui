VERSION=$(shell git describe --always)
PRODUCT=microflo-ui

rel=${PRODUCT}-${VERSION}
srcdir=$(shell pwd)

release:
	# Do npm install && npm install grunt-cli first
	git clean -dfx --exclude=node_modules
	./node_modules/.bin/grunt build
	rm -r /tmp/${rel}
	cd /tmp && cp -r ${srcdir} ${rel}
	mv /tmp/${rel} ./
	rm -r ./${rel}/node_modules
	zip -r ${rel}.zip ${rel}

.PHONY: release
