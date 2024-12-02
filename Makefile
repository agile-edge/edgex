#
# Copyright 2022-2023 Intel Corporation
# Copyright (c) 2018 Cavium
#
# SPDX-License-Identifier: Apache-2.0
#

.PHONY: build clean unittest hadolint lint test docker run sbom docker-fuzz fuzz-test-command fuzz-test-data

# change the following boolean flag to include or exclude the delayed start libs for builds for most of core services except support services
INCLUDE_DELAYED_START_BUILD_CORE:="false"
# change the following boolean flag to include or exclude the delayed start libs for builds for support services exculsively
INCLUDE_DELAYED_START_BUILD_SUPPORT:="true"

GO=go

PLATFORM=linux/amd64,linux/arm64,linux/arm/v7
GO_PROXY=https://goproxy.cn,direct

DOCKERS= \
	docker_core_data \
	docker_core_metadata \
	docker_core_command  \
	docker_core_common_config \
	docker_support_notifications \
	docker_support_scheduler \
	docker_security_proxy_auth \
	docker_security_proxy_setup \
	docker_security_secretstore_setup \
	docker_security_bootstrapper \
	docker_security_spire_server \
	docker_security_spire_agent \
	docker_security_spire_config \
	docker_security_spiffe_token_provider

DEBIAN_DOCKERS= \
	docker_core_metadata \
	docker_core_data \
	docker_core_command \
	docker_core_common_config \
	docker_support_notifications \
	docker_support_scheduler

ALPINE_DOCKERS= \
	docker_core_metadata_alpine \
	docker_core_data_alpine \
	docker_core_command_alpine \
	docker_core_common_config_alpine \
	docker_support_notifications_alpine \
	docker_support_scheduler_alpine

.PHONY: $(DOCKERS)

MICROSERVICES= \
	cmd/core-data/core-data \
	cmd/core-metadata/core-metadata \
	cmd/core-command/core-command \
	cmd/core-common-config-bootstrapper/core-common-config-bootstrapper \
	cmd/support-notifications/support-notifications \
	cmd/support-scheduler/support-scheduler \
	cmd/security-proxy-auth/security-proxy-auth \
	cmd/security-secretstore-setup/security-secretstore-setup \
	cmd/security-file-token-provider/security-file-token-provider \
	cmd/secrets-config/secrets-config \
	cmd/security-bootstrapper/security-bootstrapper \
	cmd/security-spiffe-token-provider/security-spiffe-token-provider

.PHONY: $(MICROSERVICES)

VERSION=$(shell (git branch --show-current | sed 's/^release\///' | sed 's/^v//') || echo 0.0.0)
#DOCKER_TAG=$(VERSION)-$(shell git log -1 --format=%h)
DOCKER_TAG=$(VERSION)

GOFLAGS=-ldflags "-X github.com/agile-edge/edgex.Version=$(VERSION)" -trimpath -mod=readonly
GOTESTFLAGS?=-race

GIT_SHA=$(shell git rev-parse HEAD)

ARCH=$(shell uname -m)

GO_VERSION=$(shell grep '^go [0-9].[0-9]*' go.mod | cut -d' ' -f 2)

# DO NOT change the following flag, as it is automatically set based on the boolean switch INCLUDE_DELAYED_START_BUILD_CORE
NON_DELAYED_START_GO_BUILD_TAG_FOR_CORE:=non_delayedstart
ifeq ($(INCLUDE_DELAYED_START_BUILD_CORE),"true")
	NON_DELAYED_START_GO_BUILD_TAG_FOR_CORE:=
endif
NON_DELAYED_START_GO_BUILD_TAG_FOR_SUPPORT:=
ifeq ($(INCLUDE_DELAYED_START_BUILD_SUPPORT),"false")
	NON_DELAYED_START_GO_BUILD_TAG_FOR_SUPPORT:=non_delayedstart
endif

NO_MESSAGEBUS_GO_BUILD_TAG:=no_messagebus

build: $(MICROSERVICES)

build-nats:
	make -e ADD_BUILD_TAGS=include_nats_messaging build

tidy:
	$(GO) mod tidy

core: metadata data command

