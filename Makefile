.PHONY: fmt-check lint fmt

fmt-check:
	crystal tool format --check src

lint:
	cd lint && shards install
	./lint/bin/ameba --except Documentation/DocumentationAdmonition src

fmt:
	crystal tool format src
