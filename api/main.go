package main

import (
	"io"
	"log"
	"math/rand"
	"os"

	"github.com/ProjectDistribute/distributor/db"
	"github.com/ProjectDistribute/distributor/handler"
	"github.com/ProjectDistribute/distributor/router"
	"github.com/ProjectDistribute/distributor/utils"
)

var version = "s0.4.0"

// @title Distributor API
// @version 1.0
// @BasePath /api
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and JWT token.
func main() {

	r := router.New()

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
	h.Register(r)

	funnyMessages := []string{
		"Shiver me timbers that was hard to install...",
		"420% vibe coded",
		"You wouldn't download a car.",
		"There is no cloud, just your server now.",
		"Keep it secret. Keep it safe.",
		"Look at me. I am the Distributor now.",
		"Have you tried turning it off and on again?",
		"May the Source be with you.",
		"If a user gives you up, never let them down.",
		"\"WApp\" rebrand in 2077!",
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
