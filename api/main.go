package main

import (
	"io"
	"log"
	"math/rand"
	"net/http"
	"os"

	"github.com/ProjectDistribute/distributor/db"
	"github.com/ProjectDistribute/distributor/handler"
	"github.com/ProjectDistribute/distributor/router"
	"github.com/ProjectDistribute/distributor/utils"
	"github.com/labstack/echo/v4"
)

var version = "s0.3.0"

// @title Distributor API
// @version 1.0
// @BasePath /api
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and JWT token.
func main() {

	r := router.New()

	v1 := r.Group("/api")

	// DB
	d, err := db.New()
	if err != nil {
		panic(err)
	}
	if err := db.AutoMigrate(d); err != nil {
		panic(err)
	}

	// Logging setup
	logFile, err := os.OpenFile("data/db/server_events.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		log.Printf("Failed to open log file: %v\n", err)
	} else {
		multiWriter := io.MultiWriter(os.Stdout, logFile)
		log.SetOutput(multiWriter)
	}

	storage := utils.LocalFileStorage{}
	h := handler.GigaHandler(d, storage, version)
	r.Use(h.BandwidthMiddleware)
	h.Register(v1)

	// Route to open distribute://add-server/<SERVER_URL> URL scheme
	r.GET("/add", func(c echo.Context) error {
		serverURL := utils.Getenv("SERVER_URL", "")
		if serverURL == "" {
			return c.String(http.StatusBadRequest, "SERVER_URL environment variable is not configured")
		}
		return c.Redirect(http.StatusTemporaryRedirect, "distribute://add-server/"+serverURL)
	})

	funnyMessages := []string{
		"Shiver me timbers that was hard to install...",
		"420% vibe coded",
		"You wouldn't download a car.",
		"There is no cloud, just your server now.",
		"Keep it secret. Keep it safe.",
		"I'm sorry, Dave. I'm afraid I can now do that.",
		"Have you tried turning it off and on again?",
		"May the Source be with you.",
		"If a user gives you up, never let them down.",
		"Look at me. I am the server now.",
		"Should've named the client \"W App\"",
	}

	log.Printf(`
---------------------------------------------------------------------
Welcome to

████▄  ▄▄  ▄▄▄▄ ▄▄▄▄▄▄ ▄▄▄▄  ▄▄ ▄▄▄▄  ▄▄ ▄▄ ▄▄▄▄▄▄ ▄▄▄  ▄▄▄▄  
██  ██ ██ ███▄▄   ██   ██▄█▄ ██ ██▄██ ██ ██   ██  ██▀██ ██▄█▄ 
████▀  ██ ▄▄██▀   ██   ██ ██ ██ ██▄█▀ ▀███▀   ██  ▀███▀ ██ ██  %s

%s
---------------------------------------------------------------------
`, version, funnyMessages[rand.Intn(len(funnyMessages))])

	listenOn := utils.Getenv("LISTEN_ON", "0.0.0.0:8585")
	r.Logger.Fatal(r.Start(listenOn))
}
