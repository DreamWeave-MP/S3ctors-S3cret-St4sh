proj_dir := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))

.DEFAULT_GOAL:= pkg

clean:
	cd $(proj_dir) && rm -f *.zip *.sha*sum.txt version.txt

pkg: clean
	cd $(proj_dir) && ./pkg.sh

web-clean:
	cd $(proj_dir)/web && rm -rf build site/*.md sha256sums soupault-*-linux-x86_64.tar.gz

web: web-clean
	cd $(proj_dir)/web && ./build.sh

web-debug: web-clean
	cd $(proj_dir)/web && ./build.sh --debug

web-verbose: web-clean
	cd $(proj_dir)/web && ./build.sh --verbose

clean-all: clean web-clean

local-web:
	cd $(proj_dir)/web && python3 -m http.server -d build
