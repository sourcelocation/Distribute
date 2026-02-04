package handler

import (
	"fmt"
	"net/http"

	"github.com/ProjectDistribute/distributor/middleware"
	"github.com/ProjectDistribute/distributor/model"
	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
)

// GetMe godoc
// @Summary Get current user
// @Description Returns the authenticated user's profile.
// @Tags users
// @Security BearerAuth
// @Produce json
// @Success 200 {object} User
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /users/me [get]
func (h *Handler) GetMe(c echo.Context) error {
	me := c.Get("user").(*jwt.Token).Claims.(*middleware.JwtCustomClaims)
	u, err := h.user_svc.Store.GetUserByID(me.UUID())
	if err != nil {
		return echo.NewHTTPError(500, "Failed to retrieve user")
	}

	rootFolderID, err := h.user_svc.PlaylistService.GetRootFolderID(u.ID)
	if err != nil {
		return echo.NewHTTPError(500, "Failed to retrieve root folder")
	}

	return c.JSON(200, FromUserModel(*u, rootFolderID))
}

// CreateUser godoc
// @Summary Sign up
// @Description Creates a new user and initializes their root playlist folder.
// @Tags users
// @Accept json
// @Produce json
// @Param request body SignupRequest true "Signup payload"
// @Success 201 {string} string "Success"
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /users/signup [post]
func (h *Handler) CreateUser(c echo.Context) error {
	type UserInput struct {
		Username string `json:"username" validate:"required,max=20,username_chars"`
		Password string `json:"password" validate:"required,max=128"`
	}

	var input UserInput
	if err := c.Bind(&input); err != nil {
		return c.JSON(400, map[string]string{"error": "Invalid input"})
	}
	if err := c.Validate(&input); err != nil {
		return c.JSON(400, map[string]string{"error": "Validation failed"})
	}

	_, err := h.user_svc.CreateUser(input.Username, input.Password)
	if err != nil {
		return c.JSON(500, map[string]string{"error": err.Error()})
	}

	return c.JSON(201, "Success")
}

// LoginUser godoc
// @Summary Login
// @Description Validates credentials and returns a JWT Bearer token and user object
// @Tags users
// @Accept json
// @Produce json
// @Param request body LoginRequest true "Login payload"
// @Success 200 {object} LoginResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /users/login [post]
func (h *Handler) LoginUser(c echo.Context) error {
	type LoginInput struct {
		Username string `json:"username" validate:"required,max=30"`
		Password string `json:"password" validate:"required,max=128"`
	}

	var input LoginInput
	if err := c.Bind(&input); err != nil {
		return c.JSON(400, map[string]string{"error": "Invalid input"})
	}
	if err := c.Validate(&input); err != nil {
		return c.JSON(400, map[string]string{"error": "Validation failed"})
	}

	user, err := h.user_svc.GetUserByUsername(input.Username)
	if err != nil || user == nil {
		return c.JSON(401, map[string]string{"error": "Invalid credentials"})
	}

	if err := h.user_svc.CheckPassword(user, input.Password); err != nil {
		return c.JSON(401, map[string]string{"error": "Invalid credentials"})
	}

	token, err := h.user_svc.GenerateToken(user)
	if err != nil {
		return c.JSON(500, map[string]string{"error": "Could not generate token"})
	}

	rootFolderID, err := h.user_svc.PlaylistService.GetRootFolderID(user.ID)
	if err != nil {
		return c.JSON(500, map[string]string{"error": "Failed to retrieve root folder"})
	}

	return c.JSON(200, echo.Map{"token": token, "username": user.Username, "id": user.ID, "user": FromUserModel(*user, rootFolderID)})
}

// DeleteUser godoc
// @Summary Delete user
// @Description Deletes a user by ID. Users can delete their own account, or admins can delete any user.
// @Tags users
// @Security BearerAuth
// @Param user_id path string true "User ID (UUID)"
// @Success 204 {string} string "No Content"
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /users/{user_id} [delete]
func (h *Handler) DeleteUser(c *middleware.CustomContext) error {
	// Get the user ID from route parameter
	userID, err := c.GetUUID("user_id")
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid user ID")
	}

	me := c.Get("user").(*jwt.Token).Claims.(*middleware.JwtCustomClaims)
	currentUserID := me.UUID()

	if currentUserID != userID && !me.Admin {
		return echo.NewHTTPError(http.StatusForbidden, "Forbidden: You can only delete your own account or must be an admin")
	}

	userToDelete, err := h.user_svc.Store.GetUserByID(userID)
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "User not found")
	}

	err = h.user_svc.DeleteUser(userToDelete)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to delete user: "+err.Error())
	}

	return c.NoContent(http.StatusNoContent)
}

// GetUsers godoc
// @Summary List users
// @Description Returns a list of users with pagination.
// @Tags admin
// @Security BearerAuth
// @Produce json
// @Param page query int false "Page number"
// @Param limit query int false "Items per page"
// @Success 200 {array} User
// @Failure 500 {object} ErrorResponse
// @Router /admin/users [get]
func (h *Handler) GetUsers(c echo.Context) error {
	var users []model.User
	var total int64

	limit := 10
	page := 1
	if l := c.QueryParam("limit"); l != "" {
		fmt.Sscanf(l, "%d", &limit)
	}
	if p := c.QueryParam("page"); p != "" {
		fmt.Sscanf(p, "%d", &page)
	}
	offset := (page - 1) * limit

	if err := h.db.Model(&model.User{}).Count(&total).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to count users"})
	}

	if err := h.db.Limit(limit).Offset(offset).Order("created_at desc").Find(&users).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to retrieve users"})
	}

	// Mask sensitive data
	for i := range users {
		users[i].PasswordHash = ""
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"data":  users,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

// ChangePassword godoc
// @Summary Change password
// @Description Updates the authenticated user's password.
// @Tags users
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param user_id path string true "User ID (UUID)"
// @Param request body object true "New password"
// @Success 200 {string} string "Success"
// @Failure 400 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /users/{user_id}/password [put]
func (h *Handler) ChangePassword(c echo.Context) error {
	cc := c.(*middleware.CustomContext)
	userID, err := cc.GetUUID("user_id")
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid user ID")
	}

	me := c.Get("user").(*jwt.Token).Claims.(*middleware.JwtCustomClaims)
	currentUserID := me.UUID()

	if currentUserID != userID && !me.Admin {
		return echo.NewHTTPError(http.StatusForbidden, "Forbidden: You can only change your own password or must be an admin")
	}

	type PasswordInput struct {
		Password string `json:"password" validate:"required,max=128"`
	}
	var input PasswordInput
	if err := c.Bind(&input); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid input"})
	}

	user, err := h.user_svc.Store.GetUserByID(userID)
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "User not found")
	}

	if err := h.user_svc.UpdatePassword(user, input.Password); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to update password"})
	}

	return c.JSON(http.StatusOK, "Password updated successfully")
}
