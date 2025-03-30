//
// Copyright (c) 2020 Intel Corporation
//
// SPDX-License-Identifier: Apache-2.0
//

package main

import (
	"context"
	"os"

	"github.com/agile-edge/edgex-go/internal/security/config"
)

func main() {
	os.Setenv("LOGLEVEL", "ERROR") // Workaround for https://github.com/agile-edge/edgex-go/issues/2922
	ctx, cancel := context.WithCancel(context.Background())
	exitStatusCode := config.Main(ctx, cancel, os.Args[1:])
	os.Exit(exitStatusCode)
}
