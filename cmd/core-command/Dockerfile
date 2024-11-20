#  ----------------------------------------------------------------------------------
#  Copyright 2018 Dell Technologies, Inc.
#  Copyright 2018 Cavium
#  Copyright 2023 Intel Corp.
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
RUN make -e ADD_BUILD_TAGS=$ADD_BUILD_TAGS  cmd/core-command/core-command

#Next image - Copy built Go binary into new workspace
FROM debian:bookworm-slim

# 设置环境变量以避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://deb.debian.org|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list.d/debian.sources && \
    apt update && \
    apt upgrade -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

ENV APP_PORT=59882
#expose command data port
EXPOSE $APP_PORT

WORKDIR /
COPY --from=builder /edgex/Attribution.txt /
COPY --from=builder /edgex/security.txt /
COPY --from=builder /edgex/cmd/core-command/core-command /
COPY --from=builder /edgex/cmd/core-command/res/configuration.yaml /res/configuration.yaml

ENTRYPOINT ["/core-command"]
CMD ["-cp=consul.http://edgex-core-consul:8500", "--registry"]
