package router

import (
	stdLog "log"

	"strings"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"github.com/labstack/gommon/log"

	mymiddleware "github.com/ProjectDistribute/distributor/middleware"
)

func New() *echo.Echo {
	e := echo.New()
	e.HideBanner = true
	e.Logger.SetLevel(log.DEBUG)
	e.Pre(middleware.RemoveTrailingSlash())
	e.Use(middleware.BodyLimit("300M"))
	skipper := func(c echo.Context) bool {
		switch c.Request().URL.Path {
		case "/api/mails/next":
			return true
		case "/api/admin/logs":
			return true
		case "/api/admin/bandwidth":
			return true
		case "/api/admin/stats":
			return true
		}
		return false
	}
	e.Use(middleware.RequestLoggerWithConfig(middleware.RequestLoggerConfig{
		LogStatus:  true,
		LogURI:     true,
		LogMethod:  true,
		LogLatency: true,
		Skipper:    skipper,
		LogValuesFunc: func(c echo.Context, v middleware.RequestLoggerValues) error {
			stdLog.Printf("[%s] %v, %v, took: %vms\n", v.Method, v.Status, v.URI, v.Latency.Milliseconds())
			return nil
		},
	}))
	e.Use(middleware.Recover())
	e.Use(func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			return next(&mymiddleware.CustomContext{Context: c})
		}
	})
	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins: []string{"*"},
		AllowHeaders: []string{echo.HeaderOrigin, echo.HeaderContentType, echo.HeaderAccept, echo.HeaderAuthorization},
		AllowMethods: []string{echo.GET, echo.HEAD, echo.PUT, echo.PATCH, echo.POST, echo.DELETE},
	}))
	e.Validator = NewValidator()

	// Serve the frontend (Single Page Application)
	e.Use(middleware.StaticWithConfig(middleware.StaticConfig{
		Root:  "web",
		HTML5: true, // SPA mode: serves index.html for 404s
		Skipper: func(c echo.Context) bool {
			// Skip API routes so they return json/404 correctly
			return strings.HasPrefix(c.Request().URL.Path, "/api")
		},
	}))

	return e
}
