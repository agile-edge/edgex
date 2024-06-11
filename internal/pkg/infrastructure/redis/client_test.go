//
// Copyright (C) 2021 IOTech Ltd
//
// SPDX-License-Identifier: Apache-2.0

package redis

import dataInterfaces "github.com/agile-edgex/edgex-go/internal/core/data/infrastructure/interfaces"
import metadataInterfaces "github.com/agile-edgex/edgex-go/internal/core/metadata/infrastructure/interfaces"
import schedulerInterfaces "github.com/agile-edgex/edgex-go/internal/support/scheduler/infrastructure/interfaces"
import notificationsInterfaces "github.com/agile-edgex/edgex-go/internal/support/notifications/infrastructure/interfaces"

// Check the implementation of Redis satisfies the DB client
var _ dataInterfaces.DBClient = &Client{}
var _ metadataInterfaces.DBClient = &Client{}
var _ schedulerInterfaces.DBClient = &Client{}
var _ notificationsInterfaces.DBClient = &Client{}
