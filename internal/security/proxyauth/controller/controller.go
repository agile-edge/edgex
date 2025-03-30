//
// Copyright (C) 2025 IOTech Ltd
//
// SPDX-License-Identifier: Apache-2.0

package controller

import (
	"github.com/agile-edge/edgex-go/internal/io"

	"github.com/agile-edge/go-mod-bootstrap/v4/di"
)

type AuthController struct {
	dic    *di.Container
	reader io.DtoReader
}

func NewAuthController(dic *di.Container) *AuthController {
	return &AuthController{
		dic:    dic,
		reader: io.NewJsonDtoReader(),
	}
}
