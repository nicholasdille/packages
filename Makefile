DEFINITIONS := $(shell find . -type f -name package.yaml)

packages.json: $(DEFINITIONS)
	@\
	(\
		echo "tools:"; \
		find . -type f -name package.yaml | \
			while read FILE; do \
				yq prefix $${FILE} '[+]'; \
			done; \
	) | yq --tojson read - >packages.json
