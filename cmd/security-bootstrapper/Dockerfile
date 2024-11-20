#  ----------------------------------------------------------------------------------
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
RUN make cmd/security-bootstrapper/security-bootstrapper

#Next image - Copy built Go binary into new workspace
FROM debian:bookworm-slim

# 设置环境变量以避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://deb.debian.org|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list.d/debian.sources && \
    apt update && \
    apt upgrade -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

ENV SECURITY_INIT_DIR /edgex-init
ENV SECURITY_INIT_STAGING /edgex-init-staging
ARG BOOTSTRAP_REDIS_DIR=${SECURITY_INIT_STAGING}/bootstrap-redis
ARG BOOTSTRAP_MOSQUITTO_DIR=${SECURITY_INIT_STAGING}/bootstrap-mosquitto

RUN mkdir -p ${BOOTSTRAP_REDIS_DIR} ${BOOTSTRAP_MOSQUITTO_DIR}

WORKDIR ${SECURITY_INIT_STAGING}

# copy all entrypoint scripts into shared folder
COPY --from=builder /edgex/cmd/security-bootstrapper/entrypoint-scripts/ ${SECURITY_INIT_STAGING}/
RUN chmod +x ${SECURITY_INIT_STAGING}/*.sh

COPY --from=builder /edgex/Attribution.txt /
COPY --from=builder /edgex/security.txt /
COPY --from=builder /edgex/cmd/security-bootstrapper/security-bootstrapper .
COPY --from=builder /edgex/cmd/security-bootstrapper/res/configuration.yaml ./res/

# needed for bootstrapping Redis db
COPY --from=builder /edgex/cmd/security-bootstrapper/res-bootstrap-redis/configuration.yaml ${BOOTSTRAP_REDIS_DIR}/res/

# needed for bootstrapping mosquitto
COPY --from=builder /edgex/cmd/security-bootstrapper/res-bootstrap-mosquitto/configuration.yaml ${BOOTSTRAP_MOSQUITTO_DIR}/res/

# copy Consul ACL related configs
COPY --from=builder /edgex/cmd/security-bootstrapper/consul-acl/ ${SECURITY_INIT_STAGING}/consul-bootstrapper/

# setup entry point script
COPY --from=builder /edgex/cmd/security-bootstrapper/entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# gate is one subcommand for security-bootstrapper to do security bootstrapping
CMD ["gate"]
