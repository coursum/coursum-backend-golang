package router

import (
	"github.com/coursum/coursum-backend/internal/pkg/httphandler"
	"github.com/gin-gonic/gin"
)

// Route will setup the route for the server
func Route() {
	router := gin.Default()

	// Load Template
	router.LoadHTMLGlob("web/*.tmpl")

	// Route
	router.GET("/", httphandler.GetIndex)
	router.GET("/ping", httphandler.GetPing)
	router.GET("/count", httphandler.GetCount)

	router.Run(":8000")
}
