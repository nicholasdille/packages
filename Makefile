DEFINITIONS := $(shell find . -type f -name package.yaml)
READMES     := $(DEFINITIONS:package.yaml=README.md)
SCRIPTS     := $(shell find . -type f -name \*.sh | sort)

.PHONY:
tools: .bin/jq .bin/yq

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

.PHONY:
check:
	@\
	shellcheck $(SCRIPTS)

packages.json: $(DEFINITIONS)
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
