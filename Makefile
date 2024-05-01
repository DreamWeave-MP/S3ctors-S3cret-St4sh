.DEFAULT_GOAL:= pkg

clean:
	rm -f *.zip *.sha*sum.txt version.txt

pkg: clean
	./pkg.sh

web-clean:
	rm -rf build site/*.md sha256sums soupault-*-linux-x86_64.tar.gz

web: web-clean
	./build.sh

web-debug: web-clean
	./build.sh --debug

web-verbose: web-clean
	./build.sh --verbose

clean-all: clean web-clean

local-web:
	python3 -m http.server -d build
