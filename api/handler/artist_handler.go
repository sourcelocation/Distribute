package handler

import (
	"net/http"
	"strconv"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

// CreateArtist godoc
// @Summary Create artist
// @Description Creates an artist with one or more aliases. Requires an admin JWT.
// @Tags artists
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body CreateArtistRequest true "Artist payload"
// @Success 201 {object} Artist
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /artists [post]
func (h *Handler) CreateArtist(c echo.Context) error {
	type CreateArtistRequest struct {
		Name        string   `json:"name" validate:"required"`
		Identifiers []string `json:"identifiers" validate:"required"`
	}
	var req CreateArtistRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}

	artist, err := h.artist_svc.CreateArtist(req.Name, req.Identifiers)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to create artist: "+err.Error())
	}

	return c.JSON(http.StatusCreated, FromArtistModel(*artist))
}

// GetArtistsBatch godoc
// @Summary Batch get artists
// @Description Returns a list of artists by IDs.
// @Tags artists
// @Accept json
// @Produce json
// @Param request body BatchIDRequest true "Artist IDs"
// @Success 200 {array} Artist
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /artists/batch [post]
func (h *Handler) GetArtistsBatch(c echo.Context) error {
	var req BatchIDRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}

	artists, err := h.artist_svc.Store.GetArtistsByIDs(req.IDs)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve artists")
	}

	dtos := make([]Artist, len(artists))
	for i, a := range artists {
		dtos[i] = FromArtistModel(a)
	}
	return c.JSON(http.StatusOK, dtos)
}

// AddArtistIdentifier godoc
// @Summary Add artist identifier
// @Description Adds an identifier to an existing artist. Requires an admin JWT.
// @Tags artists
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body AddArtistIdentifierRequest true "Identifier payload"
// @Success 200 {object} StatusResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /artists/identifiers [post]
func (h *Handler) AddArtistIdentifier(c echo.Context) error {
	type AddIdentifierInput struct {
		ArtistID   uuid.UUID `json:"artist_id" validate:"required"`
		Identifier string    `json:"identifier" validate:"required"`
	}
	var input AddIdentifierInput
	if err := c.Bind(&input); err != nil {
		return c.JSON(400, map[string]string{"error": "Invalid input"})
	}
	if err := c.Validate(&input); err != nil {
		return c.JSON(400, map[string]string{"error": "Validation failed"})
	}

	err := h.artist_svc.AddIdentifierToArtist(input.ArtistID, input.Identifier)
	if err != nil {
		return c.JSON(500, map[string]string{"error": err.Error()})
	}

	return c.JSON(200, map[string]string{"status": "Identifier added successfully"})
}

// UpdateArtist godoc
// @Summary Update artist
// @Description Updates artist metadata. Requires an admin JWT.
// @Tags artists
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Artist ID (UUID)"
// @Param request body UpdateArtistRequest true "Artist metadata"
// @Success 200 {object} Artist
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /artists/{id} [put]
func (h *Handler) UpdateArtist(c echo.Context) error {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid artist ID")
	}

	var req UpdateArtistRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}

	updatedArtist, err := h.artist_svc.UpdateArtist(id, req.Name)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update artist: "+err.Error())
	}

	return c.JSON(http.StatusOK, FromArtistModel(*updatedArtist))
}

// DeleteArtist godoc
// @Summary Delete artist
// @Description Deletes an artist by ID. Requires an admin JWT.
// @Tags artists
// @Security BearerAuth
// @Param id path string true "Artist ID (UUID)"
// @Success 204 {string} string "No Content"
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /artists/{id} [delete]
func (h *Handler) DeleteArtist(c echo.Context) error {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid artist ID")
	}

	err = h.artist_svc.DeleteArtist(id)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to delete artist: "+err.Error())
	}
	return c.NoContent(http.StatusNoContent)
}

// GetArtists godoc
// @Summary List artists paginated
// @Description Returns paginated list of artists.
// @Tags artists
// @Produce json
// @Param page query int false "Page number"
// @Param limit query int false "Items per page"
// @Success 200 {object} map[string]any
// @Failure 500 {object} ErrorResponse
// @Router /artists [get]
func (h *Handler) GetArtists(c echo.Context) error {
	page, _ := strconv.Atoi(c.QueryParam("page"))
	limit, _ := strconv.Atoi(c.QueryParam("limit"))

	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}

	artists, hasNext, err := h.artist_svc.Store.GetArtistsPaginated(page, limit)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve artists")
	}

	dtos := make([]Artist, len(artists))
	for i, a := range artists {
		dtos[i] = FromArtistModel(a)
	}
	return c.JSON(http.StatusOK, map[string]any{
		"data":     dtos,
		"has_next": hasNext,
	})
}

// GetArtist godoc
// @Summary Get artist
// @Description Returns an artist by ID.
// @Tags artists
// @Produce json
// @Param id path string true "Artist ID (UUID)"
// @Success 200 {object} Artist
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /artists/{id} [get]
func (h *Handler) GetArtist(c echo.Context) error {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid artist ID")
	}

	artist, err := h.artist_svc.Store.GetArtistByID(id)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve artist")
	}
	if artist == nil {
		return echo.NewHTTPError(http.StatusNotFound, "Artist not found")
	}

	return c.JSON(http.StatusOK, FromArtistModel(*artist))
}
