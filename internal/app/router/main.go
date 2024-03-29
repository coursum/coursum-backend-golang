package router

import (
	"github.com/coursum/coursum-backend/internal/pkg/httphandler"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

// Route will setup the route for the server
func Route() {
	router := gin.Default()

	// MiddleWare
	router.Use(cors.Default())

	// Load Template
	router.LoadHTMLGlob("web/*.tmpl")

	// Route
	router.GET("/", httphandler.GetIndex)
	router.GET("/ping", httphandler.GetPing)
	router.GET("/count", httphandler.GetCount)
	router.GET("/search", httphandler.GetSearch)

	router.Run(":8000")
}
