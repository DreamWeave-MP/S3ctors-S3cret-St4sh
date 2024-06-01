.DEFAULT_GOAL:= pkg

clean:
	rm -f *.zip *.sha*sum.txt version.txt

pkg: clean
	./pkg.sh

web-clean:
	rm -rf web/sha256sums web/soupault-*-linux-x86_64.tar.gz

web: web-clean
	cd web && ./build.sh

web-debug: web-clean
	cd web && ./build.sh --debug

web-verbose: web-clean
	cd web && ./build.sh --verbose

clean-all: clean web-clean

local-web:
	cd web && ./build.sh && python3 -m http.server -d build
