DEFINITIONS        := $(shell find . -type f -name package.yaml)
SCRIPTS            := $(shell find . -type f -name \*.sh | sort)
PACKAGES_VERSION   := $(shell git tag | grep "packages/" | cut -d/ -f2 | sort -V -r | head -n 1)
CLI_VERSION        := $(shell git tag | grep "cli/" | cut -d/ -f2 | sort -V -r | head -n 1)
DEFAULT_BRANCH     := $(shell git rev-parse --abbrev-ref HEAD)
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
	./.bin/shellcheck $(SCRIPTS)

.PHONY:
check-packages: packages.json
	@\
	bash pkgctl.sh cache; \
	if ! diff "${HOME}/.pkgctl/packages.json" "packages.json" >/dev/null; then \
		echo "!!! You must create a new release of packages.json !!!"; \
		exit 1; \
	else \
		echo "Packages are up-to-date."; \
	fi

.PHONY:
check-renovate: .bin/jq packages.json
	@\
	PACKAGES=$$(\
		cat packages.json | \
			./.bin/jq --raw-output '.packages[] | select(.version.latest == null) | .name' \
	); \
	if test -n "$${PACKAGES}"; then \
		echo "The following packages are missing renovate:"; \
		echo "$${PACKAGES}" | while read LINE; do echo "- [ ] $${LINE}"; done; \
		false; \
	fi

.PHONY:
check-version: .bin/jq packages.json
	@\
	PACKAGES=$$(\
		cat packages.json | \
			./.bin/jq --raw-output '.packages[] | select(.version.command == null) | .name' \
	); \
	if test -n "$${PACKAGES}"; then \
		echo "The following packages are missing the version extractor:"; \
		echo "$${PACKAGES}" | while read LINE; do echo "- [ ] $${LINE}"; done; \
		false; \
	fi

packages.json: .bin/jq .bin/yq $(DEFINITIONS) tools
	@\
	(\
		echo "packages:"; \
		find . -type f -name package.yaml | \
			sort | \
			while read FILE; do \
				./.bin/yq prefix $${FILE} '[+]'; \
			done; \
	) | \
	./.bin/yq --tojson read - | \
	./.bin/jq . >packages.json

.PHONY:
check-dirty:
	@\
	if test -n "$$(git status --short)"; then \
		echo "!!! You have uncommitted work."; \
		git status --short; \
		exit 1; \
	fi; \
	if test -n "$$(git log --pretty=oneline origin/$(DEFAULT_BRANCH)..HEAD)" >/dev/null; then \
		echo "!!! You have unpushed commits."; \
		git --no-pager log --pretty=oneline origin/$(DEFAULT_BRANCH)..HEAD; \
		exit 1; \
	fi

.PHONY:
check-name: .bin/yq
	@\
	find packages -type f -name \*.yaml | \
		sort | \
		while read FILE; do \
			DIRNAME="$$(basename "$$(dirname "$${FILE}")")"; \
			PKGNAME="$$(./.bin/yq read "$${FILE}" 'name')"; \
			if test "$${DIRNAME}" != "$${PKGNAME}"; then \
				echo "Directory name does not match package name ($${DIRNAME}!=$${PKGNAME})."; \
				exit 1; \
			fi; \
		done

.PHONY:
next-packages-%: .bin/semver
	@\
	.bin/semver bump $* $(PACKAGES_VERSION)

.PHONY:
bump-packages-%: check-dirty .bin/semver
	@\
	echo "Working on packages version $(PACKAGES_VERSION)."; \
	NEW_VERSION=$$(./.bin/semver bump $* "$(PACKAGES_VERSION)"); \
	echo "Updating packages from $(PACKAGES_VERSION) to $${NEW_VERSION}"; \
	git tag --annotate --sign --message "Packages v$${NEW_VERSION}" packages/$${NEW_VERSION}; \
	git push --tags

.PHONY:
next-cli-%: .bin/semver
	@\
	./.bin/semver bump $* $(CLI_VERSION)

.PHONY:
bump-cli-%: check-dirty .bin/semver
	@\
	echo "Working on CLI version $(CLI_VERSION)."; \
	NEW_VERSION=$$(./.bin/semver bump $* "$(CLI_VERSION)"); \
	echo "Updating CLI from $(CLI_VERSION) to $${NEW_VERSION}"; \
	git tag --annotate --sign --message "CLI v$${NEW_VERSION}" cli/$${NEW_VERSION}; \
	git push --tags

.PHONY:
tools: .bin/jq .bin/yq .bin/shellcheck .bin/semver

.bin/yq:
	@\
	echo "Installing yq version $(YQ_VERSION)..."; \
	mkdir -p .bin
	curl --silent --location --output $@ https://github.com/mikefarah/yq/releases/download/$(YQ_VERSION)/yq_linux_amd64; \
	chmod +x $@

.bin/jq:
	@\
	echo "Install jq version $(JQ_VERSION)..."; \
	mkdir -p .bin
	curl --silent --location --output $@ https://github.com/stedolan/jq/releases/download/$(JQ_VERSION)/jq-linux64; \
	chmod +x $@

.bin/shellcheck:
	@\
	echo "Install shellcheck version $(SHELLCHECK_VERSION)..."; \
	mkdir -p .bin
	curl --silent --location https://github.com/koalaman/shellcheck/releases/download/$(SHELLCHECK_VERSION)/shellcheck-v0.7.1.linux.x86_64.tar.xz | \
		tar -xJC .bin --wildcards --strip-components=1 */shellcheck; \
	chmod +x $@

.bin/semver:
	@\
	echo "Installing semver version $(SEMVER_VERSION)..."; \
	mkdir -p .bin
	curl --silent --location --output $@ https://github.com/fsaintjacques/semver-tool/raw/$(SEMVER_VERSION)/src/semver; \
	chmod +x $@
