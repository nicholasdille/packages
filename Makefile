DEFINITIONS := $(shell find . -type f -name package.yaml)
READMES     := $(DEFINITIONS:package.yaml=README.md)

packages.json: $(DEFINITIONS)
	@\
	(\
		echo "tools:"; \
		find . -type f -name package.yaml | \
			while read FILE; do \
				yq prefix $${FILE} '[+]'; \
			done; \
	) | yq --tojson read - >packages.json

.PHONY:
readme: $(READMES)

%/README.md: %/package.yaml
	@\
	yq read --tojson $*/package.yaml | \
		jq --raw-output '"# \(.name)\n\n\(.description)\n\n[GitHub](https://github.com/\(.repo))"' \
		>"$@"; \
	yq read --tojson $*/package.yaml | \
		jq --raw-output 'select(.links != null) | .links[] | "\n[\(.text)](\(.url))"' \
		>>"$@"
