.DEFAULT_GOAL:= pkg

clean:
	rm -rf *.zip *.txt VERSION packages/ web/build/

pkg: clean
	web/build.sh --profile pkg --debug	
	mkdir -p packages
	mv *.zip *.txt VERSION packages/

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