metadata: cmd/core-metadata/core-metadata
cmd/core-metadata/core-metadata:
	$(GO) build -tags "$(ADD_BUILD_TAGS) $(NON_DELAYED_START_GO_BUILD_TAG_FOR_CORE)" $(GOFLAGS) -o $@ ./cmd/core-metadata

data: cmd/core-data/core-data
cmd/core-data/core-data:
	$(GO) build -tags "$(ADD_BUILD_TAGS) $(NON_DELAYED_START_GO_BUILD_TAG_FOR_CORE)" $(GOFLAGS) -o $@ ./cmd/core-data

command: cmd/core-command/core-command
cmd/core-command/core-command:
	$(GO) build -tags "$(ADD_BUILD_TAGS) $(NON_DELAYED_START_GO_BUILD_TAG_FOR_CORE)" $(GOFLAGS) -o $@ ./cmd/core-command

common-config: cmd/core-common-config-bootstrapper/core-common-config-bootstrapper
cmd/core-common-config-bootstrapper/core-common-config-bootstrapper:
	$(GO) build -tags "$(ADD_BUILD_TAGS) $(NON_DELAYED_START_GO_BUILD_TAG_FOR_CORE)" $(GOFLAGS) -o $@ ./cmd/core-common-config-bootstrapper

support: notifications scheduler

notifications: cmd/support-notifications/support-notifications
cmd/support-notifications/support-notifications:
	$(GO) build -tags "$(ADD_BUILD_TAGS) $(NON_DELAYED_START_GO_BUILD_TAG_FOR_SUPPORT)" $(GOFLAGS) -o $@ ./cmd/support-notifications

scheduler: cmd/support-scheduler/support-scheduler
cmd/support-scheduler/support-scheduler:
	$(GO) build -tags "$(ADD_BUILD_TAGS) $(NON_DELAYED_START_GO_BUILD_TAG_FOR_SUPPORT)" $(GOFLAGS) -o $@ ./cmd/support-scheduler

proxy: cmd/security-proxy-setup/security-proxy-setup
cmd/security-proxy-setup/security-proxy-setup:
	$(GO) build -tags "$(NO_MESSAGEBUS_GO_BUILD_TAG) $(NON_DELAYED_START_GO_BUILD_TAG_FOR_CORE)" $(GOFLAGS) -o ./cmd/security-proxy-setup/security-proxy-setup ./cmd/security-proxy-setup

authproxy: cmd/security-proxy-auth/security-proxy-auth
cmd/security-proxy-auth/security-proxy-auth:
	$(GO) build -tags "$(NO_MESSAGEBUS_GO_BUILD_TAG) $(NON_DELAYED_START_GO_BUILD_TAG_FOR_CORE)" $(GOFLAGS) -o ./cmd/security-proxy-auth/security-proxy-auth ./cmd/security-proxy-auth

secretstore: cmd/security-secretstore-setup/security-secretstore-setup
cmd/security-secretstore-setup/security-secretstore-setup:
	$(GO) build -tags "$(NO_MESSAGEBUS_GO_BUILD_TAG) $(NON_DELAYED_START_GO_BUILD_TAG_FOR_CORE)" $(GOFLAGS) -o ./cmd/security-secretstore-setup/security-secretstore-setup ./cmd/security-secretstore-setup

token: cmd/security-file-token-provider/security-file-token-provider
cmd/security-file-token-provider/security-file-token-provider:
	$(GO) build -tags "$(NO_MESSAGEBUS_GO_BUILD_TAG) $(NON_DELAYED_START_GO_BUILD_TAG_FOR_CORE)" $(GOFLAGS) -o ./cmd/security-file-token-provider/security-file-token-provider ./cmd/security-file-token-provider

secrets-config: cmd/secrets-config/secrets-config
cmd/secrets-config/secrets-config:
	$(GO) build -tags "$(NO_MESSAGEBUS_GO_BUILD_TAG) $(NON_DELAYED_START_GO_BUILD_TAG_FOR_CORE)" $(GOFLAGS) -o ./cmd/secrets-config ./cmd/secrets-config

