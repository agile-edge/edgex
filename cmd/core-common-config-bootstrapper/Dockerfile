#  ----------------------------------------------------------------------------------
#  Copyright (c) 2023 Intel Corporation
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
#  SPDX-License-Identifier: Apache-2.0
#  ----------------------------------------------------------------------------------

FROM golang:1.23-bookworm AS builder

ARG ADD_BUILD_TAGS=""

WORKDIR /edgex

ARG GO_PROXY="https://goproxy.cn,direct"
ENV GOPROXY=$GO_PROXY

COPY go.* ./
RUN go mod download

COPY . .
RUN make -e ADD_BUILD_TAGS=$ADD_BUILD_TAGS cmd/core-common-config-bootstrapper/core-common-config-bootstrapper

#Next image - Copy built Go binary into new workspace
FROM debian:bookworm-slim

# 设置环境变量以避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://deb.debian.org|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list.d/debian.sources && \
    apt update && \
    apt upgrade -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /edgex/Attribution.txt /
COPY --from=builder /edgex/security.txt /
COPY --from=builder /edgex/cmd/core-common-config-bootstrapper/core-common-config-bootstrapper /
COPY --from=builder /edgex/cmd/core-common-config-bootstrapper/res/configuration.yaml /res/configuration.yaml

COPY --from=builder /edgex/cmd/core-common-config-bootstrapper/entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh \
    && ln -s /usr/local/bin/entrypoint.sh /

ENV TZ=Asia/Shanghai
RUN mkdir -p /var/log/agile-edge && chown -R 1000:1000 /var/log/agile-edge
USER 1000:1000

ENTRYPOINT ["entrypoint.sh"]
CMD ["/core-common-config-bootstrapper", "-cp=consul.http://edgex-core-consul:8500"]
