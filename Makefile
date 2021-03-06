PROJECT=helium-arduino
BOARD ?= uno
ifeq ($(strip $(shell git status --porcelain 2>/dev/null)),)
	GIT_TREE_STATE=clean
else
	GIT_TREE_STATE=dirty
endif

all: ci

.PHONY: docs
docs:
	@doxygen Doxyfile

.PHONY: clean
ci:
	for e in examples/*; do \
	  platformio ci --board=${BOARD} --lib=. $$e/*; \
	done

.PHONY: version
version: check_dirty check_version
	sed -i '' 's/version=.*/version=${VERSION}/' library.properties
	sed -i '' "s/\"version\":.*/\"version\": \"${VERSION}\",/"  library.json
	git commit -am "Making library version: ${VERSION}"
	git tag -as -m "Version ${VERSION}" ${VERSION}
	git push origin master --tags


.PHONY: update
update: check_helium_client
	rsync -r --del --exclude='.git' --exclude='.gitignore' --exclude='.travis.yml' ${HELIUM_CLIENT_DIR} src/


.PHONY: gh-pages
gh-pages: docs
	rm -rf gh-pages
	git worktree prune
	git worktree add gh-pages -B gh-pages origin/gh-pages
	rm -rf gh-pages/*
	touch gh-pages/.nojekyll
	mv docs/html/* gh-pages
	cd gh-pages; git add .; git commit -m "Generate docs"; git push origin gh-pages
	rm -rf gh-pages
	git worktree prune


.PHONY: clean
clean:
	rm -rf docs


.PHONY: check_helium_client
check_helium_client:
ifeq ($(HELIUM_CLIENT_DIR),)
	$(error HELIUM_CLIENT_DIR is not set)
endif


.PHONY: check_version
check_version:
ifeq ($(VERSION),)
	$(error VERSION is not set)
endif


.PHONY: check_dirty
check_dirty:
ifeq ($(GIT_TREE_STATE),dirty)
	$(error git state is not clean)
endif