bootstrapper: cmd/security-bootstrapper/security-bootstrapper
cmd/security-bootstrapper/security-bootstrapper:
	$(GO) build -tags "$(NO_MESSAGEBUS_GO_BUILD_TAG) $(NON_DELAYED_START_GO_BUILD_TAG_FOR_CORE)" $(GOFLAGS) -o ./cmd/security-bootstrapper/security-bootstrapper ./cmd/security-bootstrapper

spiffetp: cmd/security-spiffe-token-provider/security-spiffe-token-provider
cmd/security-spiffe-token-provider/security-spiffe-token-provider:
	$(GO) build -tags "$(NO_MESSAGEBUS_GO_BUILD_TAG) $(NON_DELAYED_START_GO_BUILD_TAG_FOR_CORE)" $(GOFLAGS) -o $@ ./cmd/security-spiffe-token-provider

clean:
	rm -f $(MICROSERVICES)

unittest:
	$(GO) test $(GOTESTFLAGS) -coverprofile=coverage.out ./...

hadolint:
	if which hadolint > /dev/null ; then hadolint --config .hadolint.yml `find * -type f -name 'Dockerfile*' -print` ; elif test "${ARCH}" = "x86_64" && which docker > /dev/null ; then docker run --rm -v `pwd`:/host:ro,z --entrypoint /bin/hadolint hadolint/hadolint:latest --config /host/.hadolint.yml `find * -type f -name 'Dockerfile*' | xargs -i echo '/host/{}'` ; fi
	
lint:
	@which golangci-lint >/dev/null || echo "WARNING: go linter not installed. To install, run make install-lint"
	@if [ "z${ARCH}" = "zx86_64" ] && which golangci-lint >/dev/null ; then echo "running golangci-lint"; golangci-lint version; go version; golangci-lint cache clean; golangci-lint run --verbose --config .golangci.yml ; else echo "WARNING: Linting skipped (not on x86_64 or linter not installed)"; fi

install-lint:
	sudo curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin v1.54.2

test: unittest hadolint lint
	$(GO) vet ./...
	gofmt -l $$(find . -type f -name '*.go'| grep -v "/vendor/")
	[ "`gofmt -l $$(find . -type f -name '*.go'| grep -v "/vendor/")`" = "" ]
	./bin/test-attribution-txt.sh

docker-all: $(DOCKERS)

docker-alpine: $(ALPINE_DOCKERS)
docker: $(DEBIAN_DOCKERS)

docker_core_metadata:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/core-metadata/Dockerfile \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/core-metadata:$(DOCKER_TAG) \
		.
docker_core_metadata_alpine:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/core-metadata/Dockerfile.alpine \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/core-metadata:$(DOCKER_TAG)-alpine \
		.

docker_core_data:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/core-data/Dockerfile \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/core-data:$(DOCKER_TAG) \
		.
docker_core_data_alpine:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/core-data/Dockerfile.alpine \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/core-data:$(DOCKER_TAG)-alpine \
		.

docker_core_command:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/core-command/Dockerfile \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/core-command:$(DOCKER_TAG) \
		.
docker_core_command_alpine:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/core-command/Dockerfile.alpine \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/core-command:$(DOCKER_TAG)-alpine \
		.

docker_core_common_config:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/core-common-config-bootstrapper/Dockerfile \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/core-common-config-bootstrapper:$(DOCKER_TAG) \
		.
docker_core_common_config_alpine:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/core-common-config-bootstrapper/Dockerfile.alpine \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/core-common-config-bootstrapper:$(DOCKER_TAG)-alpine \
		.

docker_support_notifications:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/support-notifications/Dockerfile \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/support-notifications:$(DOCKER_TAG) \
		.
docker_support_notifications_alpine:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/support-notifications/Dockerfile.alpine \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/support-notifications:$(DOCKER_TAG)-alpine \
		.

docker_support_scheduler:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/support-scheduler/Dockerfile \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/support-scheduler:$(DOCKER_TAG) \
		.
docker_support_scheduler_alpine:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/support-scheduler/Dockerfile.alpine \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/support-scheduler:$(DOCKER_TAG)-alpine \
		.

