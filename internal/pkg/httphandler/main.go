package httphandler

import (
	"net/http"

	"github.com/coursum/coursum-backend/internal/pkg/elasticclient"
	"github.com/gin-gonic/gin"
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

// GetCount will respond the document count
func GetCount(c *gin.Context) {
	counts, err := elasticclient.GetAllDocumentCounts()
	if err != nil {
		c.String(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, counts)
	return
}
