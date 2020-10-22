DEFINITIONS := $(shell find . -type f -name package.yaml)
READMES     := $(DEFINITIONS:package.yaml=README.md)
SCRIPTS     := $(shell find . -type f -name \*.sh | sort)
VERSION     := $(shell git tag | grep "packages/" | cut -d/ -f2 | sort -V -r | head -n 1)

.PHONY:
clean:
	@\
	rm -f packages.json

.PHONY:
tidy: clean
	@\
	rm -f .bin/*; \
	rmdir .bin

.PHONY:
check-scripts: .bin/shellcheck
	@\
	.bin/shellcheck $(SCRIPTS)

.PHONY:
check-packages: packages.json
	@\
	bash pkg.sh cache; \
	if ! diff "${HOME}/.pkg/packages.json" "packages.json" >/dev/null; then \
		echo "!!! You must create a new release of packages.json !!!"; \
		exit 1; \
	else \
		echo "Packages are up-to-date."; \
	fi

packages.json: $(DEFINITIONS) tools
	@\
	(\
		echo "tools:"; \
		find . -type f -name package.yaml | \
			sort | \
			while read FILE; do \
				.bin/yq prefix $${FILE} '[+]'; \
			done; \
	) | \
	.bin/yq --tojson read - | \
	jq . >packages.json

.PHONY:
readme: check $(READMES)

%/README.md: %/package.yaml
	@\
	./.bin/yq read --tojson $*/package.yaml | \
		jq --raw-output '"# \(.name)\n\n\(.description)\n\n[GitHub](https://github.com/\(.repo))"' \
		>"$@"; \
	./.bin/yq read --tojson $*/package.yaml | \
		jq --raw-output 'select(.links != null) | .links[] | "\n[\(.text)](\(.url))"' \
		>>"$@"

.PHONY:
check-dirty:
	@\
	if test -n "$$(git status --short)"; then \
		echo "!!! You have uncommitted work."; \
		git status --short; \
		exit 1; \
	fi; \
	if test -n "$$(git log --pretty=oneline origin/master..HEAD)" >/dev/null; then \
		echo "!!! You have unpushed commits."; \
		git log --pretty=oneline origin/master..HEAD; \
		exit 1; \
	fi

.PHONY:
bump-%: check-dirty .bin/semver
	@\
	NEW_VERSION=$$(.bin/semver bump $* $(VERSION)); \
	echo "Updating from $(VERSION) to $${NEW_VERSION}"; \
	git tag --annotate --sign --message "Packages v$${NEW_VERSION}" packages/$${NEW_VERSION}; \
	git push --tags

.PHONY:
tools: .bin/jq .bin/yq .bin/shellcheck .bin/semver

.bin:
	@\
	mkdir -p .bin

.bin/yq: .bin
	@\
	curl --silent --location --output $@ https://github.com/mikefarah/yq/releases/download/3.4.0/yq_linux_amd64; \
	chmod +x $@

.bin/jq: .bin
	@\
	curl --silent --location --output $@ https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64; \
	chmod +x $@

.bin/shellcheck: .bin
	@\
	curl --silent --location https://github.com/koalaman/shellcheck/releases/download/v0.7.1/shellcheck-v0.7.1.linux.x86_64.tar.xz | \
		tar -xJC .bin --wildcards --strip-components=1 */shellcheck; \
	chmod +x $@

.bin/semver: .bin
	@\
	curl --silent --location --output $@ https://github.com/fsaintjacques/semver-tool/raw/3.0.0/src/semver; \
	chmod +x $@
