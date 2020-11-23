DEFINITIONS        := $(shell find . -type f -name package.yaml)
READMES            := $(DEFINITIONS:package.yaml=README.md)
SCRIPTS            := $(shell find . -type f -name \*.sh | sort)
VERSION            := $(shell git tag | grep "packages/" | cut -d/ -f2 | sort -V -r | head -n 1)
# renovate: datasource=github-releases depName=mikefarah/yq
YQ_VERSION         := 3.4.0
# renovate: datasource=github-releases depName=stedolan/jq versioning=regex:^jq-(?<major>\d+?)\.(?<minor>\d+?)(\.(?<patch>\d+?))?$
JQ_VERSION         := jq-1.6
# renovate: datasource=github-releases depName=koalaman/shellcheck
SHELLCHECK_VERSION := v0.7.1
# renovate: datasource=github-tags depName=fsaintjacques/semver-tool
SEMVER_VERSION     := 3.0.0

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

.PHONY:
check-renovate: packages.json
	@\
	PACKAGES=$$(\
		cat packages.json | \
			jq --raw-output '.packages[] | select(.version.latest == null) | .name' \
	); \
	if test -n "$${PACKAGES}"; then \
		echo "The following packages are missing renovate:"; \
		echo "$${PACKAGES}" | while read LINE; do echo "- [ ] $${LINE}"; done; \
		false; \
	fi

.PHONY:
check-version: packages.json
	@\
	PACKAGES=$$(\
		cat packages.json | \
			jq --raw-output '.packages[] | select(.version.command == null) | .name' \
	); \
	if test -n "$${PACKAGES}"; then \
		echo "The following packages are missing the version extractor:"; \
		echo "$${PACKAGES}" | while read LINE; do echo "- [ ] $${LINE}"; done; \
		false; \
	fi

packages.json: $(DEFINITIONS) tools
	@\
	(\
		echo "packages:"; \
		find . -type f -name package.yaml | \
			sort | \
			while read FILE; do \
				.bin/yq prefix $${FILE} '[+]'; \
			done; \
	) | \
	.bin/yq --tojson read - | \
	jq . >packages.json

.PHONY:
readme: check-scripts $(READMES)

%/README.md: %/package.yaml
	@\
	case "$$(./.bin/yq read $*/package.yaml type)" in \
		codeberg) \
			./.bin/yq read --tojson $*/package.yaml | \
				jq --raw-output '"# \(.name)\n\n\(.description)\n\n[Codeberg](https://codeberg.org/\(.repo))"' \
				>"$@"; \
		;; \
		gitlab) \
			./.bin/yq read --tojson $*/package.yaml | \
				jq --raw-output '"# \(.name)\n\n\(.description)\n\n[Codeberg](https://gitlab.com/\(.repo))"' \
				>"$@"; \
		;; \
		"") \
			./.bin/yq read --tojson $*/package.yaml | \
				jq --raw-output '"# \(.name)\n\n\(.description)\n\n[GitHub](https://github.com/\(.repo))"' \
				>"$@"; \
		;; \
		*) \
			echo "!!! Unknown type in $* !!!"; \
			exit 1; \
		;; \
	esac; \
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
		git --no-pager log --pretty=oneline origin/master..HEAD; \
		exit 1; \
	fi

.PHONY:
next-%: .bin/semver
	@\
	.bin/semver bump $* $(VERSION)

.PHONY:
bump-%: check-dirty .bin/semver
	@\
	echo "Working on version $(VERSION)."; \
	NEW_VERSION=$$(.bin/semver bump $* "$(VERSION)"); \
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
	echo "Installing yq version $(YQ_VERSION)..."; \
	curl --silent --location --output $@ https://github.com/mikefarah/yq/releases/download/$(YQ_VERSION)/yq_linux_amd64; \
	chmod +x $@

.bin/jq: .bin
	@\
	echo "Install jq version $(JQ_VERSION)..."; \
	curl --silent --location --output $@ https://github.com/stedolan/jq/releases/download/$(JQ_VERSION)/jq-linux64; \
	chmod +x $@

.bin/shellcheck: .bin
	@\
	echo "Install shellcheck version $(SHELLCHECK_VERSION)..."; \
	curl --silent --location https://github.com/koalaman/shellcheck/releases/download/$(SHELLCHECK_VERSION)/shellcheck-v0.7.1.linux.x86_64.tar.xz | \
		tar -xJC .bin --wildcards --strip-components=1 */shellcheck; \
	chmod +x $@

.bin/semver: .bin
	@\
	echo "Installing semver version $(SEMVER_VERSION)..."; \
	curl --silent --verbose --location --output $@ https://github.com/fsaintjacques/semver-tool/raw/$(SEMVER_VERSION)/src/semver; \
	chmod +x $@