dproxya: docker_security_proxy_auth
docker_security_proxy_auth: 
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/security-proxy-auth/Dockerfile \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/security-proxy-auth:$(DOCKER_TAG) \
		.
docker_security_proxy_auth_alpine:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/security-proxy-auth/Dockerfile.alpine \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/security-proxy-auth:$(DOCKER_TAG)-alpine \
		.

dproxys: docker_security_proxy_setup
docker_security_proxy_setup: 
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/security-proxy-setup/Dockerfile \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/security-proxy-setup:$(DOCKER_TAG) \
		.
docker_security_proxy_setup_alpine:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/security-proxy-setup/Dockerfile.alpine \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/security-proxy-setup:$(DOCKER_TAG)-alpine \
		.
dsecretstore: docker_security_secretstore_setup
docker_security_secretstore_setup: 
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/security-secretstore-setup/Dockerfile \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/security-secretstore-setup:$(DOCKER_TAG) \
		.
docker_security_secretstore_setup_alpine:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/security-secretstore-setup/Dockerfile.alpine \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/security-secretstore-setup:$(DOCKER_TAG)-alpine \
		.

dbootstrapper: docker_security_bootstrapper
docker_security_bootstrapper: 
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/security-bootstrapper/Dockerfile \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/security-bootstrapper:$(DOCKER_TAG) \
		.
docker_security_bootstrapper_alpine:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/security-bootstrapper/Dockerfile.alpine \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/security-bootstrapper:$(DOCKER_TAG)-alpine \
		.

dspires: docker_security_spire_server
docker_security_spire_server: 
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/security-spire-server/Dockerfile \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/security-spire-server:$(DOCKER_TAG) \
		.
docker_security_spire_server_alpine:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/security-spire-server/Dockerfile.alpine \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/security-spire-server:$(DOCKER_TAG)-alpine \
		.

dspirea: docker_security_spire_agent
docker_security_spire_agent: 
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/security-spire-agent/Dockerfile \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/security-spire-agent:$(DOCKER_TAG) \
		.
docker_security_spire_agent_alpine:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/security-spire-agent/Dockerfile.alpine \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/security-spire-agent:$(DOCKER_TAG)-alpine \
		.

dspirec: docker_security_spire_config
docker_security_spire_config: 
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/security-spire-config/Dockerfile \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/security-spire-config:$(DOCKER_TAG) \
		.
docker_security_spire_config_alpine:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/security-spire-config/Dockerfile.alpine \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/security-spire-config:$(DOCKER_TAG)-alpine \
		.

dspiffetp: docker_security_spiffe_token_provider
docker_security_spiffe_token_provider: 
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/security-spiffe-token-provider/Dockerfile \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/security-spiffe-token-provider:$(DOCKER_TAG) \
		.
docker_security_spiffe_token_provider_alpine:
	docker buildx build --platform $(PLATFORM) \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		--build-arg GO_PROXY=$(GO_PROXY) \
		-f cmd/security-spiffe-token-provider/Dockerfile.alpine \
		--label "git_sha=$(GIT_SHA)" \
		--push \
		-t ccr.ccs.tencentyun.com/agile-edge/security-spiffe-token-provider:$(DOCKER_TAG)-alpine \
		.

sbom:
	docker run -it --rm \
		-v "$$PWD:/edgex" -v "$$PWD/sbom:/sbom" \
		spdx/spdx-sbom-generator -p /edgex/ -o /sbom/ --include-license-text true

docker-fuzz:
	docker build -t fuzz-edgex:latest -f fuzz_test/Dockerfile.fuzz .

fuzz-test-command:
# not joining the edgex-network due to swagger file url pointing to localhost for fuzz testing in the container
	docker run --net host --rm -v "$$PWD/fuzz_test/fuzz_results:/fuzz_results" fuzz-edgex:latest core-command /restler-fuzzer/openapi/core-command.yaml

fuzz-test-data:
# not joining the edgex-network due to swagger file url pointing to localhost for fuzz testing in the container
	docker run --net host --rm -v "$$PWD/fuzz_test/fuzz_results:/fuzz_results" fuzz-edgex:latest core-data /restler-fuzzer/openapi/core-data.yaml