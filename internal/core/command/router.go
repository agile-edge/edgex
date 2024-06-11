//
// Copyright (C) 2021-2023 IOTech Ltd
// Copyright (C) 2023 Intel Corporation
//
// SPDX-License-Identifier: Apache-2.0

package command

import (
	"github.com/agile-edgex/edgex-go"
	commandController "github.com/agile-edgex/edgex-go/internal/core/command/controller/http"
	"github.com/agile-edgex/go-mod-bootstrap/v3/bootstrap/container"
	"github.com/agile-edgex/go-mod-bootstrap/v3/bootstrap/controller"
	"github.com/agile-edgex/go-mod-bootstrap/v3/bootstrap/handlers"
	"github.com/agile-edgex/go-mod-bootstrap/v3/di"
	"github.com/agile-edgex/go-mod-core-contracts/v3/common"

	"github.com/labstack/echo/v4"
)

func LoadRestRoutes(r *echo.Echo, dic *di.Container, serviceName string) {
	lc := container.LoggingClientFrom(dic.Get)
	secretProvider := container.SecretProviderExtFrom(dic.Get)
	authenticationHook := handlers.AutoConfigAuthenticationFunc(secretProvider, lc)

	// Common
	_ = controller.NewCommonController(dic, r, serviceName, edgex.Version)

	// Command
	cmd := commandController.NewCommandController(dic)
	r.GET(common.ApiAllDeviceRoute, cmd.AllCommands, authenticationHook)
	r.GET(common.ApiDeviceByNameEchoRoute, cmd.CommandsByDeviceName, authenticationHook)
	r.GET(common.ApiDeviceNameCommandNameEchoRoute, cmd.IssueGetCommandByName, authenticationHook)
	r.PUT(common.ApiDeviceNameCommandNameEchoRoute, cmd.IssueSetCommandByName, authenticationHook)
}
