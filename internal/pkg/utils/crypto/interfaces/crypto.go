//
// Copyright (C) 2025 IOTech Ltd
//
// SPDX-License-Identifier: Apache-2.0

package interfaces

import "github.com/agile-edge/go-mod-core-contracts/v4/errors"

type Crypto interface {
	Encrypt(string) (string, errors.EdgeX)
	Decrypt(string) ([]byte, errors.EdgeX)
}
