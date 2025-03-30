/*******************************************************************************
 * Copyright 2017 Dell Inc.
 * Copyright (c) 2019 Intel Corporation
 * Copyright (C) 2020-2025 IOTech Ltd
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 *******************************************************************************/

package notifications

import (
	"context"
	"sync"
	"time"

	"github.com/agile-edge/edgex-go/internal/support/notifications/application"
	"github.com/agile-edge/edgex-go/internal/support/notifications/application/channel"
	"github.com/agile-edge/edgex-go/internal/support/notifications/container"

	bootstrapContainer "github.com/agile-edge/go-mod-bootstrap/v4/bootstrap/container"
	"github.com/agile-edge/go-mod-bootstrap/v4/bootstrap/startup"
	"github.com/agile-edge/go-mod-bootstrap/v4/di"

	"github.com/labstack/echo/v4"
)

// Bootstrap contains references to dependencies required by the BootstrapHandler.
type Bootstrap struct {
	router      *echo.Echo
	serviceName string
}

// NewBootstrap is a factory method that returns an initialized Bootstrap receiver struct.
func NewBootstrap(router *echo.Echo, serviceName string) *Bootstrap {
	return &Bootstrap{
		router:      router,
		serviceName: serviceName,
	}
}

// BootstrapHandler fulfills the BootstrapHandler contract and performs initialization for the notifications service.
func (b *Bootstrap) BootstrapHandler(ctx context.Context, wg *sync.WaitGroup, _ startup.Timer, dic *di.Container) bool {
	LoadRestRoutes(b.router, dic, b.serviceName)

	restSender := channel.NewRESTSender(dic, bootstrapContainer.SecretProviderExtFrom(dic.Get))
	emailSender := channel.NewEmailSender(dic)
	mqttSender := channel.NewMQTTSender(ctx, wg, dic)
	zeroMQSender := channel.NewZeroMQSender(ctx, wg, dic)
	dic.Update(di.ServiceConstructorMap{
		channel.RESTSenderName: func(get di.Get) interface{} {
			return restSender
		},
		channel.EmailSenderName: func(get di.Get) interface{} {
			return emailSender
		},
		channel.MQTTSenderName: func(get di.Get) interface{} {
			return mqttSender
		},
		channel.ZeroMQTSenderName: func(get di.Get) interface{} {
			return zeroMQSender
		},
	})

	lc := bootstrapContainer.LoggingClientFrom(dic.Get)
	config := container.ConfigurationFrom(dic.Get)
	if config.Retention.Enabled {
		retentionInterval, err := time.ParseDuration(config.Retention.Interval)
		if err != nil {
			lc.Errorf("Failed to parse notification retention interval, %v", err)
			return false
		}
		application.AsyncPurgeNotification(retentionInterval, ctx, dic)
	}
	return true
}
