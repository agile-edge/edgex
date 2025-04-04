//
// Copyright (C) 2020-2023 IOTech Ltd
//
// SPDX-License-Identifier: Apache-2.0

package http

import (
	"math"
	"net/http"

	"github.com/edgexfoundry/edgex-go/internal/core/metadata/application"
	metadataContainer "github.com/edgexfoundry/edgex-go/internal/core/metadata/container"
	"github.com/edgexfoundry/edgex-go/internal/io"
	"github.com/edgexfoundry/edgex-go/internal/pkg"
	"github.com/edgexfoundry/edgex-go/internal/pkg/correlation"
	"github.com/edgexfoundry/edgex-go/internal/pkg/utils"

	"github.com/edgexfoundry/go-mod-bootstrap/v4/bootstrap/container"
	"github.com/edgexfoundry/go-mod-bootstrap/v4/di"
	"github.com/edgexfoundry/go-mod-core-contracts/v4/common"
	commonDTO "github.com/edgexfoundry/go-mod-core-contracts/v4/dtos/common"
	requestDTO "github.com/edgexfoundry/go-mod-core-contracts/v4/dtos/requests"
	responseDTO "github.com/edgexfoundry/go-mod-core-contracts/v4/dtos/responses"

	"github.com/labstack/echo/v4"
)

type DeviceServiceController struct {
	reader io.DtoReader
	dic    *di.Container
}

// NewDeviceServiceController creates and initializes an DeviceServiceController
func NewDeviceServiceController(dic *di.Container) *DeviceServiceController {
	return &DeviceServiceController{
		reader: io.NewJsonDtoReader(),
		dic:    dic,
	}
}

func (dc *DeviceServiceController) AddDeviceService(c echo.Context) error {
	r := c.Request()
	w := c.Response()
	if r.Body != nil {
		defer func() { _ = r.Body.Close() }()
	}

	lc := container.LoggingClientFrom(dc.dic.Get)

	ctx := r.Context()
	correlationId := correlation.FromContext(ctx)

	var reqDTOs []requestDTO.AddDeviceServiceRequest
	err := dc.reader.Read(r.Body, &reqDTOs)
	if err != nil {
		return utils.WriteErrorResponse(w, ctx, lc, err, "")
	}
	deviceServices := requestDTO.AddDeviceServiceReqToDeviceServiceModels(reqDTOs)

	var addResponses []interface{}
	for i, d := range deviceServices {
		var addDeviceServiceResponse interface{}
		reqId := reqDTOs[i].RequestId
		newId, err := application.AddDeviceService(d, ctx, dc.dic)
		if err == nil {
			addDeviceServiceResponse = commonDTO.NewBaseWithIdResponse(
				reqId,
				"",
				http.StatusCreated,
				newId)
		} else {
			lc.Error(err.Error(), common.CorrelationHeader, correlationId)
			lc.Debug(err.DebugMessages(), common.CorrelationHeader, correlationId)
			addDeviceServiceResponse = commonDTO.NewBaseResponse(
				reqId,
				err.Error(),
				err.Code())
		}
		addResponses = append(addResponses, addDeviceServiceResponse)
	}

	utils.WriteHttpHeader(w, ctx, http.StatusMultiStatus)
	// EncodeAndWriteResponse and send the resp body as JSON format
	return pkg.EncodeAndWriteResponse(addResponses, w, lc)
}

func (dc *DeviceServiceController) DeviceServiceByName(c echo.Context) error {
	lc := container.LoggingClientFrom(dc.dic.Get)
	r := c.Request()
	w := c.Response()
	ctx := r.Context()

	// URL parameters
	name := c.Param(common.Name)

	deviceService, err := application.DeviceServiceByName(name, ctx, dc.dic)
	if err != nil {
		return utils.WriteErrorResponse(w, ctx, lc, err, "")
	}

	response := responseDTO.NewDeviceServiceResponse("", "", http.StatusOK, deviceService)
	utils.WriteHttpHeader(w, ctx, http.StatusOK)
	return pkg.EncodeAndWriteResponse(response, w, lc)
}

func (dc *DeviceServiceController) PatchDeviceService(c echo.Context) error {
	r := c.Request()
	w := c.Response()
	if r.Body != nil {
		defer func() { _ = r.Body.Close() }()
	}

	lc := container.LoggingClientFrom(dc.dic.Get)

	ctx := r.Context()
	correlationId := correlation.FromContext(ctx)

	var reqDTOs []requestDTO.UpdateDeviceServiceRequest
	err := dc.reader.Read(r.Body, &reqDTOs)
	if err != nil {
		return utils.WriteErrorResponse(w, ctx, lc, err, "")
	}

	var updateResponses []interface{}
	for _, dto := range reqDTOs {
		var response interface{}
		reqId := dto.RequestId
		err := application.PatchDeviceService(dto.Service, ctx, dc.dic)
		if err != nil {
			lc.Error(err.Error(), common.CorrelationHeader, correlationId)
			lc.Debug(err.DebugMessages(), common.CorrelationHeader, correlationId)
			response = commonDTO.NewBaseResponse(
				reqId,
				err.Message(),
				err.Code())
		} else {
			response = commonDTO.NewBaseResponse(
				reqId,
				"",
				http.StatusOK)
		}
		updateResponses = append(updateResponses, response)
	}

	utils.WriteHttpHeader(w, ctx, http.StatusMultiStatus)
	return pkg.EncodeAndWriteResponse(updateResponses, w, lc)
}

func (dc *DeviceServiceController) DeleteDeviceServiceByName(c echo.Context) error {
	lc := container.LoggingClientFrom(dc.dic.Get)
	r := c.Request()
	w := c.Response()
	ctx := r.Context()

	// URL parameters
	name := c.Param(common.Name)

	err := application.DeleteDeviceServiceByName(name, ctx, dc.dic)
	if err != nil {
		return utils.WriteErrorResponse(w, ctx, lc, err, "")
	}

	response := commonDTO.NewBaseResponse("", "", http.StatusOK)
	utils.WriteHttpHeader(w, ctx, http.StatusOK)
	return pkg.EncodeAndWriteResponse(response, w, lc)
}

func (dc *DeviceServiceController) AllDeviceServices(c echo.Context) error {
	lc := container.LoggingClientFrom(dc.dic.Get)
	r := c.Request()
	w := c.Response()
	ctx := r.Context()
	config := metadataContainer.ConfigurationFrom(dc.dic.Get)

	// parse URL query string for offset, limit, and labels
	offset, limit, labels, err := utils.ParseGetAllObjectsRequestQueryString(c, 0, math.MaxInt32, -1, config.Service.MaxResultCount)
	if err != nil {
		return utils.WriteErrorResponse(w, ctx, lc, err, "")
	}
	deviceServices, totalCount, err := application.AllDeviceServices(offset, limit, labels, ctx, dc.dic)
	if err != nil {
		return utils.WriteErrorResponse(w, ctx, lc, err, "")
	}

	response := responseDTO.NewMultiDeviceServicesResponse("", "", http.StatusOK, totalCount, deviceServices)
	utils.WriteHttpHeader(w, ctx, http.StatusOK)
	// encode and send out the response
	return pkg.EncodeAndWriteResponse(response, w, lc)
}
