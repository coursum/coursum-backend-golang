package httphandler

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

// GetIndex will respond the index page
func GetIndex(c *gin.Context) {
	c.HTML(http.StatusOK, "index.tmpl", gin.H{
		"title":   "Hello, Gin",
		"message": "Coursum Server",
	})
}

// GetPing will respond { "message": "ping" }
func GetPing(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "pong",
	})
}
