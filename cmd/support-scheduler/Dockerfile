#  ----------------------------------------------------------------------------------
#  Copyright 2018 Dell Technologies, Inc.
#  Copyright 2018 Cavium
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

COPY . .
ARG GO_PROXY="https://goproxy.cn,direct"
ENV GOPROXY=$GO_PROXY
RUN make cmd/support-scheduler/support-scheduler

#Next image - Copy built Go binary into new workspace
FROM debian:bookworm-slim

ENV APP_PORT=59861
#expose support scheduler port
EXPOSE $APP_PORT

COPY --from=builder /edgex/Attribution.txt /
COPY --from=builder /edgex/security.txt /
COPY --from=builder /edgex/cmd/support-scheduler/support-scheduler /
COPY --from=builder /edgex/cmd/support-scheduler/res/configuration.yaml /res/configuration.yaml

ENTRYPOINT ["/support-scheduler"]
CMD ["-cp=consul.http://edgex-core-consul:8500", "--registry"]
