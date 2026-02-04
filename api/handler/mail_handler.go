package handler

import (
	"strconv"

	"github.com/ProjectDistribute/distributor/middleware"
	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
)

// CreateRequestMail godoc
// @Summary Create request mail
// @Description Creates a new music request mail entry. Requires authentication.
// @Tags mails
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body CreateRequestMailRequest true "Request mail payload"
// @Success 201 {object} RequestMail
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /mails [post]
func (h *Handler) CreateRequestMail(c echo.Context) error {
	type RequestMailInput struct {
		Category string `json:"category" validate:"required"`
		Message  string `json:"message" validate:"required"`
	}

	var input RequestMailInput
	if err := c.Bind(&input); err != nil {
		return c.JSON(400, map[string]string{"error": "Invalid input"})
	}
	if err := c.Validate(&input); err != nil {
		return c.JSON(400, map[string]string{"error": "Validation failed"})
	}

	userToken, ok := c.Get("user").(*jwt.Token)
	if !ok {
		return c.JSON(401, map[string]string{"error": "Unauthorized"})
	}
	claims, ok := userToken.Claims.(*middleware.JwtCustomClaims)
	if !ok {
		return c.JSON(401, map[string]string{"error": "Invalid token claims"})
	}
	userID := claims.UUID()

	mail, err := h.mail_svc.CreateRequestMail(input.Category, input.Message, userID)
	if err != nil {
		return c.JSON(500, map[string]string{"error": err.Error()})
	}

	return c.JSON(201, FromRequestMailModel(*mail))
}

// GetCategories godoc
// @Summary List request mail categories
// @Description Returns configured request mail categories.
// @Tags mails
// @Produce json
// @Success 200 {object} CategoriesResponse
// @Router /mails/categories [get]
func (h *Handler) GetCategories(c echo.Context) error {
	categories := h.mail_svc.GetCategories()
	return c.JSON(200, map[string][]string{"categories": categories})
}

// GetRequestMails godoc
// @Summary List request mails
// @Description Returns all request mails. Requires an admin JWT.
// @Tags mails
// @Security BearerAuth
// @Produce json
// @Success 200 {array} RequestMail
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Router /mails [get]
func (h *Handler) GetRequestMails(c echo.Context) error {
	mails := h.mail_svc.GetRequestMails()
	dtos := make([]RequestMail, len(mails))
	for i, m := range mails {
		dtos[i] = FromRequestMailModel(m)
	}
	return c.JSON(200, dtos)
}

// SetMailStatus godoc
// @Summary Set request mail status
// @Description Updates the status of a request mail. Requires an admin JWT. Status values: 0=pending, 1=processing, 2=completed, 3=rejected.
// @Tags mails
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path int true "Mail ID"
// @Param request body SetMailStatusRequest true "Status payload"
// @Success 200 {object} MessageResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /mails/{id}/status [put]
func (h *Handler) SetMailStatus(c echo.Context) error {
	type StatusInput struct {
		Status int `json:"status" validate:"required"`
	}

	mailIdStr := c.Param("id")
	mailIdInt, err := strconv.Atoi(mailIdStr)
	if err != nil {
		return c.JSON(400, map[string]string{"error": "Invalid mail ID"})
	}
	unitmailId := uint(mailIdInt)

	var input StatusInput
	if err := c.Bind(&input); err != nil {
		return c.JSON(400, map[string]string{"error": "Invalid input"})
	}
	if err := c.Validate(&input); err != nil {
		return c.JSON(400, map[string]string{"error": "Validation failed"})
	}
	err = h.mail_svc.SetStatus(unitmailId, input.Status)
	if err != nil {
		return c.JSON(500, map[string]string{"error": err.Error()})
	}
	return c.JSON(200, map[string]string{"message": "Status updated"})
}

// GetNextRequestMail godoc
// @Summary Get next pending request mail
// @Description Returns the next pending request mail (if any). Requires an admin JWT.
// @Tags mails
// @Security BearerAuth
// @Produce json
// @Success 200 {object} RequestMail
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /mails/next [get]
func (h *Handler) GetNextRequestMail(c echo.Context) error {
	mail, err := h.mail_svc.GetNextRequestMail()
	if err != nil {
		return c.JSON(500, map[string]string{"error": err.Error()})
	}
	if mail == nil {
		return c.JSON(404, map[string]string{"error": "No pending request mail found"})
	}
	return c.JSON(200, FromRequestMailModel(*mail))
}
