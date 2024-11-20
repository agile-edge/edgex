#  ----------------------------------------------------------------------------------
#  Copyright 2019 Dell Technologies, Inc.
#  Copyright 2020-2023 Intel Corporation
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
# 
#  ----------------------------------------------------------------------------------

FROM golang:1.23-bookworm AS builder

ARG ADD_BUILD_TAGS=""

WORKDIR /edgex

ARG GO_PROXY="https://goproxy.cn,direct"
ENV GOPROXY=$GO_PROXY

COPY go.* ./
RUN go mod download

COPY . .
RUN make cmd/secrets-config/secrets-config

#Next image - Copy built Go binary into new workspace
FROM debian:bookworm-slim

# 设置环境变量以避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://deb.debian.org|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list.d/debian.sources && \
    apt update && \
    apt upgrade -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /edgex

COPY --from=builder /edgex/Attribution.txt /
COPY --from=builder /edgex/security.txt /

# We need the CORS configuration from common-config-bootstrapper to write nginx.conf
# (CORS configuration must be done in the proxy when security is enabled, as it must happen prior to security check)
COPY --from=builder /edgex/cmd/core-common-config-bootstrapper/res/configuration.yaml res/common_configuration.yaml

# Note that secrets-config shares the same configuration file as security-proxy-setup
# as we are splitting security-proxy-setup into two different utilities for ease-of-use.
COPY --from=builder /edgex/cmd/secrets-config/res/configuration.yaml res/configuration.yaml
COPY --from=builder /edgex/cmd/secrets-config/secrets-config .

# Setup the entry point script and assign perms
COPY --from=builder /edgex/cmd/security-proxy-setup/entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh \
    && ln -s /usr/local/bin/entrypoint.sh /

ENTRYPOINT ["entrypoint.sh"]
