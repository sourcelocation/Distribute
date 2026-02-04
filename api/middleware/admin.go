package middleware

import (
	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
)

func AdminMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		data := c.Get("user")
		if data == nil {
			return echo.ErrUnauthorized
		}

		token, ok := data.(*jwt.Token)
		if !ok || token == nil {
			return echo.ErrUnauthorized
		}

		// if !token.Valid {
		// 	return echo.ErrUnauthorized
		// }

		claims, ok := token.Claims.(*JwtCustomClaims)
		if !ok || claims == nil {
			return echo.ErrUnauthorized
		}

		if !claims.Admin {
			return echo.ErrUnauthorized
		}

		return next(c)
	}
}
