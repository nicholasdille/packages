DEFINITIONS := $(shell find . -type f -name package.yaml)
READMES     := $(DEFINITIONS:package.yaml=README.md)
SCRIPTS     := $(shell find . -type f -name \*.sh | sort)

.PHONY:
clean:
	@\
	rm packages.json

.PHONY:
tidy: clean
	@\
	rm .bin/*; \
	rmdir .bin

.PHONY:
tools: .bin/jq .bin/yq .bin/shellcheck

.bin:
	@\
	mkdir -p .bin

.bin/yq: .bin
	@\
	curl --silent --location --output .bin/yq https://github.com/mikefarah/yq/releases/download/3.4.0/yq_linux_amd64; \
	chmod +x .bin/yq

.bin/jq: .bin
	@\
	curl --silent --location --output .bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64; \
	chmod +x .bin/jq

.bin/shellcheck: .bin
	@\
	curl --silent --location https://github.com/koalaman/shellcheck/releases/download/v0.7.1/shellcheck-v0.7.1.linux.x86_64.tar.xz | \
		tar -xJC .bin --wildcards --strip-components=1 */shellcheck; \
	chmod +x .bin/jq

.PHONY:
check: tools
	@\
	.bin/shellcheck $(SCRIPTS)

packages.json: $(DEFINITIONS) tools
	@\
	(\
		echo "tools:"; \
		find . -type f -name package.yaml | \
			while read FILE; do \
				.bin/yq prefix $${FILE} '[+]'; \
			done; \
	) | .bin/yq --tojson read - >packages.json

.PHONY:
readme: $(READMES)

%/README.md: %/package.yaml
	@\
	./.bin/yq read --tojson $*/package.yaml | \
		jq --raw-output '"# \(.name)\n\n\(.description)\n\n[GitHub](https://github.com/\(.repo))"' \
		>"$@"; \
	./.bin/yq read --tojson $*/package.yaml | \
		jq --raw-output 'select(.links != null) | .links[] | "\n[\(.text)](\(.url))"' \
		>>"$@"
