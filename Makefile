.DEFAULT_GOAL := build.examples

ISTIO_VERSION ?= 1.7.2

.PHONY: help build.example build.examples lint test test.sdk test.e2e
help:
	grep -E '^[a-z0-9A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build.example:
	tinygo build -o ./examples/${name}/main.go.wasm -target=wasi -wasm-abi=generic ./examples/${name}/main.go

build.examples:
	find ./examples -type f -name "main.go" | xargs -Ip tinygo build -o p.wasm -target=wasi -wasm-abi=generic p

lint:
	golangci-lint run --build-tags proxytest

test:
	go test -tags=proxytest $(go list ./... | grep -v e2e | sed 's/github.com\/tetratelabs\/proxy-wasm-go-sdk/./g')

test.e2e:
	docker run -it -w /tmp/proxy-wasm-go -v $(shell pwd):/tmp/proxy-wasm-go getenvoy/proxy-wasm-go-sdk-ci:istio-${ISTIO_VERSION} go test -v ./e2e

run:
	docker run --entrypoint='/usr/local/bin/envoy' \
		-p 18000:18000 -p 8099:8099 \
		-w /tmp/envoy -v $(shell pwd):/tmp/envoy getenvoy/proxy-wasm-go-sdk-ci:istio-${ISTIO_VERSION} \
		-c /tmp/envoy/examples/${name}/envoy.yaml --concurrency 2