//
// Copyright (C) 2025 IOTech Ltd
//
// SPDX-License-Identifier: Apache-2.0

package tokenmaintenance

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/agile-edge/edgex-go/internal/security/secretstore/config"

	"github.com/agile-edge/go-mod-core-contracts/v4/clients/logger"
	"github.com/agile-edge/go-mod-secrets/v4/pkg/token/fileioperformer/mocks"
	"github.com/agile-edge/go-mod-secrets/v4/pkg/types"

	"github.com/stretchr/testify/assert"
)

var (
	sampleJSON = `
{
	"keys": [
		"test-keys"
	],
	"keys_base64": [
		"test-keys-base64"
	],
	"root_token": "test-root-token"
}`
	expectedFolder = "/foo"
	expectedFile   = "bar.baz"
)

func TestLoadInitResponse(t *testing.T) {
	// Arrange
	mockLogger := logger.MockLogger{}
	fileOpener := &mocks.FileIoPerformer{}
	stringReader := strings.NewReader(sampleJSON)
	fileOpener.On("OpenFileReader", filepath.Join(expectedFolder, expectedFile), os.O_RDONLY, os.FileMode(0400)).Return(stringReader, nil)
	secretConfig := config.SecretStoreInfo{
		TokenFolderPath: expectedFolder,
		TokenFile:       expectedFile,
	}
	initResponse := types.InitResponse{}

	// Act
	err := LoadInitResponse(mockLogger, fileOpener, secretConfig, &initResponse)

	// Assert
	assert.NoError(t, err)
	fileOpener.AssertExpectations(t)
}
