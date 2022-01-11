.PHONY: fmt-check lint fmt

fmt-check:
	crystal tool format --check src

lint:
	cd lint && shards install
	./lint/bin/ameba src

fmt:
	crystal tool format src
