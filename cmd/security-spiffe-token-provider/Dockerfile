#  ----------------------------------------------------------------------------------
#  Copyright 2023 Intel Corporation
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

FROM golang:1.21-bookworm AS builder

ARG ADD_BUILD_TAGS=""

WORKDIR /edgex

ARG GO_PROXY="https://goproxy.cn,direct"
ENV GOPROXY=$GO_PROXY

COPY go.mod ./
RUN go mod download

COPY . .
RUN make cmd/security-spiffe-token-provider/security-spiffe-token-provider

#Next image - Copy built Go binary into new workspace
FROM debian:bookworm-slim

COPY --from=builder /edgex/Attribution.txt /
COPY --from=builder /edgex/security.txt /
COPY --from=builder /edgex/cmd/security-spiffe-token-provider/security-spiffe-token-provider /
COPY --from=builder /edgex/cmd/security-spiffe-token-provider/res/configuration.yaml /res/configuration.yaml

ENTRYPOINT [ "/security-spiffe-token-provider" ]
CMD ["-cp=consul.http://edgex-core-consul:8500"]
